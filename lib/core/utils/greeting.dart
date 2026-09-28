import 'dart:math';

String pickGreeting({DateTime? now}) {
  final hour = (now ?? DateTime.now()).hour;
  final random = Random();

  List<String> pool;
  if (hour >= 1 && hour <= 5) {
    pool = const [
      'up late?',
      'still awake?',
      'night thoughts?',
      'mind running?',
      'quiet hours.',
    ];
  } else if (hour >= 6 && hour <= 8) {
    pool = const [
      'a new start.',
      'quiet morning.',
      'first thoughts?',
      'good morning.',
      "here's to today.",
    ];
  } else if (hour >= 9 && hour <= 11) {
    pool = const [
      'step back a sec.',
      'reset a moment.',
      "what's up?",
      'taking a moment.',
      "how's it going?",
    ];
  } else if (hour >= 12 && hour <= 16) {
    pool = const [
      "how's the day?",
      'halfway through.',
      'quick breather?',
      'pausing a bit.',
    ];
  } else if (hour >= 17 && hour <= 20) {
    pool = const [
      'into the night.',
      'time to unwind.',
      'good evening.',
      'how was today?',
    ];
  } else {
    pool = const [
      'nightfall.',
      'letting it go.',
      'wrapping up.',
      'time to reflect.',
    ];
  }

  return pool[random.nextInt(pool.length)];
}