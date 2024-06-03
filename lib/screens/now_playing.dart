import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:blur/blur.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class NowPlayingScreen extends StatefulWidget {
  final List<SongModel> songs;
  final int currentIndex;

  NowPlayingScreen({required this.songs, required this.currentIndex});

  @override
  _NowPlayingScreenState createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  late AudioPlayer _audioPlayer;
  late int _currentIndex;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _currentIndex = widget.currentIndex;
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _audioPlayer.positionStream.listen((position) {
      final duration = _audioPlayer.duration;
      if (duration != null && position >= duration) {
        _skip();
      }
    });
    _play();
  }

  void _play() async {
    if (_currentIndex >= 0 && _currentIndex < widget.songs.length) {
      final song = widget.songs[_currentIndex];
      final url = song.uri;
      await _audioPlayer.setUrl(url.toString());
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _pause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _stop() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  void _skip() async {
    int nextIndex = _currentIndex + 1;
    if (_isShuffle) {
      nextIndex = _getRandomIndex();
    } else if (nextIndex >= widget.songs.length) {
      nextIndex = _isRepeat ? 0 : _currentIndex;
    }

    _playAtIndex(nextIndex);
  }

  void _back() async {
    int prevIndex = _currentIndex - 1;
    if (_isShuffle) {
      prevIndex = _getRandomIndex();
    } else if (prevIndex < 0) {
      prevIndex = _isRepeat ? widget.songs.length - 1 : _currentIndex;
    }

    _playAtIndex(prevIndex);
  }

  void _playAtIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
    _play();
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
    });
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeat = !_isRepeat;
    });
  }

  int _getRandomIndex() {
    if (widget.songs.length <= 1) return _currentIndex;
    int newIndex;
    do {
      newIndex = (DateTime.now().millisecondsSinceEpoch % widget.songs.length).toInt();
    } while (newIndex == _currentIndex);
    return newIndex;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<String?> _getArtworkUrl(SongModel song) async {
    final apiKey = '7a9dd38921cc44bfae9363a0a4f3e387';
    final artist = song.artist ?? '';
    final title = song.title ?? '';
    final url =
        'http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=$apiKey&artist=$artist&album=$title&format=json';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final album = data['album'];
      if (album != null && album['image'] != null && album['image'].isNotEmpty) {
        return album['image'].last['#text'];
      }
    }
    return null;
  }

  Future<void> _downloadAndSaveArtwork(String url, String filePath) async {
    final dio = Dio();
    await dio.download(url, filePath);
  }

  Future<File?> _getLocalArtworkFile(SongModel song) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/artwork_${song.id}.jpg';
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  Future<void> _downloadArtworkIfNeeded(SongModel song) async {
    final localFile = await _getLocalArtworkFile(song);
    if (localFile == null) {
      final artworkUrl = await _getArtworkUrl(song);
      if (artworkUrl != null) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/artwork_${song.id}.jpg';
        await _downloadAndSaveArtwork(artworkUrl, filePath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = _currentIndex >= 0 && _currentIndex < widget.songs.length
        ? widget.songs[_currentIndex]
        : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Now Playing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<File?>(
        future: currentSong != null ? _getLocalArtworkFile(currentSong).then((file) {
          if (file == null) {
            return _downloadArtworkIfNeeded(currentSong).then((_) => _getLocalArtworkFile(currentSong));
          }
          return Future.value(file);
        }) : Future.value(null),
        builder: (context, snapshot) {
          final artworkFile = snapshot.data;
          final hasArtwork = artworkFile != null;
          final artworkWidget = hasArtwork
              ? Image.file(
            artworkFile!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ).blurred(blur: 55, colorOpacity: 0)
              : _getFallbackArtwork(currentSong).blurred(blur: 50, colorOpacity: 0);

          return Stack(
            children: [
              // Fullscreen background image with blur effect
              Container(
                width: double.infinity,
                height: double.infinity,
                child: artworkWidget,
              ),
              // Content of the page
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Center the artwork
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 70.0),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                spreadRadius: 5,
                                blurRadius: 30,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: 500),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                              child: hasArtwork
                                  ? Image.file(
                                artworkFile!,
                                key: ValueKey<String>(artworkFile.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                                  : _getFallbackArtwork(currentSong),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Song title
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    child: Text(
                      currentSong?.title ?? 'No song playing',
                      key: ValueKey<int>(_currentIndex),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Artist name
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    child: Text(
                      currentSong?.artist ?? 'Unknown artist',
                      key: ValueKey<int>(_currentIndex),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Timeline
                  StreamBuilder<Duration?>(
                    stream: _audioPlayer.durationStream,
                    builder: (context, snapshot) {
                      final duration = snapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration>(
                        stream: _audioPlayer.positionStream,
                        builder: (context, snapshot) {
                          var position = snapshot.data ?? Duration.zero;
                          if (position > duration) {
                            position = duration;
                          }
                          return Column(
                            children: [
                              Slider(
                                activeColor: Colors.white,
                                inactiveColor: Colors.white54,
                                min: 0.0,
                                max: duration.inMilliseconds.toDouble(),
                                value: position.inMilliseconds.toDouble(),
                                onChanged: (value) {
                                  _audioPlayer.seek(Duration(milliseconds: value.round()));
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(_isShuffle ? Icons.shuffle : Icons.shuffle_outlined, color: Colors.white),
                        onPressed: _toggleShuffle,
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_previous, color: Colors.white),
                        onPressed: _back,
                      ),
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
                        onPressed: _pause,
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next, color: Colors.white),
                        onPressed: _skip,
                      ),
                      IconButton(
                        icon: Icon(_isRepeat ? Icons.repeat_one : Icons.repeat, color: Colors.white),
                        onPressed: _toggleRepeat,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),

    );
  }

  Widget _getFallbackArtwork(SongModel? currentSong) {
    return currentSong != null
        ? QueryArtworkWidget(
      id: currentSong.id,
      type: ArtworkType.AUDIO,
      artworkFit: BoxFit.cover,
      artworkQuality: FilterQuality.high,
      artworkWidth: 2000,
      artworkHeight: 2000,
      keepOldArtwork: true,
      nullArtworkWidget: Image.asset(
        'assets/images/logo/default_art.png',
        fit: BoxFit.cover,
      ),
    )
        : Image.asset(
      'assets/images/logo/default_art.png',
      fit: BoxFit.cover,
    );
  }
}
