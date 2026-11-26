import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/core/utils/alarm_challenge.dart';

void main() {
  group('easy alarm challenges', () {
    test('uses multiplication and division questions with integer answers', () {
      final multiplication = createAlarmChallenge('آسان', 4);
      expect(multiplication.question, '7 × 6 = ؟');
      expect(multiplication.answer, 42);

      final division = createAlarmChallenge('آسان', 5);
      expect(division.question, '16 ÷ 2 = ؟');
      expect(division.answer, 8);
    });
  });

  group('medium alarm challenges', () {
    test('uses a solvable quadratic or exact cube root', () {
      final quadratic = createAlarmChallenge('متوسط', 4);
      expect(quadratic.question, contains('x² − 20x + 91 = 0'));
      expect(quadratic.answer, 7);
      expect(7 * 7 - 20 * 7 + 91, 0);
      expect(13 * 13 - 20 * 13 + 91, 0);

      final cubeRoot = createAlarmChallenge('متوسط', 5);
      expect(cubeRoot.question, 'x³ = 512\nx = ؟');
      expect(cubeRoot.answer, 8);
      expect(8 * 8 * 8, 512);
    });
  });

  group('hard alarm challenges', () {
    test('uses exactly evaluable trigonometry and square roots', () {
      final sine = createAlarmChallenge('سخت', 4);
      expect(sine.question, '100 × sin(30°) + √49 = ؟');
      expect(sine.answer, 57);
      expect(100 * 0.5 + 7, sine.answer);

      final cosine = createAlarmChallenge('سخت', 5);
      expect(cosine.question, '100 × cos(60°) + √64 = ؟');
      expect(cosine.answer, 58);
      expect(100 * 0.5 + 8, cosine.answer);
    });
  });
}
