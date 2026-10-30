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
  final AIDifficulty aiDifficulty;
  final bool isFirstMove;
  
  final int? selectedPitForJump; 
  final Map<int, int>? jumpMove;

  final int matchId; 
  final Player initialStartingPlayer;

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
    this.boardSize = 12,
    this.aiDifficulty = AIDifficulty.expert, 
    this.isFirstMove = true, 
    this.selectedPitForJump,
    this.jumpMove,
    this.matchId = 0,
    this.initialStartingPlayer = Player.player1,
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
    bool? isFirstMove,
    int? selectedPitForJump,
    bool clearSelectedPit = false,
    Map<int, int>? jumpMove,
    bool clearJumpMove = false,
    int? matchId,
    Player? initialStartingPlayer,
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
      isFirstMove: isFirstMove ?? this.isFirstMove,
      selectedPitForJump: clearSelectedPit ? null : (selectedPitForJump ?? this.selectedPitForJump),
      jumpMove: clearJumpMove ? null : (jumpMove ?? this.jumpMove),
      matchId: matchId ?? this.matchId,
      initialStartingPlayer: initialStartingPlayer ?? this.initialStartingPlayer,
    );
  }
}