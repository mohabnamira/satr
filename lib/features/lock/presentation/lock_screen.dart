import 'package:flutter/material.dart';
import 'package:satr/core/constants/app_constants.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.title,
    required this.onPin,
    this.canCancel = false,
  });

  final String title;
  final Future<String?> Function(String pin) onPin;
  final bool canCancel;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '<'],
  ];

  String _pin = '';
  String? _message;
  int _failures = 0;
  bool _busy = false;

  Future<void> _tap(String digit) async {
    if (_busy || _pin.length >= kPinLength) return;
    setState(() {
      _pin += digit;
      _message = null;
    });
    if (_pin.length < kPinLength) return;

    _busy = true;
    try {
      final error = await widget.onPin(_pin);

      if (!mounted) return;

      if (error != null) {
        _failures++;
        var message = error;

        if (_failures % kMaxPinAttemptsBeforeLockout == 0) {
          message =
              'Too many attempts. Try again in $kLockoutDurationSeconds seconds.';
          setState(() => _message = message);
          await Future.delayed(
              const Duration(seconds: kLockoutDurationSeconds));
          if (!mounted) return;
        }
        setState(() => _message = message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _pin = '';
          _busy = false;
        });
      }
    }
  }

  void _back() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _key(String k) {
    if (k.isEmpty) {
      return const SizedBox(
        width: 80,
        height: 64,
      );
    }

    return SizedBox(
      width: 80,
      height: 64,
      child: Semantics(
        label: k == '<' ? 'backspace' : k,
        button: true,
        child: TextButton(
          onPressed: () => k == '<' ? _back() : _tap(k),
          child: k == '<'
              ? const Icon(Icons.backspace_outlined)
              : Text(k, style: Theme.of(context).textTheme.headlineMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.canCancel ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title.toLowerCase(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < kPinLength; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        i < _pin.length ? Icons.circle : Icons.circle_outlined,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _message ?? ' ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 16),
              for (final row in _rows)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [for (final k in row) _key(k)],
                ),
            ],
          ),
        ),
      ),
    );
  }
}