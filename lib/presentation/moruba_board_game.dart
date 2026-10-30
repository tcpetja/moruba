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
  
  bool _isBoardReady = false; 
  
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
    
    // INITIAL "CRAMPED" LAYOUT (While banks are open)
    final initialStoreWidth = isSmall ? size.x * 0.12 : size.x * 0.14;
    final initialBoardWidth = size.x - (initialStoreWidth * 2) - 20;      
    final initialPitSize = min((initialBoardWidth / n) * 0.85, (size.y * 0.8) / 4 * 0.85);
    final initialSpacing = initialBoardWidth / n;

    final p2BackY = size.y * 0.20;
    final p2FrontY = size.y * 0.40;
    final p1FrontY = size.y * 0.60;
    final p1BackY = size.y * 0.80;

    final boardSurface = RectangleComponent(
      size: Vector2(initialBoardWidth + 30, size.y * 0.78),
      position: Vector2(initialStoreWidth - 15, size.y * 0.11),
      paint: Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0),
    );
    add(boardSurface);

    _addBank(n * 4 + 1, Player.player2, Vector2(10, size.y * 0.15), Vector2(initialStoreWidth, size.y * 0.7), n);
    _addBank(n * 4, Player.player1, Vector2(size.x - initialStoreWidth - 10, size.y * 0.15), Vector2(initialStoreWidth, size.y * 0.7), n);

    List<PitComponent> standardPits = [];

    for (int col = 0; col < n; col++) {
      double startX = initialStoreWidth + 10 + (col * initialSpacing) + (initialSpacing / 2) - (initialPitSize / 2);
      
      standardPits.add(_addStandardPit((n * 2) + col, Player.player2, startX, p2BackY, initialPitSize, n));
      standardPits.add(_addStandardPit((n * 3) + col, Player.player2, startX, p2FrontY, initialPitSize, n));
      standardPits.add(_addStandardPit(n + col, Player.player1, startX, p1FrontY, initialPitSize, n));
      standardPits.add(_addStandardPit(col, Player.player1, startX, p1BackY, initialPitSize, n));
    }

    // THE FIX: Animate standard pits outward when the banks collapse
    add(TimerComponent(
      period: 2.0,
      removeOnFinish: true,
      onTick: () {
        p1Bank.collapseBank();
        p2Bank.collapseBank();
        
        // FINAL "SPACIOUS" LAYOUT (After banks collapse to 20px)
        final finalBoardWidth = size.x - 90.0; // Account for the 20px banks + padding
        final finalSpacing = finalBoardWidth / n;
        final finalPitSize = min((finalBoardWidth / n) * 0.85, (size.y * 0.8) / 4 * 0.85);

        // Stretch the background mat
        boardSurface.add(SizeEffect.to(Vector2(size.x - 60.0, size.y * 0.78), EffectController(duration: 0.5, curve: Curves.easeInOutCubic)));
        boardSurface.add(MoveToEffect(Vector2(30.0, size.y * 0.11), EffectController(duration: 0.5, curve: Curves.easeInOutCubic)));

        // Stretch and reposition all standard pits
        for (var pit in standardPits) {
          int col = pit.pitIndex % n;
          double finalX = 45.0 + (col * finalSpacing) + (finalSpacing / 2) - (finalPitSize / 2);
          Vector2 finalPos = Vector2(finalX, pit.position.y);
          Vector2 finalSize = Vector2(finalPitSize, finalPitSize);

          pit.transitionTo(finalPos, finalSize); // Trigger smooth animation
          
          // Update internal tracking so flying stones know where the new pits are
          _pitCenters[pit.pitIndex] = finalPos + (finalSize / 2);
        }

        _isBoardReady = true; 
      },
    ));

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

  void _handlePitTap(int index) {
    if (!_isBoardReady) return;
    onPitTapped(index);
  }

  void _addBank(int index, Player player, Vector2 pos, Vector2 sizeVec, int pitsPerRow) {
    _pitCenters[index] = pos + (sizeVec / 2);
    final bank = PitComponent(pitIndex: index, player: player, isBank: true, pitsPerRow: pitsPerRow, onTapped: _handlePitTap, size: sizeVec, position: pos);
    if (player == Player.player1) p1Bank = bank;
    if (player == Player.player2) p2Bank = bank;
    add(bank);
  }

  PitComponent _addStandardPit(int index, Player player, double x, double y, double s, int pitsPerRow) {
    Vector2 pos = Vector2(x, y);
    Vector2 sizeVec = Vector2(s, s);
    _pitCenters[index] = pos + (sizeVec / 2);
    final pit = PitComponent(pitIndex: index, player: player, isBank: false, pitsPerRow: pitsPerRow, onTapped: _handlePitTap, size: sizeVec, position: pos);
    add(pit);
    return pit; // Return so we can store it for the animation
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

    int currentP1Score = state.board.getBank(Player.player1).stones;
    if (currentP1Score > _lastP1Score) {
      if (_isBoardReady) p1Bank.expandTemporarily();
      _lastP1Score = currentP1Score;
    }

    int currentP2Score = state.board.getBank(Player.player2).stones;
    if (currentP2Score > _lastP2Score) {
      if (_isBoardReady) p2Bank.expandTemporarily();
      _lastP2Score = currentP2Score;
    }

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