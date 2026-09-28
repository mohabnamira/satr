import 'package:flutter/material.dart';
import 'package:satr/core/theme/app_theme.dart';
import 'package:satr/features/lock/presentation/lock_gate.dart';

class SatrApp extends StatelessWidget {
  const SatrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'satr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const LockGate(),
    );
  }
}
