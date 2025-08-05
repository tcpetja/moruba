// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'dart:math' as math;

void main() {
  runApp(const ProviderScope(child: MorubaApp()));
}

class MorubaApp extends StatelessWidget {
  const MorubaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moruba',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.amber,
          accentColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

// Game state and logic
enum Player { player1, player2 }

@immutable
class GameState {
  final List<int> board;
  final Player currentPlayer;
  final String? winner;
  final int? activePit;
  final Map<int, int> movingStones;

  const GameState({
    required this.board,
    this.currentPlayer = Player.player1,
    this.winner,
    this.activePit,
    this.movingStones = const {},
  });

  GameState copyWith({
    List<int>? board,
    Player? currentPlayer,
    String? winner,
    int? activePit,
    Map<int, int>? movingStones,
  }) {
    return GameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winner: winner ?? this.winner,
      activePit: activePit ?? this.activePit,
      movingStones: movingStones ?? this.movingStones,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier()
    : super(
        GameState(
          board:
              List.filled(6, 4) // Player 1 pits (0-5)
              +
              [0] // Player 1 store (6)
              +
              List.filled(6, 4) // Player 2 pits (7-12)
              +
              [0], // Player 2 store (13)
        ),
      );

  bool get isGameOver => state.winner != null;

  void makeMove(int pitIndex) {
    if (isGameOver || state.movingStones.isNotEmpty || !_isValidMove(pitIndex))
      return;

    final board = List<int>.from(state.board);
    int stones = board[pitIndex];
    board[pitIndex] = 0;

    state = state.copyWith(
      activePit: pitIndex,
      movingStones: {pitIndex: stones},
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      _distributeStones(board, pitIndex, stones);
    });
  }

  void _distributeStones(List<int> board, int startIndex, int stones) {
    int currentIndex = startIndex;
    int lastIndex = startIndex;

    while (stones > 0) {
      // Move to next pit in counter-clockwise direction
      currentIndex = (currentIndex + 1) % 14;

      // Skip opponent's store
      if (state.currentPlayer == Player.player1 && currentIndex == 13) continue;
      if (state.currentPlayer == Player.player2 && currentIndex == 6) continue;

      board[currentIndex]++;
      stones--;
      lastIndex = currentIndex;
    }

    final extraTurn = _checkExtraTurn(lastIndex);
    if (!extraTurn) {
      _checkCapture(board, lastIndex);
    }

    final winner = _checkGameEnd(board);

    state = state.copyWith(
      board: board,
      currentPlayer: extraTurn ? state.currentPlayer : _opponent(),
      activePit: null,
      movingStones: {},
      winner: winner,
    );
  }

  bool _checkExtraTurn(int lastIndex) {
    return (state.currentPlayer == Player.player1 && lastIndex == 6) ||
        (state.currentPlayer == Player.player2 && lastIndex == 13);
  }

  void _checkCapture(List<int> board, int lastIndex) {
    final currentPlayer = state.currentPlayer;
    final isPlayer1Pit =
        currentPlayer == Player.player1 && lastIndex >= 0 && lastIndex <= 5;
    final isPlayer2Pit =
        currentPlayer == Player.player2 && lastIndex >= 7 && lastIndex <= 12;

    if ((isPlayer1Pit || isPlayer2Pit) && board[lastIndex] == 1) {
      final oppositeIndex = 12 - lastIndex;
      final captureAmount = board[oppositeIndex] + 1;

      if (captureAmount > 1) {
        board[oppositeIndex] = 0;
        board[lastIndex] = 0;

        if (currentPlayer == Player.player1) {
          board[6] += captureAmount;
        } else {
          board[13] += captureAmount;
        }
      }
    }
  }

  String? _checkGameEnd(List<int> board) {
    final player1Pits = board.sublist(0, 6).sum;
    final player2Pits = board.sublist(7, 13).sum;

    if (player1Pits == 0 || player2Pits == 0) {
      board[6] += player1Pits;
      board[13] += player2Pits;

      for (int i = 0; i < 14; i++) {
        if ((i >= 0 && i <= 5) || (i >= 7 && i <= 12)) {
          board[i] = 0;
        }
      }

      if (board[6] > board[13]) return "Player 1 Wins!";
      if (board[6] < board[13]) return "Player 2 Wins!";
      return "It's a Draw!";
    }
    return null;
  }

  Player _opponent() {
    return state.currentPlayer == Player.player1
        ? Player.player2
        : Player.player1;
  }

