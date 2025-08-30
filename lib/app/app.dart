import 'package:flutter/material.dart';
import 'package:flutter_test_lab/features/home/presentation/pages/home_page.dart';
import 'package:flutter_test_lab/core/theme/app_theme.dart';

class FlutterTestLabApp extends StatelessWidget {
  const FlutterTestLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Test Lab',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
