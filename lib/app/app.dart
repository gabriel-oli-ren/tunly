import 'package:flutter/cupertino.dart';
import 'router.dart';
import 'theme.dart';

class TunlyApp extends StatelessWidget {
  const TunlyApp({super.key});

  @override
  Widget build(BuildContext context) => CupertinoApp.router(
        title: 'Tunly',
        debugShowCheckedModeBanner: false,
        theme: TunlyTheme.dark,
        routerConfig: appRouter,
      );
}
