import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart' as permissionhandler;
import 'package:on_audio_query/on_audio_query.dart';
import 'package:appwrite/appwrite.dart';
import 'package:aurora_music_v01/screens/login_screen.dart';
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
  String? userName;

  @override
  void initState() {
    super.initState();
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
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> checkForAuthentication() async {
    try {
      final session = await account!.getSession(sessionId: 'current');
      final user = await account?.get();
      if (session != null) {
        setState(() {
          account = account;
          userName = user?.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${userName ?? 'User'}!'),
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
        final regex = RegExp(r'^v?(\d+\.\d+\.\d+)(-[a-zA-Z]+)?$');
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
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      try {
        await launchUrl(uri);
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

  void _openNowPlayingScreen(SongModel song) {
    int index = songs.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NowPlayingScreen(
            songs: songs,
            currentIndex: index,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Song not found in list')),
      );
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
                    child: Text(
                      'Welcome Back${userName != null ? ', $userName' : ''}',
                      style: const TextStyle(
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
                  dividerColor: Colors.transparent,
                  indicator: OutlineIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                    text: '',
                    radius: Radius.circular(24),
                  ),
                  tabs: [
                    Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Songs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Playlist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
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
                      _openNowPlayingScreen(song);
                    },
                  );
                },
              ),
              const Center(
                child: Text('Playlist', style: TextStyle(color: Colors.white)),
              ),
              ListView(
                children: [
                  ListTile(
                    title: const Text(
                      'Log Out',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'User settings',
                      style: TextStyle(color: Colors.grey),
                    ),
                    leading: const Icon(Icons.logout, color: Colors.white),
                    onTap: logout,
                  ),
                ],
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
  BoxPainter createBoxPainter([VoidCallback? onChange]) {
    return _OutlinePainter(
      color: color,
      strokeWidth: strokeWidth,
      text: text,
      radius: radius,
      onChange: onChange,
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
    const Radius radius = Radius.circular(24);
    final Rect rect = offset & configuration.size!;
    final RRect rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: radius,
      topRight: radius,
      bottomLeft: radius,
      bottomRight: radius,
    );
    canvas.drawRRect(rrect, _paint);
  }
}
