import 'package:flutter/material.dart';
import 'package:genlink_frontend/main_screen.dart';
import 'package:provider/provider.dart';

import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          theme: lightTheme,
          darkTheme: darkTheme,

          themeMode: provider.themeMode,

          home: const MainScreen(),
        );
      },
    );
  }
}
