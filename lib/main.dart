import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main_screen.dart';
import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const GenLinkApp(),
    ),
  );
}

class GenLinkApp extends StatelessWidget {
  const GenLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GenLink KH',

          // Themes
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,

          // Home
          home: const MainScreen(),
        );
      },
    );
  }
}
