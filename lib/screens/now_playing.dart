import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:typed_data';

class NowPlayingScreen extends StatefulWidget {
  final List<SongModel> songs;
  final int currentIndex;

  const NowPlayingScreen({super.key, required this.songs, required this.currentIndex});

  @override
  _NowPlayingScreenState createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  late AudioPlayer _audioPlayer;
  late int _currentIndex;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  Map<int, Uint8List?> _artworkCache = {};

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _currentIndex = widget.currentIndex;
    _setupAudioPlayer();
    _preloadArtwork();
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

  void _preloadArtwork() async {
    final currentSong = widget.songs[_currentIndex];
    _artworkCache[_currentIndex] = await _getArtwork(currentSong.id);

    // Preload next and previous
    if (_currentIndex > 0) {
      final prevSong = widget.songs[_currentIndex - 1];
      _artworkCache[_currentIndex - 1] = await _getArtwork(prevSong.id);
    }
    if (_currentIndex < widget.songs.length - 1) {
      final nextSong = widget.songs[_currentIndex + 1];
      _artworkCache[_currentIndex + 1] = await _getArtwork(nextSong.id);
    }

    setState(() {});
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
    _preloadArtwork();
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

  Future<Uint8List?> _getArtwork(int id) async {
    try {
      return await _audioQuery.queryArtwork(
        id,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 1000,
      );
    } catch (e) {
      print("Error fetching artwork: $e");
      return null;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
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
        title: const Text('Now Playing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background image with blur effect
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: _artworkCache[_currentIndex] != null
                    ? MemoryImage(_artworkCache[_currentIndex]!)
                    : AssetImage('assets/images/logo/default_art.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
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
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: currentSong != null
                              ? _artworkCache[_currentIndex] != null
                              ? Image.memory(
                            _artworkCache[_currentIndex]!,
                            key: ValueKey<int>(currentSong.id),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                              : Image.asset(
                            'assets/images/logo/default_art.png',
                            key: ValueKey<String>('default_artwork'),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                              : Container(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Song title
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  currentSong?.title ?? 'No song playing',
                  key: ValueKey<int>(_currentIndex),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              // Artist name
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  currentSong?.artist ?? 'Unknown artist',
                  key: ValueKey<int>(_currentIndex),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
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
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(color: Colors.white),
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
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: _back,
                  ),
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
                    onPressed: _pause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
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
      ),
    );
  }
}