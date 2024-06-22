import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart' as permissionhandler;
import 'package:on_audio_query/on_audio_query.dart';
import 'package:appwrite/appwrite.dart';
import 'package:aurora_music_v01/screens/now_playing.dart';
import 'package:palette_generator/palette_generator.dart';

import '../localization/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final Client client;


  const HomeScreen({super.key, required this.client});

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
  SongModel? currentSong;
  Color? dominantColor;
  Color? textColor;
  AnimationController? _animationController;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    account = Account(widget.client);

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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
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
            const SnackBar(
              content: Text('Permissions denied'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching songs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
      // Handle logout actions (e.g., navigate to a different screen or show a message)
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  Future<void> _extractDominantColor(SongModel song) async {
    final image = await OnAudioQuery().queryArtwork(
      song.id,
      ArtworkType.AUDIO,
    );
    if (image != null) {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        MemoryImage(image),
      );
      setState(() {
        dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
        textColor = dominantColor!.computeLuminance() > 0.5 ? Colors.black : Colors.white;
      });
    } else {
      setState(() {
        dominantColor = Colors.black;
        textColor = Colors.white;
      });
    }
  }

  void _openNowPlayingScreen(SongModel song) async {
    await _animationController?.forward();
    int index = songs.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              NowPlayingScreen(
                songs: songs,
                currentIndex: index,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: _slideAnimation!,
              child: child,
            );
          },
        ),
      ).then((value) => _animationController?.reverse());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Song not found in list')),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  void _onSongTap(SongModel song) async {
    setState(() {
      currentSong = song;
    });
    await _extractDominantColor(song);
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

    return Stack(
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
                      AppLocalizations.of(context).translate('welcome_back'),
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
                    child: Text(
                      AppLocalizations.of(context).translate('aurora_music'),
                      style: const TextStyle(
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
              preferredSize: const Size.fromHeight(48.0),
              child: Align(
                alignment: Alignment.center,
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: const OutlineIndicator(
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
                          AppLocalizations.of(context).translate('songs'),
                          style: const TextStyle(
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
                          AppLocalizations.of(context).translate('playlists'),
                          style: const TextStyle(
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
                          AppLocalizations.of(context).translate('settings'),
                          style: const TextStyle(
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
          body: Stack(
            children: [
              TabBarView(
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
                          _onSongTap(song);
                        },
                      );
                    },
                  ),
                  Center(
                    child: Text(AppLocalizations.of(context).translate('playlists'),
                        style: const TextStyle(color: Colors.white)),
                  ),
                  ListView(
                    children: [
                      ListTile(
                        title: const Text(
                          'Log Out',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context).translate('user_settings'),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        leading: const Icon(Icons.logout, color: Colors.white),
                        onTap: logout,
                      ),
                    ],
                  ),
                ],
              ),
              if (currentSong != null)
                Positioned(
                  bottom: 16.0,
                  left: 16.0,
                  right: 16.0,
                  child: GestureDetector(
                    onTap: () => _openNowPlayingScreen(currentSong!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: dominantColor ?? Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Row(
                        children: [
                          QueryArtworkWidget(
                            id: currentSong!.id,
                            type: ArtworkType.AUDIO,
                            artworkFit: BoxFit.cover,
                            artworkWidth: 50,
                            artworkHeight: 50,
                            nullArtworkWidget: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong!.title,
                                  style: TextStyle(
                                      color: textColor ?? Colors.white, fontSize: 16.0),
                                ),
                                Text(
                                  currentSong!.artist ?? 'Unknown Artist',
                                  style: TextStyle(
                                      color: textColor?.withOpacity(0.7) ?? Colors.grey, fontSize: 14.0),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.play_arrow, color: textColor ?? Colors.white),
                            onPressed: () {
                              // Handle play button press
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_next, color: textColor ?? Colors.white),
                            onPressed: () {
                              // Handle next button press
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
