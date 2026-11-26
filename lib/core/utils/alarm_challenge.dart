/// A reproducible arithmetic prompt so each difficulty can be tested directly.
class AlarmChallenge {
  const AlarmChallenge({required this.question, required this.answer});

  final String question;
  final int answer;
}

AlarmChallenge createAlarmChallenge(String level, int seed) {
  final a = seed.abs() % 7 + 3;
  final b = seed.abs() % 5 + 2;
  if (level == 'متوسط') {
    if (seed.isEven) {
      return AlarmChallenge(
        question:
            'x² − ${2 * a + b}x + ${a * (a + b)} = 0\nریشهٔ کوچک‌تر را بنویس.',
        answer: a,
      );
    }
    return AlarmChallenge(question: 'x³ = ${a * a * a}\nx = ؟', answer: a);
  }
  if (level == 'سخت') {
    return AlarmChallenge(
      question: seed.isEven
          ? '100 × sin(30°) + √${a * a} = ؟'
          : '100 × cos(60°) + √${a * a} = ؟',
      answer: 50 + a,
    );
  }
  if (seed.isEven) {
    return AlarmChallenge(question: '$a × $b = ؟', answer: a * b);
  }
  return AlarmChallenge(question: '${a * b} ÷ $b = ؟', answer: a);
}
