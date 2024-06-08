import 'package:flutter/material.dart';

class MusicLogoAnimation extends StatefulWidget {
  const MusicLogoAnimation({super.key});

  @override
  _MusicLogoAnimationState createState() => _MusicLogoAnimationState();
}

class _MusicLogoAnimationState extends State<MusicLogoAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple,
                    Colors.blue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomPaint(
                painter: _MusicLogoPainter(
                  _controller.value,
                ),
                size: Size.infinite,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MusicLogoPainter extends CustomPainter {
  final double _animationValue;

  _MusicLogoPainter(this._animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);

    final path = Path();

    // Draw the first part of the music note
    path.moveTo(center.dx - 10, center.dy);
    path.quadraticBezierTo(
      center.dx - 5,
      center.dy - 20,
      center.dx,
      center.dy - 10,
    );
    path.quadraticBezierTo(
      center.dx + 5,
      center.dy - 20,
      center.dx + 10,
      center.dy,
    );
    path.quadraticBezierTo(
      center.dx + 5,
      center.dy + 20,
      center.dx,
      center.dy + 10,
    );
    path.quadraticBezierTo(
      center.dx - 5,
      center.dy + 20,
      center.dx - 10,
      center.dy,
    );

    // Draw the second part of the music note
    path.moveTo(center.dx - 10, center.dy);
    path.quadraticBezierTo(
      center.dx - 5,
      center.dy + 20,
      center.dx,
      center.dy + 10,
    );
    path.quadraticBezierTo(
      center.dx + 5,
      center.dy + 20,
      center.dx + 10,
      center.dy,
    );

    // Animate the music note
    path.moveTo(
        center.dx + 10 * _animationValue, center.dy - 10 * _animationValue);
    path.quadraticBezierTo(
      center.dx + 5 * _animationValue,
      center.dy - 20 * _animationValue,
      center.dx,
      center.dy - 10 * _animationValue,
    );

    canvas.drawPath(path, paint);

    // Add the text "Aurora Music"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Aurora Music',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + 30,
      ),
    );
  }

  @override
  bool shouldRepaint(_MusicLogoPainter oldDelegate) {
    return oldDelegate._animationValue != _animationValue;
  }
}