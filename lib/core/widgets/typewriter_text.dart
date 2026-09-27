import 'dart:async';
import 'package:flutter/material.dart';

/// Renders text with a smooth, character-by-character typewriter reveal animation.
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.durationPerChar = const Duration(milliseconds: 18),
    this.textDirection,
    this.textAlign,
    this.onComplete,
  });

  final String text;
  final TextStyle? style;
  final Duration durationPerChar;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final VoidCallback? onComplete;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  int _charCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    setState(() {
      _charCount = 0;
    });

    if (widget.text.isEmpty) {
      widget.onComplete?.call();
      return;
    }

    _timer = Timer.periodic(widget.durationPerChar, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_charCount < widget.text.length) {
        setState(() {
          _charCount++;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.text.substring(0, _charCount.clamp(0, widget.text.length));

    return Text(
      visibleText,
      style: widget.style,
      textDirection: widget.textDirection,
      textAlign: widget.textAlign,
    );
  }
}
