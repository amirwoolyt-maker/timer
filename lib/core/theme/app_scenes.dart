// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum AppScene { cosmic, lantern, halloween, nowruz, anime, kawaii, ocean }

/// Stable identifiers are saved locally; unknown future/old values stay usable.
AppScene sceneFromId(String? value) => AppScene.values.firstWhere(
  (scene) => scene.name == value,
  orElse: () => AppScene.cosmic,
);

extension AppSceneDetails on AppScene {
  String get title => switch (this) {
    AppScene.cosmic => 'کهکشان',
    AppScene.lantern => 'شب فانوس‌ها',
    AppScene.halloween => 'هالووین',
    AppScene.nowruz => 'جشن نوروز',
    AppScene.anime => 'غروب انیمه',
    AppScene.kawaii => 'دنیای دخترانه',
    AppScene.ocean => 'آرامش اقیانوس',
  };
  String get titleEn => switch (this) {
    AppScene.cosmic => 'Cosmic',
    AppScene.lantern => 'Lantern night',
    AppScene.halloween => 'Halloween',
    AppScene.nowruz => 'Nowruz garden',
    AppScene.anime => 'Anime sunset',
    AppScene.kawaii => 'Kawaii dreams',
    AppScene.ocean => 'Ocean calm',
  };
  String get description => switch (this) {
    AppScene.cosmic => 'ستاره‌های چشمک‌زن و سحابی آرام',
    AppScene.lantern => 'فانوس چینی، ماه طلایی و کوهستان',
    AppScene.halloween => 'کدوهای خندان، خفاش و ماهِ شب',
    AppScene.nowruz => 'تم مناسبتی با لاله و شکوفه‌های بهاری',
    AppScene.anime => 'ابرهای کمیک، شکوفهٔ ساکورا و افق شهر',
    AppScene.kawaii => 'کارتونی و دخترانه؛ خرگوش، پاپیون و قلب',
    AppScene.ocean => 'موج‌های نرم، حباب و ماهی‌های کوچک',
  };
  String get descriptionEn => switch (this) {
    AppScene.cosmic => 'Twinkling stars and a quiet nebula',
    AppScene.lantern => 'Chinese lanterns, golden moon and mountains',
    AppScene.halloween => 'Smiling pumpkins, bats and a midnight moon',
    AppScene.nowruz => 'A seasonal garden of tulips and spring blossoms',
    AppScene.anime => 'Comic clouds, sakura blossoms and a city skyline',
    AppScene.kawaii => 'Cartoon bunnies, bows and floating hearts',
    AppScene.ocean => 'Gentle waves, bubbles and tiny fish',
  };
  IconData get icon => switch (this) {
    AppScene.cosmic => Icons.auto_awesome_rounded,
    AppScene.lantern => Icons.festival_rounded,
    AppScene.halloween => Icons.nights_stay_rounded,
    AppScene.nowruz => Icons.local_florist_rounded,
    AppScene.anime => Icons.animation_rounded,
    AppScene.kawaii => Icons.favorite_rounded,
    AppScene.ocean => Icons.waves_rounded,
  };
  Color get accent => switch (this) {
    AppScene.cosmic => const Color(0xFF10B981),
    AppScene.lantern => const Color(0xFFEFBF69),
    AppScene.halloween => const Color(0xFFFFA557),
    AppScene.nowruz => const Color(0xFF62CBA2),
    AppScene.anime => const Color(0xFFC3A0FF),
    AppScene.kawaii => const Color(0xFFFFA8D4),
    AppScene.ocean => const Color(0xFF6ED7EA),
  };
  Color get lightAccent => switch (this) {
    AppScene.cosmic => const Color(0xFF047857),
    AppScene.lantern => const Color(0xFF9D442C),
    AppScene.halloween => const Color(0xFF9E430F),
    AppScene.nowruz => const Color(0xFF176B50),
    AppScene.anime => const Color(0xFF7652AD),
    AppScene.kawaii => const Color(0xFFA33B70),
    AppScene.ocean => const Color(0xFF15677A),
  };
  Color background(bool dark) => dark
      ? switch (this) {
          AppScene.cosmic => const Color(0xFF0A0A0C),
          AppScene.lantern => const Color(0xFF1C1017),
          AppScene.halloween => const Color(0xFF17101F),
          AppScene.nowruz => const Color(0xFF0D1D1A),
          AppScene.anime => const Color(0xFF18152C),
          AppScene.kawaii => const Color(0xFF281B2C),
          AppScene.ocean => const Color(0xFF091D2B),
        }
      : switch (this) {
          AppScene.cosmic => const Color(0xFFF4F8F6),
          AppScene.lantern => const Color(0xFFFFF5E7),
          AppScene.halloween => const Color(0xFFFFF3E7),
          AppScene.nowruz => const Color(0xFFF0F8EB),
          AppScene.anime => const Color(0xFFF5F0FC),
          AppScene.kawaii => const Color(0xFFFFF0F7),
          AppScene.ocean => const Color(0xFFEDF9FC),
        };
  Color surface(bool dark) => Color.alphaBlend(
    Colors.white.withValues(alpha: dark ? .035 : .8),
    background(dark),
  );
}

