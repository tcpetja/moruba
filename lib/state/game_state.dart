import '../domain/board.dart';
import '../domain/player.dart';

enum AIDifficulty { beginner, intermediate, expert, master }

class GameState {
  final Board board;
  final Player currentPlayer;
  final Player? winner;
  
  final int? activePit;
  final Map<int, int> movingStones;
  final int stonesInHand; 
  final bool isPaused;
  final bool canCapture;
  final bool canBank;
  final bool isSinglePlayer;
  final int boardSize; 
  
  // NEW: AI Difficulty Tracker
  final AIDifficulty aiDifficulty;

  const GameState({
    required this.board,
    this.currentPlayer = Player.player1,
    this.winner,
    this.activePit,
    this.movingStones = const {},
    this.stonesInHand = 0,
    this.isPaused = false,
    this.canCapture = false,
    this.canBank = false,
    this.isSinglePlayer = false,
    this.boardSize = 6,
    this.aiDifficulty = AIDifficulty.expert, // Defaults to a standard challenge
  });

  bool get isGameOver => winner != null;

  GameState copyWith({
    Board? board,
    Player? currentPlayer,
    Player? winner,
    int? activePit,
    Map<int, int>? movingStones,
    int? stonesInHand,
    bool? isPaused,
    bool? canCapture,
    bool? canBank,
    bool? isSinglePlayer,
    int? boardSize,
    AIDifficulty? aiDifficulty,
  }) {
    return GameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winner: winner ?? this.winner,
      activePit: activePit ?? this.activePit,
      movingStones: movingStones ?? this.movingStones,
      stonesInHand: stonesInHand ?? this.stonesInHand,
      isPaused: isPaused ?? this.isPaused,
      canCapture: canCapture ?? this.canCapture,
      canBank: canBank ?? this.canBank,
      isSinglePlayer: isSinglePlayer ?? this.isSinglePlayer,
      boardSize: boardSize ?? this.boardSize,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
    );
  }
}