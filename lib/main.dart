import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/home/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: PulseBudgetApp()));
}

class PulseBudgetApp extends StatelessWidget {
  const PulseBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse Budget',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