/// Decorative art only: excluded from accessibility and input. Passing progress
/// from the shell keeps one shared, reduce-motion-aware animation controller.
class SceneBackground extends StatelessWidget {
  const SceneBackground({
    required this.scene,
    this.progress = 0,
    this.dark = true,
    this.preview = false,
    super.key,
  });
  final AppScene scene;
  final double progress;
  final bool dark;
  final bool preview;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ScenePainter(
            scene,
            MediaQuery.maybeOf(context)?.disableAnimations == true
                ? 0
                : progress,
            dark,
            preview,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.scene, this.progress, this.dark, this.preview);
  final AppScene scene;
  final double progress;
  final bool dark, preview;
  double get drift => math.sin(progress * math.pi * 2);
  Color shade(Color color, [double opacity = 1]) =>
      color.withValues(alpha: opacity * (preview ? 1 : (dark ? .65 : .64)));
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = scene.background(dark),
    );
    // Normalized art keeps illustrations legible in thumbnails and on tablets.
    canvas.save();
    canvas.scale(size.width / 400, size.height / 800);
    switch (scene) {
      case AppScene.cosmic:
        _cosmic(canvas);
      case AppScene.lantern:
        _lanternScene(canvas);
      case AppScene.halloween:
        _halloween(canvas);
      case AppScene.nowruz:
        _nowruz(canvas);
      case AppScene.anime:
        _anime(canvas);
      case AppScene.kawaii:
        _kawaii(canvas);
      case AppScene.ocean:
        _ocean(canvas);
    }
    canvas.restore();
  }

  void _glow(Canvas c, Offset point, Color color, double radius) {
    c.drawCircle(
      point,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: dark ? .16 : .11),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: point, radius: radius)),
    );
  }

  void _line(Canvas c, Offset a, Offset b, Color color, [double width = 1]) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
  void _cosmic(Canvas c) {
    _glow(c, const Offset(320, 100), scene.accent, 320);
    _glow(c, const Offset(30, 650), const Color(0xFF7467DF), 290);
    final random = math.Random(1947);
    for (var i = 0; i < 105; i++) {
      final p = Offset(random.nextDouble() * 400, random.nextDouble() * 800);
      final r = .5 + random.nextDouble() * 1.1;
      final alpha = .25 + .35 * (.5 + .5 * math.sin(progress * 6.28 + i));
      final color = (dark ? const Color(0xFFD5EFE9) : const Color(0xFF426E66))
          .withValues(alpha: alpha);
      c.drawCircle(p, r, Paint()..color = color);
      if (i % 13 == 0) {
        _line(c, p - const Offset(0, 4), p + const Offset(0, 4), color, .6);
        _line(c, p - const Offset(4, 0), p + const Offset(4, 0), color, .6);
      }
    }
  }

  void _moon(Canvas c, Offset p, double radius, Color color) {
    _glow(c, p, color, radius * 4);
    c.drawCircle(p, radius, Paint()..color = shade(color, .7));
    for (var i = 0; i < 4; i++) {
      c.drawCircle(
        p +
            Offset(
              -radius * .5 + i * radius * .25,
              radius * .25 * (i.isEven ? 1 : -1),
            ),
        radius * .1,
        Paint()..color = shade(scene.background(dark), .2),
      );
    }
  }

  void _lanternScene(Canvas c) {
    const gold = Color(0xFFE7BC71), red = Color(0xFFDD554D);
    _moon(c, const Offset(302, 95), 39, gold);
    _line(c, const Offset(0, 15), const Offset(400, 35), shade(gold, .55), 1.2);
    for (final item in [
      (62.0, 80.0, 1.0),
      (182.0, 47.0, .7),
      (363.0, 165.0, .65),
    ]) {
      c.save();
      c.translate(item.$1 + drift * 3, item.$2);
      c.scale(item.$3);
      _line(c, const Offset(0, -80), const Offset(0, -27), shade(gold, .55));
      c.drawOval(
        const Rect.fromLTWH(-25, -25, 50, 65),
        Paint()..color = shade(red, .72),
      );
      for (final x in [-13.0, 0.0, 13.0]) {
        c.drawOval(
          Rect.fromCenter(
            center: const Offset(0, 7),
            width: 20 + x.abs(),
            height: 62,
          ),
          Paint()
            ..color = shade(gold, .25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8,
        );
      }
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-17, -28, 34, 6),
          const Radius.circular(2),
        ),
        Paint()..color = shade(gold, .85),
      );
      c.drawRect(
        const Rect.fromLTWH(-14, 38, 28, 5),
        Paint()..color = shade(gold, .85),
      );
      _line(c, const Offset(0, 44), const Offset(0, 61), shade(gold, .8));
      for (var i = -3; i <= 3; i++) {
        _line(c, Offset(i * 1.4, 61), Offset(i * 1.6, 78), shade(red, .7));
      }
      c.restore();
    }
    for (var layer = 0; layer < 3; layer++) {
      final base = 780.0 - layer * 25;
      final path = Path()
        ..moveTo(0, 800)
        ..lineTo(0, base);
      for (var x = 0.0; x <= 440; x += 40) {
        path.lineTo(x, base - 28 - math.sin(x / 65 + layer) * (30 + layer * 8));
      }
      path
        ..lineTo(400, 800)
        ..close();
      c.drawPath(path, Paint()..color = shade(red, .07 + layer * .035));
    }
    // A small tiered pavilion, rather than another star-field silhouette.
    for (var i = 0; i < 3; i++) {
      final y = 692.0 + i * 25;
      final half = 21.0 + i * 10;
      final roof = Path()
        ..moveTo(325 - half, y + 9)
        ..quadraticBezierTo(325, y + 7, 325, y - 10)
        ..quadraticBezierTo(325, y + 7, 325 + half, y + 9)
        ..close();
      c.drawPath(roof, Paint()..color = shade(gold, .3));
      c.drawRect(
        Rect.fromLTWH(315, y + 9, 20, 15),
        Paint()..color = shade(red, .3),
      );
    }
  }

  void _bat(Canvas c, Offset p, double scale) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(scale);
    final path = Path()
      ..moveTo(0, 1)
      ..quadraticBezierTo(-9, -16, -23, -9)
      ..quadraticBezierTo(-16, -2, -17, 6)
      ..quadraticBezierTo(-10, 0, -5, 8)
      ..lineTo(0, 4)
      ..lineTo(5, 8)
      ..quadraticBezierTo(10, 0, 17, 6)
      ..quadraticBezierTo(16, -2, 23, -9)
      ..quadraticBezierTo(9, -16, 0, 1)
      ..close();
    c.drawPath(
      path,
      Paint()
        ..color = shade(
          dark ? const Color(0xFFA395BC) : const Color(0xFF483459),
          .5,
        ),
    );
    c.restore();
  }

  void _pumpkin(Canvas c, Offset p, double scale) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(scale);
    const orange = Color(0xFFED853D);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-4, -38, 8, 16),
        const Radius.circular(3),
      ),
      Paint()..color = shade(const Color(0xFF80A27B), .8),
    );
    c.drawOval(
      const Rect.fromLTWH(-38, -27, 76, 55),
      Paint()..color = shade(orange, .8),
    );
    for (var x = -2; x <= 2; x++) {
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(0, 0),
          width: 24 + x.abs() * 19,
          height: 54,
        ),
        Paint()
          ..color = shade(const Color(0xFF7C3F27), .3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    for (final x in [-14.0, 14.0]) {
      c.drawPath(
        Path()
          ..moveTo(x, -15)
          ..lineTo(x - 7, -3)
          ..lineTo(x + 7, -3)
          ..close(),
        Paint()..color = shade(const Color(0xFFFFE4A0), .95),
      );
    }
    c.drawArc(
      const Rect.fromLTWH(-18, -1, 36, 20),
      0,
      math.pi,
      false,
      Paint()
        ..color = shade(const Color(0xFF5F332D), .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    c.restore();
  }

  void _halloween(Canvas c) {
    _moon(c, const Offset(312, 100), 48, const Color(0xFFE0CAA2));
    _bat(c, Offset(67 + drift * 6, 80), .8);
    _bat(c, Offset(224 - drift * 5, 154), .65);
    _bat(c, Offset(365 + drift * 3, 229), .45);
    final branch = Paint()
      ..color = shade(const Color(0xFF9E76B3), .24)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawPath(
      Path()
        ..moveTo(0, 600)
        ..lineTo(12, 400)
        ..lineTo(2, 300)
        ..moveTo(10, 460)
        ..lineTo(54, 419)
        ..lineTo(73, 359)
        ..moveTo(54, 419)
        ..lineTo(85, 420),
      branch,
    );
    _pumpkin(c, const Offset(52, 743), .95);
    _pumpkin(c, const Offset(344, 768), .7);
    for (var i = 0; i < 12; i++) {
      c.drawCircle(
        Offset((i * 93) % 400, 670 + math.sin(i * 1.6 + progress * 6.28) * 25),
        1.6,
        Paint()..color = shade(scene.accent, .4),
      );
    }
  }

  void _flower(Canvas c, Offset p, double r, Color color) {
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5;
      c.drawCircle(
        p + Offset(math.cos(a), math.sin(a)) * r * .56,
        r * .48,
        Paint()..color = shade(color, .75),
      );
    }
    c.drawCircle(
      p,
      r * .19,
      Paint()..color = shade(const Color(0xFFFFDA83), .9),
    );
  }

  void _nowruz(Canvas c) {
    _glow(c, const Offset(230, 30), const Color(0xFFEBCE75), 250);
    final branch = Path()
      ..moveTo(-10, 95)
      ..quadraticBezierTo(85, 93, 159, 8)
      ..moveTo(50, 82)
      ..quadraticBezierTo(69, 45, 54, 11)
      ..moveTo(97, 51)
      ..quadraticBezierTo(141, 62, 181, 45);
    c.drawPath(
      branch,
      Paint()
        ..color = shade(const Color(0xFF967961), .7)
        ..strokeWidth = 2.7
        ..style = PaintingStyle.stroke,
    );
    for (final p in [
      const Offset(22, 89),
      const Offset(56, 39),
      const Offset(91, 59),
      const Offset(127, 32),
      const Offset(161, 49),
    ]) {
      _flower(c, p + Offset(0, drift * 1.7), 10, const Color(0xFFF0B6CB));
    }
    for (var i = 0; i < 8; i++) {
      final x = 12.0 + i * 55;
      final y = 762.0 + math.sin(i * 2) * 17;
      _line(
        c,
        Offset(x, 810),
        Offset(x + drift * 2, y - 25),
        shade(const Color(0xFF5CA081), .5),
        2,
      );
      final leaf = Path()
        ..moveTo(x, 795)
        ..quadraticBezierTo(x - 26, 779, x - 17, 766)
        ..quadraticBezierTo(x, 773, x, 795);
      c.drawPath(leaf, Paint()..color = shade(const Color(0xFF6BAE80), .4));
      final tulip = Path()
        ..moveTo(x - 12, y - 35)
        ..lineTo(x - 4, y - 29)
        ..lineTo(x, y - 40)
        ..lineTo(x + 5, y - 29)
        ..lineTo(x + 13, y - 35)
        ..quadraticBezierTo(x + 13, y - 12, x, y - 13)
        ..quadraticBezierTo(x - 12, y - 12, x - 12, y - 35)
        ..close();
      c.drawPath(
        tulip,
        Paint()
          ..color = shade(
            i.isEven ? const Color(0xFFEE92A1) : const Color(0xFFE5BD65),
            .72,
          ),
      );
    }
    for (var i = 0; i < 10; i++) {
      final p = Offset(30.0 + i * 42, 165.0 + (i * 97) % 420 + drift * 4);
      c.drawOval(
        Rect.fromCenter(center: p, width: 4, height: 8),
        Paint()..color = shade(const Color(0xFFDFA0B6), .3),
      );
    }
  }

  void _cloud(Canvas c, Offset p, double scale, Color color) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(scale);
    final paint = Paint()..color = shade(color, .45);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-45, 0, 90, 20),
        const Radius.circular(12),
      ),
      paint,
    );
    c.drawCircle(const Offset(-20, 0), 17, paint);
    c.drawCircle(const Offset(5, -8), 25, paint);
    c.drawCircle(const Offset(27, 0), 15, paint);
    c.restore();
  }

  void _anime(Canvas c) {
    _glow(c, const Offset(290, 120), const Color(0xFFEC91B8), 250);
    _moon(c, const Offset(312, 110), 39, const Color(0xFFE5AACA));
    _cloud(c, Offset(75 + drift * 4, 75), 1.25, const Color(0xFFA08EBB));
    _cloud(c, Offset(275 - drift * 3, 208), .8, const Color(0xFFBAA0D1));
    final mountains = Path()
      ..moveTo(0, 800)
      ..lineTo(0, 737)
      ..lineTo(91, 679)
      ..lineTo(157, 745)
      ..lineTo(251, 667)
      ..lineTo(400, 760)
      ..lineTo(400, 800)
      ..close();
    c.drawPath(mountains, Paint()..color = shade(const Color(0xFF8E76B7), .18));
    for (var i = 0; i < 18; i++) {
      final x = i * 24.0;
      final h = 20.0 + (i * 29) % 48;
      c.drawRect(
        Rect.fromLTWH(x, 810 - h, 18, h),
        Paint()..color = shade(const Color(0xFF8976AC), .24),
      );
      if (i % 3 == 0) {
        _line(
          c,
          Offset(x + 9, 810 - h),
          Offset(x + 9, 795 - h),
          shade(const Color(0xFF8976AC), .3),
        );
      }
    }
    // Comic framing and floating sakura are distinct from the cosmic theme.
    _line(
      c,
      const Offset(2, 246),
      const Offset(77, 226),
      shade(const Color(0xFFB39BD9), .22),
    );
    _line(
      c,
      const Offset(1, 255),
      const Offset(53, 240),
      shade(const Color(0xFFB39BD9), .15),
    );
    for (var i = 0; i < 14; i++) {
      final p = Offset(
        (i * 137 % 400).toDouble(),
        50.0 + (i * 89) % 650 + drift * 4,
      );
      if (i % 4 == 0) {
        _flower(c, p, 5, const Color(0xFFE4A0C0));
      } else {
        c.drawOval(
          Rect.fromCenter(center: p, width: 4, height: 8),
          Paint()..color = shade(const Color(0xFFE4A0C0), .35),
        );
      }
    }
  }

  void _heart(Canvas c, Offset p, double scale, Color color) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(scale);
    final heart = Path()
      ..moveTo(0, 11)
      ..cubicTo(-25, -3, -12, -20, 0, -9)
      ..cubicTo(12, -20, 25, -3, 0, 11)
      ..close();
    c.drawPath(heart, Paint()..color = shade(color, .55));
    c.restore();
  }

  void _kawaii(Canvas c) {
    const pink = Color(0xFFECA2CA), cream = Color(0xFFE9D6E9);
    _glow(c, const Offset(195, 62), pink, 300);
    _cloud(c, const Offset(65, 91), 1.3, pink);
    _cloud(c, const Offset(329, 174), .9, const Color(0xFFB6B0E0));
    for (var i = 0; i < 9; i++) {
      _heart(
        c,
        Offset(20.0 + i * 48, 32 + (i * 119) % 670 + drift * 4),
        i.isEven ? .38 : .24,
        i.isEven ? pink : const Color(0xFFAEA1DE),
      );
    }
    // A hand-drawn cartoon bunny with long ears, face, cheeks and bow.
    c.save();
    c.translate(331, 730);
    final fur = Paint()..color = shade(cream, .55);
    c.drawOval(const Rect.fromLTWH(-23, -83, 18, 58), fur);
    c.drawOval(const Rect.fromLTWH(7, -86, 18, 61), fur);
    c.drawOval(
      const Rect.fromLTWH(-18, -77, 8, 43),
      Paint()..color = shade(pink, .52),
    );
    c.drawOval(
      const Rect.fromLTWH(12, -79, 8, 43),
      Paint()..color = shade(pink, .52),
    );
    c.drawOval(const Rect.fromLTWH(-37, -38, 74, 64), fur);
    final face = shade(
      dark ? const Color(0xFF38243D) : const Color(0xFF7B5274),
      .8,
    );
    c.drawCircle(const Offset(-12, -12), 2.4, Paint()..color = face);
    c.drawCircle(const Offset(12, -12), 2.4, Paint()..color = face);
    _line(c, const Offset(-3, -3), const Offset(0, 0), face, 1.3);
    _line(c, const Offset(0, 0), const Offset(3, -3), face, 1.3);
    c.drawOval(
      const Rect.fromLTWH(-25, -7, 13, 6),
      Paint()..color = shade(pink, .65),
    );
    c.drawOval(
      const Rect.fromLTWH(13, -7, 13, 6),
      Paint()..color = shade(pink, .65),
    );
    final bow = Path()
      ..moveTo(20, -28)
      ..lineTo(2, -37)
      ..quadraticBezierTo(-2, -25, 4, -18)
      ..close()
      ..moveTo(20, -28)
      ..lineTo(36, -40)
      ..quadraticBezierTo(44, -29, 38, -21)
      ..close();
    c.drawPath(bow, Paint()..color = shade(pink, .9));
    c.drawCircle(
      const Offset(20, -28),
      5,
      Paint()..color = shade(const Color(0xFFCF75A6), .9),
    );
    c.restore();
    // Scalloped stationery edge.
    for (var i = 0; i < 14; i++) {
      c.drawCircle(
        Offset(i * 32.0, 809),
        18,
        Paint()..color = shade(pink, .11),
      );
    }
  }

  void _ocean(Canvas c) {
    _glow(c, const Offset(320, 70), const Color(0xFF5BC8DB), 320);
    for (var i = 0; i < 16; i++) {
      final p = Offset(
        15.0 + (i * 109) % 380,
        50.0 + (i * 89) % 700 - drift * (i % 3 + 1) * 3,
      );
      c.drawCircle(
        p,
        2.0 + i % 4,
        Paint()
          ..color = shade(const Color(0xFF87D9E8), .18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
    }
    for (var layer = 0; layer < 4; layer++) {
      final y = 713.0 + layer * 25;
      final path = Path()
        ..moveTo(0, 800)
        ..lineTo(0, y);
      for (var x = 0.0; x <= 420; x += 10) {
        path.lineTo(x, y + math.sin(x / 65 + progress * 6.28 + layer) * 13);
      }
      path
        ..lineTo(400, 800)
        ..close();
      c.drawPath(
        path,
        Paint()..color = shade(const Color(0xFF52B6CE), .08 + layer * .04),
      );
    }
    for (var i = 0; i < 4; i++) {
      final p = Offset(45.0 + i * 83 + drift * 3, 130.0 + (i * 171) % 550);
      c.drawOval(
        Rect.fromCenter(center: p, width: 17, height: 8),
        Paint()..color = shade(const Color(0xFF7CCDDC), .35),
      );
      c.drawPath(
        Path()
          ..moveTo(p.dx + 7, p.dy)
          ..lineTo(p.dx + 14, p.dy - 5)
          ..lineTo(p.dx + 14, p.dy + 5)
          ..close(),
        Paint()..color = shade(const Color(0xFF7CCDDC), .35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.scene != scene ||
      oldDelegate.progress != progress ||
      oldDelegate.dark != dark ||
      oldDelegate.preview != preview;
}
