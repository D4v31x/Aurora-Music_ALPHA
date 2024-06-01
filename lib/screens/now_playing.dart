import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class NowPlayingScreen extends StatefulWidget {
  final SongModel? currentSong;

  NowPlayingScreen({required this.currentSong});

  @override
  _NowPlayingScreenState createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _play() async {
    if (widget.currentSong != null) {
      final url = widget.currentSong!.uri;
      await _audioPlayer.setUrl(url.toString());
      await _audioPlayer.play();
    }
  }

  void _stop() async {
    await _audioPlayer.stop();
  }

  void _skip() async {

  }

  void _back() async {
    // Implement back functionality
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Now Playing'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              // Handle song name tap
            },
            child: Text(
              widget.currentSong?.title ?? 'No song playing',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () {
              // Handle artist name tap
            },
            child: Text(
              widget.currentSong?.artist ?? 'Unknown artist',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: _play,
                  ),
                  IconButton(
                    icon: Icon(Icons.stop),
                    onPressed: _stop,
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next),
                    onPressed: _skip,
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_previous),
                    onPressed: _back,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
