import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satr/features/home/presentation/home_screen.dart';
import 'package:satr/features/lock/application/lock_providers.dart';
import 'package:satr/features/lock/data/pin_repository.dart';
import 'package:satr/features/lock/presentation/lock_screen.dart';
import 'package:satr/features/onboarding/application/onboarding_providers.dart';
import 'package:satr/features/onboarding/presentation/onboarding_screen.dart';

class LockGate extends ConsumerWidget {
  const LockGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirstLaunch = ref.watch(isFirstLaunchProvider);
    if (isFirstLaunch) {
      return const OnboardingScreen();
    }

    final unlocked = ref.watch(unlockedProvider);
    if (unlocked) {
      return const HomeScreen();
    }

    return LockScreen(
      title: 'satr',
      onPin: (pin) async {
        try {
          final ok = await ref.read(pinRepositoryProvider).verify(pin);
          if (ok) {
            ref.read(unlockedProvider.notifier).state = true;
            return null;
          }
          return 'wrong pin';
        } on PinStorageException catch (e) {
          return e.message;
        } catch (_) {
          return "couldn't check your pin. please try again";
        }
      },
    );
  }
}