import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/index.dart';

void main() {
  runApp(
    const ProviderScope(
      child: LoomMonitoringApp(),
    ),
  );
}

class LoomMonitoringApp extends StatelessWidget {
  const LoomMonitoringApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loom Monitoring System',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(),
    );
  }
}
