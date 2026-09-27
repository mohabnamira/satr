import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satr/screens/home_screen.dart';
import 'package:satr/screens/onboarding_screen.dart';
import 'package:satr/main.dart';
import '../application/lock_providers.dart';
import 'lock_screen.dart';

class LockGate extends ConsumerWidget {
  const LockGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirstLaunch = ref.watch(isFirstLaunchProvider);
    if (isFirstLaunch) {
      return const OnboardingScreen();
    }

    final unlocked = ref.watch(unlockedProvider);
    if (unlocked) return const HomeScreen();

    return LockScreen(
      title: 'Enter PIN',
      onPin: (pin) async {
        try {
          final ok = await ref.read(pinRepositoryProvider).verify(pin);
          if (!ok) return 'Wrong PIN';
          ref.read(unlockedProvider.notifier).state = true;
          return null;
        } catch (e) {
          return e is Exception ? e.toString() : 'Something went wrong';
        }
      },
    );
  }
}