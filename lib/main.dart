import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tunly/providers/music_provider.dart';
import 'package:tunly/screens/home_screen.dart';

void main() {
  runApp(const TunlyApp());
}

class TunlyApp extends StatelessWidget {
  const TunlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MusicProvider(),
      child: MaterialApp(
        title: 'Tunly',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: Colors.purple,
            secondary: Colors.pink,
            surface: Colors.black,
          ),
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}