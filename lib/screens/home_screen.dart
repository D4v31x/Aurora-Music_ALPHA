import 'dart:convert';
import 'dart:io';
import 'package:aurora_music_v01/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart' as permissionhandler;
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:appwrite/appwrite.dart';
import 'package:aurora_music_v01/screens/now_playing.dart';

class HomeScreen extends StatefulWidget {
  final Client client;
  final String sessionId;

  const HomeScreen({super.key, required this.client, required this.sessionId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late bool isDarkMode;
  bool isWelcomeBackVisible = true;
  bool isAuroraMusicVisible = false;
  Account? account;
  Version? latestVersion;
  late TabController _tabController;
  List<SongModel> songs = [];

  @override
  void initState() {
    super.initState();

    // Initialize the Account object
    account = Account(widget.client);

    checkForAuthentication();

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

  Future<void> checkForAuthentication() async {
    try {
      final session = await account!.getSession(sessionId: 'current');
      final user = await account?.get();
      if (session != null) {
        setState(() {
          account = account;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged in as ${user?.email}'),
          ),
        );
      }
    } catch (e) {
      // If there's an error fetching the session, navigate to the login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage(client: widget.client)),
      );
    }
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
    try {
      if (Platform.isAndroid) {
        // Requesting audio permission
        var audioPermissionStatus = await permissionhandler.Permission.audio.status;
        if (!audioPermissionStatus.isGranted) {
          audioPermissionStatus = await permissionhandler.Permission.audio.request();
        }

        // Requesting storage permission
        var storagePermissionStatus = await permissionhandler.Permission.storage.status;
        if (!storagePermissionStatus.isGranted) {
          storagePermissionStatus = await permissionhandler.Permission.storage.request();
        }

        // Proceed if permissions are granted
        if (audioPermissionStatus.isGranted || storagePermissionStatus.isGranted) {
          final onAudioQuery = OnAudioQuery();
          final songsResult = await onAudioQuery.querySongs();
          setState(() {
            songs = songsResult;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permissions denied'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching songs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching songs'),
        ),
      );
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

  Future<void> logout() async {
    try {
      await account!.deleteSession(sessionId: 'current');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage(client: widget.client)),
      );
    } catch (e) {
      print('Error logging out: $e');
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
    final match = regex.firstMatch('v0.0.6-alpha');
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
                  'A new version is available. Would you like to download it now?'),
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
                        'https://github.com/D4v31x/Aurora-Music_ALPHA_RELEASES/releases/latest');
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

    return account != null
        ? Stack(
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
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    logout();
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ];
                },
              ),
            ],
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
                    text: 'Custom Indicator',
                    radius: Radius.circular(24),
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(
                        Icons.music_note,
                        color: Colors.white,
                      ),
                      text: 'Songs',
                    ),
                    Tab(
                      icon: Icon(
                        Icons.playlist_play,
                        color: Colors.white,
                      ),
                      text: 'Playlist',
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return ListTile(
                    leading: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkFit: BoxFit.cover,
                      nullArtworkWidget: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      song.title.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      song.artist.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NowPlayingScreen(currentSong: song),
                        ),
                      );
                    },
                  );
                },
              ),
              const Center(
                child: Text('Playlist'),
              ),
            ],
          ),
        ),
      ],
    )
        : Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: CircularProgressIndicator(),
      ),
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
        style: const TextStyle(
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