  bool _isValidMove(int pitIndex) {
    final isPlayer1 = state.currentPlayer == Player.player1;
    final validPlayer1Pits = pitIndex >= 0 && pitIndex <= 5;
    final validPlayer2Pits = pitIndex >= 7 && pitIndex <= 12;

    return state.board[pitIndex] > 0 &&
        ((isPlayer1 && validPlayer1Pits) || (!isPlayer1 && validPlayer2Pits));
  }

  void resetGame() {
    state = GameState(board: List.filled(6, 4) + [0] + List.filled(6, 4) + [0]);
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(),
);

// UI Components
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moruba'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          _PlayerInfo(
            player: Player.player2,
            isActive: state.currentPlayer == Player.player2,
            score: state.board[13],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: _BoardLayout(boardState: state),
            ),
          ),
          _PlayerInfo(
            player: Player.player1,
            isActive: state.currentPlayer == Player.player1,
            score: state.board[6],
          ),
          if (state.winner != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                state.winner!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerInfo extends StatelessWidget {
  final Player player;
  final bool isActive;
  final int score;

  const _PlayerInfo({
    required this.player,
    required this.isActive,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: isActive ? Colors.amber.shade100 : Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            player == Player.player1 ? 'Player 1' : 'Player 2',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(width: 16),
          Text('Score: $score', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _BoardLayout extends ConsumerWidget {
  final GameState boardState;

  const _BoardLayout({required this.boardState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final storeWidth = constraints.maxWidth * 0.15;
        final pitSize = constraints.maxWidth * 0.1;

        return Row(
          children: [
            // Player 2 store (left side)
            _StoreWidget(
              stones: boardState.board[13],
              width: storeWidth,
              height: constraints.maxHeight,
              player: Player.player2,
            ),
            Expanded(
              child: Column(
                children: [
                  // Player 2 pits (top row - right to left: 12,11,10,9,8,7)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        final pitIndex = 12 - index; // 12,11,10,9,8,7
                        return _PitWidget(
                          stones: boardState.board[pitIndex],
                          pitIndex: pitIndex,
                          size: pitSize,
                          player: Player.player2,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Player 1 pits (bottom row - left to right: 0,1,2,3,4,5)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return _PitWidget(
                          stones: boardState.board[index],
                          pitIndex: index,
                          size: pitSize,
                          player: Player.player1,
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            // Player 1 store (right side)
            _StoreWidget(
              stones: boardState.board[6],
              width: storeWidth,
              height: constraints.maxHeight,
              player: Player.player1,
            ),
          ],
        );
      },
    );
  }
}

class _PitWidget extends ConsumerWidget {
  final int stones;
  final int pitIndex;
  final double size;
  final Player player;

  const _PitWidget({
    required this.stones,
    required this.pitIndex,
    required this.size,
    required this.player,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final state = ref.watch(gameProvider);
    final isActive = state.activePit == pitIndex;

    return GestureDetector(
      onTap: () => notifier.makeMove(pitIndex),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: player == Player.player1
              ? Colors.amber.shade300
              : Colors.blue.shade300,
          borderRadius: BorderRadius.circular(size / 2),
          border: isActive ? Border.all(color: Colors.red, width: 3) : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$stones',
                style: TextStyle(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (state.movingStones.containsKey(pitIndex))
              ...List.generate(
                state.movingStones[pitIndex]!,
                (index) =>
                    _MovingStone(index: index, total: stones, size: size),
              ),
          ],
        ),
      ),
    );
  }
}

class _MovingStone extends StatelessWidget {
  final int index;
  final int total;
  final double size;

  const _MovingStone({
    required this.index,
    required this.total,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final angle = 2 * 3.14 * index / total;
    final offset = Offset(
      size / 2 + size / 3 * math.cos(angle),
      size / 2 + size / 3 * math.sin(angle),
    );

    return Positioned(
      left: offset.dx - size / 10,
      top: offset.dy - size / 10,
      child: Container(
        width: size / 5,
        height: size / 5,
        decoration: const BoxDecoration(
          color: Colors.brown,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _StoreWidget extends StatelessWidget {
  final int stones;
  final double width;
  final double height;
  final Player player;

  const _StoreWidget({
    required this.stones,
    required this.width,
    required this.height,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height * 0.7,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: player == Player.player1 ? Colors.amber : Colors.blue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$stones',
          style: TextStyle(
            fontSize: width * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
