import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'providers/music_provider.dart';
import 'screens/home_screen.dart';
import 'screens/now_playing_screen.dart';
import 'widgets/liquid_glass_components.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const TunelyApp());
}

class TunelyApp extends StatelessWidget {
  const TunelyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MusicProvider(),
      child: MaterialApp(
        title: 'Tunely',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          useMaterial3: true,
          cupertinoOverrideTheme: const CupertinoThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        return Stack(
          children: [
            const HomeScreen(),
            if (musicProvider.currentSong != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MiniPlayer(),
              ),
          ],
        );
      },
    );
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        final song = musicProvider.currentSong;
        if (song == null) return const SizedBox.shrink();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NowPlayingScreen(),
                  ),
                );
              },
              child: LiquidGlassCard(
                borderRadius: 20,
                blur: 20,
                thickness: 15,
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          song.coverImage,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artist,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      LiquidGlassButton(
                        onPressed: () => musicProvider.togglePlayPause(),
                        borderRadius: 28,
                        width: 56,
                        height: 56,
                        child: Icon(
                          musicProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
