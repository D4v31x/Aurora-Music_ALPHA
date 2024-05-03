import 'dart:convert';
import 'dart:io';
import 'package:aurora_music_v01/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late bool isDarkMode;
  bool isWelcomeBackVisible = true;
  bool isAuroraMusicVisible = false;
  User? user;
  Version? latestVersion;
  late TabController _tabController;
  List<SongModel> songs = []; // Initialize with empty list

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        isWelcomeBackVisible = false;
      });
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      setState(() {
        isAuroraMusicVisible = true;
      });
    });

    checkForNewVersion();
    fetchSongs();
  }

  Future<void> checkForNewVersion() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.github.com/repos/D4v31x/Aurora-Music_ALPHA_RELEASES/releases/latest'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final versionString = data['tag_name'];
        final regex = RegExp(r'^v?(\d+\.\d+\.\d+(-\S+)?)$');
        final match = regex.firstMatch(versionString);
        if (match != null && match.groupCount > 0) {
          final versionString = match.group(1)!;
          setState(() {
            latestVersion = Version.parse(versionString);
          });
        }
      }
    } catch (e) {
      print('Error fetching latest version: $e');
    }
  }

Future<void> fetchSongs() async {
  if (Platform.isAndroid) {
     await Permission.audio.request();
    if (await Permission.mediaLibrary.request().isGranted) {
      // Permission is granted, fetch songs
      final onAudioQuery = OnAudioQuery();
      try {
        final songsResult = await onAudioQuery.querySongs();
        setState(() {
          songs = songsResult;
        });
      } catch (e) {
        // Handle error
        print('Error fetching songs: $e');
      }
    } else {
      // Permission is denied, show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission denied'),
        ),
      );
    }
  } else {
    // Handle other platforms
  }
}

  void launchURL(String url) async {
    if (await canLaunch(url)) {
      try {
        await launch(url);
      } catch (e) {
        print('Error launching URL: $e');
      }
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final regex = RegExp(r'^v?(\d+\.\d+\.\d+)(-[a-zA-Z]+)?$');
    final match = regex.firstMatch('v0.0.5-alpha');
    final currentVersion = Version.parse(match!.group(1)!);
    final isUpdateAvailable =
        latestVersion != null && latestVersion!.compareTo(currentVersion) > 0;

    if (isUpdateAvailable) {
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('New version available'),
              content: const Text(
                  'A new version of Aurora Music is available. Would you like to download it now?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await launch(
                        'https://github.com/D4v31x/Aurora-Music_ALPHA_RELEASES/releases/latest'); // Replace this line
                  },
                  child: const Text('Download'),
                ),
              ],
            );
          },
        );
      });
    }

    _tabController = TabController(length: 2, vsync: this);

    return user == null
        ? LoginPage()
        : Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  image: DecorationImage(
                    image: AssetImage(isDarkMode
                        ? 'assets/images/background/dark_back.jpg'
                        : 'assets/images/background/light_back.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0.0,
                  toolbarHeight: 180,
                  automaticallyImplyLeading: false,
                  title: Stack(
                    children: [
                      Center(
                        child: AnimatedOpacity(
                          opacity: isWelcomeBackVisible ? 1.0 : 0.0,
                          duration: const Duration(seconds: 1),
                          child: const Text(
                            'Welcome Back',
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontStyle: FontStyle.normal,
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                      Center(
                        child: AnimatedOpacity(
                          opacity: isAuroraMusicVisible ? 1.0 : 0.0,
                          duration: const Duration(seconds: 1),
                          child: const Text(
                            'Aurora Music',
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontStyle: FontStyle.normal,
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                    ],
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(50),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: OutlineIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                          text: 'Home',
                        ),
                        dividerColor: Colors.transparent,
                        labelStyle:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        unselectedLabelStyle: TextStyle(fontSize: 16),
                        tabs: [
                          Tab(
                            text: 'Home',
                          ),
                          Tab(
                            text: 'Library',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    Center(
                      child: Text(
                        'App is under construction',
                        style: TextStyle(
                            fontFamily: 'Outfit',
                            fontStyle: FontStyle.normal,
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    songs.isEmpty
                        ? Center(child: CircularProgressIndicator())
                        : ListView.builder(
  itemCount: songs.length,
  itemBuilder: (context, index) {
    final song = songs[index];
    return ListTile(
      title: Text(
        song.title,
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        song.artist.toString(), 
        style: TextStyle(color: Colors.white),
      ),
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => NowPlayingScreen(
        currentSong: song,
      ),
    ),
  );
},
    );
  },
)
                  ],
                ),
              ),
            ],
          );
  }
}

class OutlineIndicator extends Decoration {
  const OutlineIndicator({
    this.color = Colors.white,
    this.strokeWidth = 2,
    required this.text,
    this.radius = const Radius.circular(24),
  });

  final Color color;
  final double strokeWidth;
  final String text;
  final Radius radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _OutlinePainter(
      color: color,
      strokeWidth: strokeWidth,
      text: text,
      radius: radius,
      onChange: onChanged,
    );
  }
}

class _OutlinePainter extends BoxPainter {
  _OutlinePainter({
    required this.color,
    required this.strokeWidth,
    required this.text,
    required this.radius,
    VoidCallback? onChange,
  })  : _paint = Paint()
          ..style = PaintingStyle.stroke
          ..color = color
          ..strokeWidth = strokeWidth,
        super(onChange);

  final Color color;
  final double strokeWidth;
  final String text;
  final Radius radius;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration.size != null);
    var rect = offset & configuration.size!;
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final textWidth = textPainter.width;
    final indicatorWidth = textWidth + 16; // Add some padding to the indicator
    final indicatorRect = Rect.fromLTWH(
      rect.left + (rect.width - indicatorWidth) / 2,
      rect.top + rect.height - strokeWidth,
      indicatorWidth,
      strokeWidth,
    );
    var rrect = RRect.fromRectAndRadius(indicatorRect, radius);
    canvas.drawRRect(rrect, _paint);
  }
}



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
    if (widget.currentSong!= null) {
      final url = widget.currentSong!.uri;
      await _audioPlayer.setUrl(url.toString());
      await _audioPlayer.play();
    }
  }

  void _stop() async {
    await _audioPlayer.stop();
  }

  void _skip() async {
    // Implement skip functionality
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
              widget.currentSong?.title?? 'No song playing',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () {
              // Handle artist name tap
            },
            child: Text(
              widget.currentSong?.artist?? 'Unknown artist',
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