import 'package:flutter/material.dart';
import 'package:satr/core/widgets/app_toast.dart';
import '../data/pin_repository.dart';
import 'lock_screen.dart';

Future<void> showLockMenu(BuildContext context, PinRepository repo) async {
  final hasPin = await repo.hasPin();

  if (!context.mounted) return;

  if (!hasPin) {
    setPin(context, repo);
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Change PIN'),
            onTap: () {
              Navigator.of(sheetContext).pop(); // close the sheet
              setPin(context, repo);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_open_outlined),
            title: const Text('Remove PIN'),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await repo.clearPin();
              if (context.mounted) {
                AppToast.show(context, message: 'pin removed');
              }
            },
          ),
        ],
      ),
    ),
  );
}
Future<void> setPin(BuildContext context, PinRepository repo) {
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => LockScreen(
      title: 'New PIN',
      canCancel: true,
      onPin: (first) async {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => LockScreen(
            title: 'Confirm PIN',
            canCancel: true,
            onPin: (second) async {
              if (second != first) return "PINs don't match";
              await repo.setPin(second);
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                AppToast.show(context, message: 'pin saved');
              }
              return null;
            },
          ),
        ));
        return null;
      },
    ),
  ));
}