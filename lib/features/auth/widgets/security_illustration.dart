import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/theme/app_colors.dart';

/// Animated shield/security illustration for the login page.
/// Draws a professional shield with a lock icon and animated pulse effect.
class SecurityIllustration extends StatefulWidget {
  final double size;

  const SecurityIllustration({super.key, this.size = 280});

  @override
  State<SecurityIllustration> createState() => _SecurityIllustrationState();
}

class _SecurityIllustrationState extends State<SecurityIllustration>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _rotateAnimation]),
        builder: (context, child) {
          return CustomPaint(
            painter: _SecurityPainter(
              pulseValue: _pulseAnimation.value,
              rotateValue: _rotateAnimation.value,
            ),
            child: Center(
              child: Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: widget.size * 0.38,
                  height: widget.size * 0.38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2B5F8A), Color(0xFF1A3A5C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAccent.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: widget.size * 0.16,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SecurityPainter extends CustomPainter {
  final double pulseValue;
  final double rotateValue;

  _SecurityPainter({required this.pulseValue, required this.rotateValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Outer rotating dashed circle
    _drawRotatingCircle(canvas, center, maxRadius * 0.92, rotateValue);

    // Pulsing rings
    _drawPulsingRing(canvas, center, maxRadius * 0.78 * pulseValue, 0.08);
    _drawPulsingRing(canvas, center, maxRadius * 0.65 * pulseValue, 0.05);

    // Floating security dots
    _drawFloatingDots(canvas, center, maxRadius * 0.85, rotateValue);

    // Corner feature icons positions
    _drawFeatureIndicators(canvas, center, maxRadius);
  }

  void _drawRotatingCircle(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
  ) {
    final paint = Paint()
      ..color = AppColors.primaryAccent.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const int segments = 36;
    const double gapAngle = math.pi / 36;

    for (int i = 0; i < segments; i++) {
      final startAngle = (i * 2 * math.pi / segments) + rotation;
      final sweepAngle = (2 * math.pi / segments) - gapAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  void _drawPulsingRing(
    Canvas canvas,
    Offset center,
    double radius,
    double opacity,
  ) {
    final paint = Paint()
      ..color = AppColors.primaryAccent.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, paint);
  }

  void _drawFloatingDots(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;

    const int dotCount = 8;
    for (int i = 0; i < dotCount; i++) {
      final angle = (i * 2 * math.pi / dotCount) + rotation * 0.5;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final dotOpacity = 0.3 + 0.4 * ((math.sin(angle + rotation) + 1) / 2);
      paint.color = AppColors.secondaryLight.withValues(alpha: dotOpacity);

      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  void _drawFeatureIndicators(Canvas canvas, Offset center, double maxRadius) {
    final positions = [
      Offset(center.dx - maxRadius * 0.65, center.dy - maxRadius * 0.65),
      Offset(center.dx + maxRadius * 0.65, center.dy - maxRadius * 0.65),
      Offset(center.dx - maxRadius * 0.65, center.dy + maxRadius * 0.65),
      Offset(center.dx + maxRadius * 0.65, center.dy + maxRadius * 0.65),
    ];

    for (final pos in positions) {
      final bgPaint = Paint()
        ..color = AppColors.primaryLight.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, 6, bgPaint);

      final dotPaint = Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SecurityPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.rotateValue != rotateValue;
  }
}

/// Feature badge widget shown around the illustration
class FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const FeatureBadge({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
