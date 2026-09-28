import 'package:flutter/material.dart';
import 'package:satr/core/widgets/app_toast.dart';
import 'package:satr/features/lock/data/pin_repository.dart';
import 'package:satr/features/lock/presentation/lock_screen.dart';

Future<void> setPin(BuildContext context, PinRepository repo) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => LockScreen(
        title: 'new pin',
        canCancel: true,
        onPin: (first) async {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LockScreen(
                title: 'confirm pin',
                canCancel: true,
                onPin: (second) async {
                  if (second != first) return "pins don't match";
                  try {
                    await repo.setPin(second);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      AppToast.show(context, message: 'pin saved');
                    }
                    return null;
                  } on PinStorageException catch (e) {
                    return e.message;
                  } catch (_) {
                    return "couldn't save your pin. please try again";
                  }
                },
              ),
            ),
          );
          return null;
        },
      ),
    ),
  );
}