import 'package:flutter/material.dart';
import 'dart:math';

class DownloadProgressIcon extends StatelessWidget {

  final double progress;
  final double size;
  final Color primaryColor;
  final Color secondaryColor;

  const DownloadProgressIcon({
    super.key,
    required this.progress,
    required this.size,
    this.primaryColor = Colors.white,
    this.secondaryColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.arrow_circle_down_sharp,
          size: size,
          color: progress == 1
            ? primaryColor
            : secondaryColor,
        ),
        CustomPaint(
          painter: _ProgressPainter(
            progress,
            primaryColor,
          ),
          size: Size(size, size),
        ),
      ],
    );
  }
}

class _ProgressPainter extends CustomPainter {

  final double progress;
  final Color color;

  _ProgressPainter(
    this.progress,
    this.color,
  );

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = canvasSize.width / 12;

    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = canvasSize.width / 2.68;

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
