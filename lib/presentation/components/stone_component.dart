import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class StoneComponent extends PositionComponent {
  late final Paint _basePaint;
  late final Paint _highlightPaint;
  late final Paint _shadowPaint;

  StoneComponent({
    required Vector2 position,
    required double radius,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        ) {
    // 1. The main shiny gem body
    _basePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.brown.shade200, 
          Colors.brown.shade600, 
          Colors.black87
        ],
        stops: const [0.0, 0.6, 1.0],
        center: const Alignment(-0.3, -0.3), // Simulates light coming from top-left
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    // 2. The glassy light reflection
    _highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    // 3. The soft drop shadow underneath
    _shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
  }

  @override
  Future<void> onLoad() async {
    scale = Vector2.zero();
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.3, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final r = size.x / 2;

    // Draw the shadow slightly offset to the bottom right
    canvas.drawCircle(center + const Offset(2, 4), r * 0.9, _shadowPaint);
    
    // Draw the main stone
    canvas.drawCircle(center, r, _basePaint);

    // Draw the curved glossy reflection on the top left
    final highlightPath = Path()
      ..addOval(Rect.fromLTWH(size.x * 0.15, size.y * 0.15, size.x * 0.4, size.y * 0.3));
    canvas.drawPath(highlightPath, _highlightPaint);
  }
}