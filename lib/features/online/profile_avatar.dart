// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({required this.avatar, this.radius = 34, super.key});
  final String avatar;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    child: AvatarGlyph(avatar: avatar, size: radius * 1.55),
  );
}

class AvatarGlyph extends StatelessWidget {
  const AvatarGlyph({required this.avatar, this.size = 40, super.key});
  final String avatar;
  final double size;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _AvatarPainter(avatar));
}

/// Drawn avatars stay sharp and do not depend on a device's emoji font.
class _AvatarPainter extends CustomPainter {
  const _AvatarPainter(this.kind);
  final String kind;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    void circle(double x, double y, double r, Color color) =>
        canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
    void line(Offset from, Offset to, Color color, [double width = 3]) =>
        canvas.drawLine(
          from,
          to,
          Paint()
            ..color = color
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round,
        );
    void oval(Rect rect, Color color) =>
        canvas.drawOval(rect, Paint()..color = color);
    void triangle(Offset a, Offset b, Offset c, Color color) => canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..close(),
      Paint()..color = color,
    );
    const ink = Color(0xFF302941),
        white = Color(0xFFFFF7ED),
        pink = Color(0xFFF6A4BF);
    void face() {
      circle(39, 53, 3, ink);
      circle(62, 53, 3, ink);
      canvas.drawArc(
        const Rect.fromLTWH(43, 57, 15, 12),
        .1,
        math.pi - .2,
        false,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
      oval(const Rect.fromLTWH(25, 59, 12, 6), pink);
      oval(const Rect.fromLTWH(65, 59, 12, 6), pink);
    }

    switch (kind) {
      case '':
        circle(50, 35, 17, const Color(0xFFAFCCCB));
        oval(const Rect.fromLTWH(15, 58, 70, 45), const Color(0xFFAFCCCB));
      case 'moon':
        circle(50, 50, 34, const Color(0xFFFFD979));
        circle(64, 36, 29, const Color(0xFF665089));
        circle(22, 25, 3, white);
        circle(78, 72, 4, white);
        circle(24, 79, 2, white);
      case 'planet':
        circle(50, 50, 27, const Color(0xFFBD9AE8));
        line(const Offset(32, 39), const Offset(68, 44), pink, 7);
        line(
          const Offset(31, 58),
          const Offset(65, 65),
          const Color(0xFF9975CC),
          7,
        );
        canvas.drawOval(
          const Rect.fromLTWH(6, 36, 88, 29),
          Paint()
            ..color = const Color(0xFFFFD979)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6,
        );
      case 'flower':
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          circle(50 + 25 * math.cos(a), 50 + 25 * math.sin(a), 17, pink);
        }
        circle(50, 50, 22, const Color(0xFFFFD979));
        face();
      case 'butterfly':
        oval(const Rect.fromLTWH(9, 15, 39, 51), const Color(0xFFBC9EE9));
        oval(const Rect.fromLTWH(52, 15, 39, 51), const Color(0xFFBC9EE9));
        oval(const Rect.fromLTWH(18, 53, 31, 34), pink);
        oval(const Rect.fromLTWH(51, 53, 31, 34), pink);
        line(const Offset(50, 31), const Offset(50, 78), ink, 8);
        line(const Offset(49, 34), const Offset(38, 20), ink, 2);
        line(const Offset(51, 34), const Offset(62, 20), ink, 2);
        circle(29, 39, 7, white);
        circle(71, 39, 7, white);
      case 'cherry':
        line(
          const Offset(30, 61),
          const Offset(56, 15),
          const Color(0xFF428769),
          5,
        );
        line(
          const Offset(72, 62),
          const Offset(56, 15),
          const Color(0xFF428769),
          5,
        );
        oval(const Rect.fromLTWH(54, 10, 25, 12), const Color(0xFF5FAC71));
        circle(30, 67, 21, const Color(0xFFE87595));
        circle(72, 67, 21, const Color(0xFFCD4B77));
        circle(23, 61, 4, white);
        circle(65, 61, 4, white);
      case 'robot':
        line(const Offset(50, 17), const Offset(50, 30), ink, 4);
        circle(50, 14, 6, pink);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(16, 29, 68, 55),
            const Radius.circular(15),
          ),
          Paint()..color = const Color(0xFF80CFD0),
        );
        circle(36, 51, 7, white);
        circle(64, 51, 7, white);
        circle(36, 51, 3, ink);
        circle(64, 51, 3, ink);
        line(const Offset(39, 69), const Offset(61, 69), ink, 4);
      case 'rabbit':
        oval(const Rect.fromLTWH(24, 2, 20, 48), white);
        oval(const Rect.fromLTWH(56, 2, 20, 48), white);
        oval(const Rect.fromLTWH(30, 8, 8, 35), pink);
        oval(const Rect.fromLTWH(62, 8, 8, 35), pink);
        oval(const Rect.fromLTWH(17, 29, 66, 58), white);
        face();
      case 'panda':
        circle(25, 27, 14, ink);
        circle(75, 27, 14, ink);
        circle(50, 55, 34, white);
        oval(const Rect.fromLTWH(27, 40, 21, 25), ink);
        oval(const Rect.fromLTWH(53, 40, 21, 25), ink);
        circle(38, 50, 4, white);
        circle(62, 50, 4, white);
        triangle(
          const Offset(44, 66),
          const Offset(56, 66),
          const Offset(50, 73),
          ink,
        );
      case 'owl':
        triangle(
          const Offset(18, 38),
          const Offset(15, 12),
          const Offset(44, 29),
          const Color(0xFFBB8C69),
        );
        triangle(
          const Offset(82, 38),
          const Offset(85, 12),
          const Offset(56, 29),
          const Color(0xFFBB8C69),
        );
        oval(const Rect.fromLTWH(14, 21, 72, 68), const Color(0xFFBB8C69));
        circle(35, 51, 19, white);
        circle(65, 51, 19, white);
        circle(36, 51, 7, ink);
        circle(64, 51, 7, ink);
        triangle(
          const Offset(44, 66),
          const Offset(56, 66),
          const Offset(50, 77),
          const Color(0xFFF3BD67),
        );
      case 'unicorn':
        triangle(
          const Offset(45, 33),
          const Offset(52, 1),
          const Offset(61, 34),
          const Color(0xFFFFD979),
        );
        circle(70, 56, 30, const Color(0xFFBAA1DF));
        oval(const Rect.fromLTWH(20, 24, 57, 64), white);
        triangle(
          const Offset(25, 35),
          const Offset(23, 9),
          const Offset(43, 29),
          white,
        );
        face();
      case 'cat':
        const fur = Color(0xFFFFD2A4);
        triangle(
          const Offset(17, 49),
          const Offset(15, 11),
          const Offset(45, 32),
          fur,
        );
        triangle(
          const Offset(83, 49),
          const Offset(85, 11),
          const Offset(55, 32),
          fur,
        );
        circle(50, 56, 34, fur);
        face();
        for (var i = 0; i < 2; i++) {
          line(Offset(10, 57 + i * 10), Offset(29, 60 + i * 5), ink, 2);
          line(Offset(71, 60 + i * 5), Offset(90, 57 + i * 10), ink, 2);
        }
      default:
        const fur = Color(0xFFEAA16F);
        triangle(
          const Offset(17, 43),
          const Offset(16, 8),
          const Offset(44, 30),
          fur,
        );
        triangle(
          const Offset(83, 43),
          const Offset(84, 8),
          const Offset(56, 30),
          fur,
        );
        circle(50, 52, 35, fur);
        oval(const Rect.fromLTWH(22, 43, 56, 39), white);
        face();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) => oldDelegate.kind != kind;
}
