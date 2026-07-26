import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/effects.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

import '../domain/player.dart';
import '../domain/pit.dart';
import '../state/game_state.dart';
import '../engine/moruba_engine.dart';
import 'components/pit_component.dart';
import 'components/stone_component.dart';

class MorubaBoardGame extends FlameGame {
  GameState state;
  final Function(int) onPitTapped;

  final Map<int, Vector2> _pitCenters = {};
  int? _lastActivePit;
  double _time = 0;
  
  late PitComponent p1Bank;
  late PitComponent p2Bank;
  bool _hasStarted = false;
  int _lastP1Score = 0;
  int _lastP2Score = 0;

  late CircleComponent handBackground;
  late TextComponent handIndicator;

  MorubaBoardGame({
    required this.state,
    required this.onPitTapped,
  });

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    int n = state.board.pitsPerRow;
    final isSmall = size.y < 500;
    
    final storeWidth = isSmall ? size.x * 0.12 : size.x * 0.14;
    final boardWidth = size.x - (storeWidth * 2) - 20;      
    
    final pitSize = min((boardWidth / n) * 0.85, (size.y * 0.8) / 4 * 0.85);
    final spacing = boardWidth / n;

    final p2BackY = size.y * 0.20;
    final p2FrontY = size.y * 0.40;
    final p1FrontY = size.y * 0.60;
    final p1BackY = size.y * 0.80;

    final boardSurface = RectangleComponent(
      size: Vector2(boardWidth + 30, size.y * 0.78),
      position: Vector2(storeWidth - 15, size.y * 0.11),
      paint: Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0),
    );
    add(boardSurface);

    _addBank(n * 4 + 1, Player.player2, Vector2(10, size.y * 0.15), Vector2(storeWidth, size.y * 0.7));
    _addBank(n * 4, Player.player1, Vector2(size.x - storeWidth - 10, size.y * 0.15), Vector2(storeWidth, size.y * 0.7));

    for (int col = 0; col < n; col++) {
      double startX = storeWidth + 10 + (col * spacing) + (spacing / 2) - (pitSize / 2);
      
      _addStandardPit((n * 2) + col, Player.player2, startX, p2BackY, pitSize);
      _addStandardPit((n * 3) + col, Player.player2, startX, p2FrontY, pitSize);
      _addStandardPit(n + col, Player.player1, startX, p1FrontY, pitSize);
      _addStandardPit(col, Player.player1, startX, p1BackY, pitSize);
    }

    handBackground = CircleComponent(
      radius: 22,
      paint: Paint()
        ..shader = RadialGradient(
          colors: [Colors.amberAccent.shade100, Colors.orange.shade700],
          stops: const [0.3, 1.0],
        ).createShader(const Rect.fromLTWH(0, 0, 44, 44)),
      anchor: Anchor.center,
      priority: 200,
    );

    final halo = CircleComponent(
      radius: 26,
      paint: Paint()..color = Colors.amber.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
      anchor: Anchor.center,
      position: Vector2(22, 22),
    );
    
    handIndicator = TextComponent(
      text: '',
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
      anchor: Anchor.center,
      position: Vector2(22, 22),
    );
    
    handBackground.add(halo);
    handBackground.add(handIndicator);
    handBackground.scale = Vector2.zero();
    add(handBackground);
  }

  void _addBank(int index, Player player, Vector2 pos, Vector2 sizeVec) {
    _pitCenters[index] = pos + (sizeVec / 2);
    final bank = PitComponent(pitIndex: index, player: player, isBank: true, onTapped: onPitTapped, size: sizeVec, position: pos);
    if (player == Player.player1) p1Bank = bank;
    if (player == Player.player2) p2Bank = bank;
    add(bank);
  }

  void _addStandardPit(int index, Player player, double x, double y, double s) {
    Vector2 pos = Vector2(x, y);
    Vector2 sizeVec = Vector2(s, s);
    _pitCenters[index] = pos + (sizeVec / 2);
    add(PitComponent(pitIndex: index, player: player, isBank: false, onTapped: onPitTapped, size: sizeVec, position: pos));
  }

  Vector2 _getDynamicCenter(int index) {
    for (var component in children) {
      if (component is PitComponent && component.pitIndex == index) {
        return component.position + (component.size / 2);
      }
    }
    return _pitCenters[index] ?? Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
      
    if (!_hasStarted && state.movingStones.isNotEmpty) {
      _hasStarted = true;
      p1Bank.collapseBank();
      p2Bank.collapseBank();
    }

    int currentP1Score = state.board.getBank(Player.player1).stones;
    if (currentP1Score > _lastP1Score) {
      if (_hasStarted) p1Bank.expandTemporarily();
      _lastP1Score = currentP1Score;
    }

    int currentP2Score = state.board.getBank(Player.player2).stones;
    if (currentP2Score > _lastP2Score) {
      if (_hasStarted) p2Bank.expandTemporarily();
      _lastP2Score = currentP2Score;
    }

    // Handles the special jump stone animation intercept
    if (state.jumpMove != null && state.jumpMove!.isNotEmpty) {
      int fromPit = state.jumpMove!.keys.first;
      int toPit = state.jumpMove!.values.first;
      _spawnFlyingStone(_getDynamicCenter(fromPit), _getDynamicCenter(toPit));
    } else {
      if (state.activePit != _lastActivePit) {
        _lastActivePit = state.activePit;
        if (state.activePit != null && state.movingStones.isNotEmpty) {
          int fromPit = state.activePit!;
          int toPit = MorubaEngine.getNextPit(fromPit, state.currentPlayer, state.board.pitsPerRow);
          _spawnFlyingStone(_getDynamicCenter(fromPit), _getDynamicCenter(toPit));
        }
      }
    }

    for (var component in children) {
      if (component is PitComponent) {
        Pit modelPit = state.board.getPit(component.pitIndex);
        component.syncStones(modelPit.stones);
        
        component.isCaptureMode = state.canCapture;
        component.isSelectedJump = (state.selectedPitForJump == component.pitIndex);
        
        component.isValidMove = MorubaEngine.isValidMove(
          state.board, 
          component.pitIndex, 
          state.currentPlayer,
          isFirstMove: state.isFirstMove,
          selectedPitForJump: state.selectedPitForJump,
        ) && (modelPit.owner == state.currentPlayer || (state.selectedPitForJump != null && component.pitIndex == state.selectedPitForJump));
      }
    }

    if (state.stonesInHand > 0 && state.activePit != null) {
      handBackground.scale = Vector2.all(1.0);
      double bounceOffset = sin(_time * 10) * 6; 
      handBackground.position = _getDynamicCenter(state.activePit!) + Vector2(0, -45 + bounceOffset); 
      handIndicator.text = '${state.stonesInHand}';
    } else {
      handBackground.scale = Vector2.zero(); 
    }
  }

  void _spawnFlyingStone(Vector2 from, Vector2 to) {
    final flyingStone = StoneComponent(position: from, radius: 14.0);
    flyingStone.priority = 100; 

    flyingStone.add(
      SequenceEffect([
        MoveToEffect(to, EffectController(duration: 0.3, curve: Curves.easeInOutSine)),
        RemoveEffect(),
      ]),
    );
    flyingStone.add(
      SequenceEffect([
        ScaleEffect.to(Vector2.all(1.5), EffectController(duration: 0.15, curve: Curves.easeOutCubic)),
        ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.15, curve: Curves.easeInCubic)),
      ]),
    );

    add(flyingStone);
  }
}