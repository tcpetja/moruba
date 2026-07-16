import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../domain/player.dart';
import 'stone_component.dart';

class PitComponent extends PositionComponent with TapCallbacks {
  final int pitIndex;
  final Player player;
  final bool isBank;
  final Function(int) onTapped;
  
  bool isValidMove = false;
  bool isCaptureMode = false;
  int _currentStones = 0;

  late final Paint _basePaint;
  late final Paint _innerShadowPaint;
  late final Paint _borderPaint;
  late final TextPaint _textPaint;

  Vector2? expandedSize;
  Vector2? expandedPos;
  Vector2? collapsedSize;
  Vector2? collapsedPos;
  bool isExpanded = true;
  TimerComponent? _collapseTimer;

  PitComponent({
    required this.pitIndex,
    required this.player,
    required this.isBank,
    required this.onTapped,
    required Vector2 size,
    required Vector2 position,
  }) : super(size: size, position: position) {
    
    _basePaint = Paint()
      ..color = player == Player.player1 
          ? Colors.amber.shade200 
          : Colors.blue.shade200;

    _innerShadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
        stops: const [0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
          
    _borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    _textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        shadows: [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1))]
      ),
    );

    if (isBank) {
      expandedSize = size.clone();
      expandedPos = position.clone();
      
      final skinnyWidth = 20.0; 
      
      collapsedSize = Vector2(skinnyWidth, size.y);
      if (player == Player.player2) {
        collapsedPos = position.clone(); 
      } else {
        collapsedPos = Vector2(position.x + (size.x - skinnyWidth), position.y); 
      }
    }
  }
  
  void toggleBank() {
    if (!isBank) return;
    if (isExpanded) collapseBank();
    else expandBank();
  }

  void collapseBank() {
    if (!isBank || !isExpanded) return;
    isExpanded = false;
    
    removeAll(children.whereType<SizeEffect>());
    removeAll(children.whereType<MoveToEffect>());
    _collapseTimer?.removeFromParent();
    
    add(SizeEffect.to(collapsedSize!, EffectController(duration: 0.5, curve: Curves.easeInOutCubic)));
    add(MoveToEffect(collapsedPos!, EffectController(duration: 0.5, curve: Curves.easeInOutCubic)));
  }

  void expandBank() {
    if (!isBank || isExpanded) return;
    isExpanded = true;
    
    removeAll(children.whereType<SizeEffect>());
    removeAll(children.whereType<MoveToEffect>());
    _collapseTimer?.removeFromParent();
    
    add(SizeEffect.to(expandedSize!, EffectController(duration: 0.5, curve: Curves.easeInOutCubic)));
    add(MoveToEffect(expandedPos!, EffectController(duration: 0.5, curve: Curves.easeInOutCubic)));
  }

  void expandTemporarily() {
    if (!isBank) return;
    
    if (!isExpanded) expandBank();
    else _collapseTimer?.removeFromParent();
    
    _collapseTimer = TimerComponent(
      period: 2.5, 
      removeOnFinish: true,
      onTick: () => collapseBank(),
    );
    add(_collapseTimer!);
  }

  void syncStones(int targetCount) {
    if (_currentStones == targetCount) return;

    if (isBank) {
      if (targetCount > _currentStones) {
        for (int i = _currentStones; i < targetCount; i++) {
          _spawnStone(i, targetCount);
        }
      } else {
        removeAll(children.whereType<StoneComponent>());
        for (int i = 0; i < targetCount; i++) {
          _spawnStone(i, targetCount);
        }
      }
    } else {
      removeAll(children.whereType<StoneComponent>());
      for (int i = 0; i < targetCount; i++) {
        _spawnStone(i, targetCount);
      }
    }
    _currentStones = targetCount;
  }

  void _spawnStone(int index, int total) {
    final actualWidth = expandedSize?.x ?? size.x;
    final actualHeight = expandedSize?.y ?? size.y;
    
    final stoneRadius = actualWidth * 0.16; 
    final center = Vector2(actualWidth / 2, actualHeight / 2);
    double dx = center.x;
    double dy = center.y;

    if (total > 1) {
      if (isBank) {
        // Banks remain an organic pile to fit into their rectangular shape
        Random seededRandom = Random(index); 
        double maxDx = actualWidth - (stoneRadius * 2) - 10;
        double maxDy = actualHeight - (stoneRadius * 2) - 10;
        dx = stoneRadius + 5 + seededRandom.nextDouble() * maxDx;
        dy = stoneRadius + 5 + seededRandom.nextDouble() * maxDy;
      } else {
        // THE FIX: Strict Geometric Subitizing Patterns for Standard Pits
        final R = (actualWidth / 2) - stoneRadius - 4; 
        double offsetX = 0;
        double offsetY = 0;

        if (total == 2) {
          double r = R * 0.6;
          offsetX = index == 0 ? -r : r;
        } 
        else if (total == 3) {
          double r = R * 0.6;
          if (index == 0) { offsetX = 0; offsetY = -r; } // Top center
          else if (index == 1) { offsetX = -r; offsetY = r * 0.8; } // Bottom left
          else { offsetX = r; offsetY = r * 0.8; } // Bottom right
        } 
        else if (total == 4) {
          double r = R * 0.55;
          offsetX = (index % 2 == 0) ? -r : r;
          offsetY = (index < 2) ? -r : r;
        } 
        else if (total == 5) {
          double r = R * 0.6;
          if (index == 4) { offsetX = 0; offsetY = 0; } // Center
          else {
            offsetX = (index % 2 == 0) ? -r : r;
            offsetY = (index < 2) ? -r : r;
          }
        } 
        else if (total == 6) {
          double rx = R * 0.55;
          double ry = R * 0.7;
          offsetX = (index % 2 == 0) ? -rx : rx;
          if (index < 2) offsetY = -ry;
          else if (index < 4) offsetY = 0;
          else offsetY = ry;
        } 
        else if (total == 7) {
          if (index == 6) { offsetX = 0; offsetY = 0; } // Center
          else {
            double r = R * 0.75;
            double angle = index * (2 * pi / 6);
            offsetX = r * cos(angle);
            offsetY = r * sin(angle);
          }
        } 
        else if (total == 8) {
          double r = R * 0.8;
          double angle = index * (2 * pi / 8);
          offsetX = r * cos(angle);
          offsetY = r * sin(angle);
        } 
        else if (total == 9) {
          double r = R * 0.65;
          int row = index ~/ 3;
          int col = index % 3;
          offsetX = (col - 1) * r;
          offsetY = (row - 1) * r;
        } 
        else {
          // Fallback for 10+: Sunflower Spiral
          final goldenAngle = 137.5 * (pi / 180.0);
          final maxRadius = (actualWidth / 2) - stoneRadius - 4;
          final radiusStep = maxRadius / sqrt(total - 1 > 0 ? total - 1 : 1);
          final r = radiusStep * sqrt(index);
          final theta = index * goldenAngle;
          offsetX = r * cos(theta);
          offsetY = r * sin(theta);
        }

        dx = center.x + offsetX;
        dy = center.y + offsetY;
      }
    }

    add(StoneComponent(position: Vector2(dx, dy), radius: stoneRadius));
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final center = Offset(size.x / 2, size.y / 2);

    if (isBank) {
      final dynamicRadius = Radius.circular(min(20.0, size.x / 2));
      canvas.clipRRect(RRect.fromRectAndRadius(rect, dynamicRadius));
      final rRect = RRect.fromRectAndRadius(rect, dynamicRadius);
      
      canvas.drawRRect(rRect, _basePaint);
      canvas.drawRRect(rRect, _innerShadowPaint); 
    } else {
      canvas.drawCircle(center, size.x / 2, _basePaint);
      canvas.drawCircle(center, size.x / 2, _innerShadowPaint); 
    }

    if (isCaptureMode) {
      _borderPaint.color = Colors.greenAccent.shade400;
      if (isBank) {
        final dynamicRadius = Radius.circular(min(20.0, size.x / 2));
        canvas.drawRRect(RRect.fromRectAndRadius(rect, dynamicRadius), _borderPaint);
      } else {
        canvas.drawCircle(center, size.x / 2, _borderPaint);
      }
    } else if (isValidMove) {
      _borderPaint.color = Colors.white70;
      canvas.drawCircle(center, size.x / 2, _borderPaint);
    }

    if (_currentStones > 0) {
      final badgePaint = Paint()
        ..color = Colors.black.withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 28, height: 28),
          const Radius.circular(14)
        ),
        badgePaint
      );

      _textPaint.render(
        canvas,
        '$_currentStones',
        Vector2(center.dx, center.dy + 1), 
        anchor: Anchor.center,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isBank) {
      toggleBank();
      return; 
    }
    onTapped(pitIndex);
  }
}