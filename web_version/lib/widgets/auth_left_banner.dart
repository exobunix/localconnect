import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthLeftBanner extends StatelessWidget {
  const AuthLeftBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF020916),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          bottomLeft: Radius.circular(24.0),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _AuthBannerPainter(),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LocalConnect',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect with local\nservice providers',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()..color = const Color(0xFF020916);
    canvas.drawRect(rect, bgPaint);

    // 1. Draw Mandala Background
    final center = Offset(size.width / 2, size.height * 0.35);
    final mandalaPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (double r = 40; r <= 180; r += 30) {
      canvas.drawCircle(center, r, mandalaPaint);
      
      // Draw rotated petals/spokes
      final path = Path();
      const int numPetals = 12;
      for (int i = 0; i < numPetals; i++) {
        final angle = (i * 2 * pi) / numPetals;
        final x1 = center.dx + r * cos(angle);
        final y1 = center.dy + r * sin(angle);
        
        final petalAngle = angle + pi / numPetals;
        final x2 = center.dx + (r + 15) * cos(petalAngle);
        final y2 = center.dy + (r + 15) * sin(petalAngle);
        
        final x3 = center.dx + r * cos(angle + (2 * pi / numPetals));
        final y3 = center.dy + r * sin(angle + (2 * pi / numPetals));

        path.moveTo(x1, y1);
        path.quadraticBezierTo(x2, y2, x3, y3);
      }
      canvas.drawPath(path, mandalaPaint);
    }

    // 2. Draw Teardrop Location Pin
    final pinPath = Path();
    final pinWidth = size.width * 0.55;
    final pinHeight = pinWidth * 1.35;
    final pinCenter = Offset(center.dx, center.dy + 10);

    // Teardrop shape starting from bottom tip
    pinPath.moveTo(pinCenter.dx, pinCenter.dy + pinHeight / 2);
    pinPath.cubicTo(
      pinCenter.dx - pinWidth / 2, pinCenter.dy + pinHeight / 6,
      pinCenter.dx - pinWidth / 2, pinCenter.dy - pinHeight / 3,
      pinCenter.dx, pinCenter.dy - pinHeight / 2,
    );
    pinPath.cubicTo(
      pinCenter.dx + pinWidth / 2, pinCenter.dy - pinHeight / 3,
      pinCenter.dx + pinWidth / 2, pinCenter.dy + pinHeight / 6,
      pinCenter.dx, pinCenter.dy + pinHeight / 2,
    );
    pinPath.close();

    final pinPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF9E00), Color(0xFFE52E71), Color(0xFF8A2387)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(
          center: pinCenter, width: pinWidth, height: pinHeight));
    
    // Draw shadow
    canvas.drawPath(
      pinPath,
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(pinPath, pinPaint);

    // 3. Draw circular cutout inside pin
    final cutoutRadius = pinWidth * 0.35;
    final cutoutPaint = Paint()..color = const Color(0xFF020916);
    canvas.drawCircle(pinCenter, cutoutRadius, cutoutPaint);

    // 4. Draw service icons inside cutout
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw a small wrench/hammer schematic
    final iconCenter = pinCenter;
    canvas.drawCircle(iconCenter, 6, Paint()..color = Colors.white.withOpacity(0.1));
    canvas.drawLine(Offset(iconCenter.dx - 12, iconCenter.dy - 12), Offset(iconCenter.dx + 12, iconCenter.dy + 12), iconPaint);
    canvas.drawLine(Offset(iconCenter.dx + 12, iconCenter.dy - 12), Offset(iconCenter.dx - 12, iconCenter.dy + 12), iconPaint);
    canvas.drawCircle(Offset(iconCenter.dx - 12, iconCenter.dy - 12), 4, iconPaint);
    canvas.drawCircle(Offset(iconCenter.dx + 12, iconCenter.dy + 12), 4, iconPaint);
    canvas.drawCircle(Offset(iconCenter.dx + 12, iconCenter.dy - 12), 4, iconPaint);
    canvas.drawCircle(Offset(iconCenter.dx - 12, iconCenter.dy + 12), 4, iconPaint);

    // 5. Draw city silhouette / roadmap at bottom
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final roadPath = Path()
      ..moveTo(20, size.height - 180)
      ..quadraticBezierTo(size.width * 0.3, size.height - 230, size.width * 0.6, size.height - 150)
      ..quadraticBezierTo(size.width * 0.8, size.height - 100, size.width - 20, size.height - 170);
    canvas.drawPath(roadPath, roadPaint);

    // Small markers on the roadmap
    final markerPaint = Paint()
      ..color = const Color(0xFFFF9E00)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.3, size.height - 205), 4, markerPaint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height - 150), 4, markerPaint..color = const Color(0xFFE52E71));
    canvas.drawCircle(Offset(size.width * 0.8, size.height - 115), 4, markerPaint..color = const Color(0xFF8A2387));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
