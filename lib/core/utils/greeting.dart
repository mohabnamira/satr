import 'dart:math';

String pickGreeting({DateTime? now}) {
  final hour = (now ?? DateTime.now()).hour;
  final random = Random();

  List<String> pool;
  if (hour >= 1 && hour <= 5) {
    pool = const [
      'staying up late?',
      'still awake?',
      'night thoughts?',
      'mind still running?',
      'quiet hours.',
    ];
  } else if (hour >= 6 && hour <= 8) {
    pool = const [
      'a new start.',
      'quiet morning.',
      'initial thoughts?',
      "here's to today.",
      'good morning.',
    ];
  } else if (hour >= 9 && hour <= 11) {
    pool = const [
      'step back for a second.',
      'reset for a moment.',
      "what's on your mind?",
      'taking a moment.',
      'how are things looking?',
    ];
  } else if (hour >= 12 && hour <= 16) {
    pool = const [
      'how is your day going?',
      'halfway through.',
      'catching your breath?',
      'pausing the hustle.',
    ];
  } else if (hour >= 17 && hour <= 20) {
    pool = const [
      'easing into the night.',
      'time to unburden.',
      'good evening.',
      'how was the day?',
    ];
  } else {
    pool = const [
      'nightfall stillness.',
      'letting the day go.',
      'wrapping up.',
      'time to reflect.',
    ];
  }

  return pool[random.nextInt(pool.length)];
}