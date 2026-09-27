import 'package:flutter/material.dart';
import 'app_toast.dart';

export 'app_toast.dart';

void showUndoToast(
  OverlayState overlayState, {
  required String message,
  required VoidCallback onUndo,
}) {
  AppToast.showWithOverlay(
    overlayState,
    message: message,
    onUndo: onUndo,
  );
}