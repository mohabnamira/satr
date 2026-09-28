import 'package:flutter/material.dart';
import 'package:satr/core/constants/app_constants.dart';
import 'package:satr/core/theme/app_theme.dart';

/// Global minimalist floating toast utility styled with a capsule shape,
/// dark #1A1A1A background, subtle border, and crisp lowercase typography.
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;

  /// Shows a standard floating toast message at the bottom center.
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = kToastDuration,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _showOverlay(
      overlay,
      message: message.toLowerCase(),
      duration: duration,
    );
  }

  /// Shows a floating toast with an Undo action button.
  static void showUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = kToastUndoDuration,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _showOverlay(
      overlay,
      message: message.toLowerCase(),
      onUndo: onUndo,
      duration: duration,
    );
  }

  /// Directly shows on an OverlayState.
  static void showWithOverlay(
    OverlayState overlayState, {
    required String message,
    VoidCallback? onUndo,
    Duration duration = kToastOverlayDuration,
  }) {
    _showOverlay(
      overlayState,
      message: message.toLowerCase(),
      onUndo: onUndo,
      duration: duration,
    );
  }

  static void _showOverlay(
    OverlayState overlayState, {
    required String message,
    VoidCallback? onUndo,
    required Duration duration,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _AppToastWidget(
        message: message,
        onUndo: onUndo == null
            ? null
            : () {
                entry.remove();
                if (_currentEntry == entry) _currentEntry = null;
                onUndo();
              },
        duration: duration,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }
}

class _AppToastWidget extends StatefulWidget {
  const _AppToastWidget({
    required this.message,
    this.onUndo,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback? onUndo;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });

    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted) return;
    setState(() => _visible = false);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final animDuration = disableAnimations ? Duration.zero : kToastAnimationDuration;
    if (animDuration == Duration.zero) {
      widget.onDismiss();
    } else {
      Future.delayed(animDuration, widget.onDismiss);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final animDuration = disableAnimations ? Duration.zero : kToastAnimationDuration;
    final fadeDuration = disableAnimations ? Duration.zero : kToastFadeDuration;

    return Positioned(
      left: kHorizontalPadding,
      right: kHorizontalPadding,
      bottom: 32,
      child: IgnorePointer(
        ignoring: !_visible,
        child: AnimatedSlide(
          duration: animDuration,
          curve: Curves.easeOutCubic,
          offset: _visible ? Offset.zero : const Offset(0, 0.35),
          child: AnimatedOpacity(
            duration: fadeDuration,
            curve: Curves.easeOut,
            opacity: _visible ? 1.0 : 0.0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.toastBackground,
                    borderRadius: BorderRadius.circular(kRadiusPill),
                    border: Border.all(color: AppTheme.toastBorder, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: AppTheme.toastText,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'WorkSans',
                            decoration: TextDecoration.none,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.onUndo != null) ...[
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: widget.onUndo,
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              'undo',
                              style: TextStyle(
                                color: AppTheme.toastText,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'WorkSans',
                                decoration: TextDecoration.underline,
                                decorationColor: AppTheme.toastMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
