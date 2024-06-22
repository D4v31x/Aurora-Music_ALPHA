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
import 'dart:ui';
import 'dart:typed_data';

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

    Widget buildBackground() {
      return FutureBuilder<Uint8List?>(
        future: currentSong != null
            ? OnAudioQuery().queryArtwork(currentSong!.id, ArtworkType.AUDIO)
            : Future.value(null),
        builder: (context, snapshot) {
          ImageProvider backgroundImage;
          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            backgroundImage = MemoryImage(snapshot.data!);
          } else {
            backgroundImage = AssetImage(isDarkMode
                ? 'assets/images/background/dark_back.jpg'
                : 'assets/images/background/light_back.jpg');
          }

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: backgroundImage,
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          );
        },
      );
    }


    return Stack(
      children: [
        buildBackground(),
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
          body: TabBarView(
            controller: _tabController,
            children: [
              buildHomeTab(),
              const Center(
                child: Text('Library'),
              ),
              const Center(
                child: Text('Discover'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget glassmorphicContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('quick_access'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10.0),
          buildQuickAccessSection(),
          const SizedBox(height: 30.0),
          Text(
            AppLocalizations.of(context).translate('suggested_tracks'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10.0),
          buildSuggestedTracksSection(),
          const SizedBox(height: 30.0),
          Text(
            AppLocalizations.of(context).translate('suggested_artists'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10.0),
          buildSuggestedArtistsSection(),
        ],
      ),
    );
  }

                      Widget buildQuickAccessSection() {
                        final favoritesPlaylist = 'Oblíbené';
                        final recentlyListenedPlaylists = ['Playlist 1']; // This should be dynamically populated

                        if (favoritesPlaylist.isNotEmpty || recentlyListenedPlaylists.isNotEmpty) {
                          return Column(
                            children: [
                              if (favoritesPlaylist.isNotEmpty)
                                glassmorphicContainer(
                                  child: ListTile(
                                    leading: const Icon(Icons.favorite, color: Colors.pink),
                                    title: Text(favoritesPlaylist, style: const TextStyle(color: Colors.white)),
                                    onTap: () {
                                      // Navigate to the favorites playlist
                                    },
                                  ),
                                ),
                              if (recentlyListenedPlaylists.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: glassmorphicContainer(
                                    child: ListTile(
                                      leading: const Icon(Icons.history, color: Colors.white),
                                      title: Text(recentlyListenedPlaylists[0], style: const TextStyle(color: Colors.white)),
                                      onTap: () {
                                        // Navigate to the recently listened playlist
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          );
                        } else {
                          return glassmorphicContainer(
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Žádná data k zobrazení', style: TextStyle(color: Colors.white)),
                            ),
                          );
                        }
                      }


  Widget buildSuggestedTracksSection() {
    if (songs.isNotEmpty) {
      final randomSongs = (songs.toList()..shuffle()).take(3).toList();
      return Column(
        children: randomSongs.map((song) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: glassmorphicContainer(
              child: ListTile(
                leading: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white),
                ),
                title: Text(song.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(song.artist ?? 'Unknown Artist', style: const TextStyle(color: Colors.grey)),
                trailing: const Icon(Icons.favorite_border, color: Colors.white),
                onTap: () {
                  _onSongTap(song);
                  _openNowPlayingScreen(song);
                },
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return glassmorphicContainer(
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Žádná data k zobrazení', style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Widget buildSuggestedArtistsSection() {
    if (songs.isNotEmpty) {
      final uniqueArtists = songs
          .map((song) => song.artist)
          .where((artist) => artist != null)
          .toSet()
          .toList();

      if (uniqueArtists.isNotEmpty) {
        final randomArtists = (uniqueArtists.toList()..shuffle()).take(3).toList();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: randomArtists.map((artist) {
            return glassmorphicContainer(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage('https://example.com/artist_image.jpg'), // Replace with actual artist image URL
                      child: artist!.isNotEmpty ? null : const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(artist, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }
    }
    return glassmorphicContainer(
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Žádná data k zobrazení', style: TextStyle(color: Colors.white)),
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