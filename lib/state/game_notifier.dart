import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/board.dart';
import '../domain/player.dart';
import '../domain/pit.dart';
import '../engine/moruba_engine.dart';
import '../engine/ai_engine.dart';
import 'game_state.dart';

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState(board: Board.initial()));

  void setGameMode(bool singlePlayer) {
    state = state.copyWith(isSinglePlayer: singlePlayer);
  }

  void makeMove(int pitIndex) {
    if (state.isGameOver || state.movingStones.isNotEmpty || state.isPaused || state.canCapture) return;
    if (!MorubaEngine.isValidMove(state.board, pitIndex, state.currentPlayer)) return;

    Board currentBoard = state.board.copy();
    Pit selectedPit = currentBoard.getPit(pitIndex);
    
    int stonesToMove = selectedPit.stones;
    selectedPit.stones = 0;

    state = state.copyWith(
      board: currentBoard,
      activePit: pitIndex,
      movingStones: {pitIndex: stonesToMove},
      stonesInHand: stonesToMove, 
      canCapture: false,
    );

    _distributeStones(currentBoard, pitIndex, stonesToMove);
  }

  void _distributeStones(Board board, int startIndex, int stones) async {
    int currentIndex = startIndex;
    int remaining = stones;
    
    state = state.copyWith(movingStones: {});

    while (remaining > 0) {
      if (state.isPaused || state.isGameOver) break;

      await Future.delayed(const Duration(milliseconds: 300));

      currentIndex = MorubaEngine.getNextPit(currentIndex, state.currentPlayer, board.pitsPerRow);
      board.getPit(currentIndex).stones++;
      remaining--;

      state = state.copyWith(
        board: board.copy(),
        activePit: currentIndex,
        movingStones: {currentIndex: 1},
        stonesInHand: remaining,
      );
    }

    Pit landingPit = board.getPit(currentIndex);
    if (landingPit.stones > 1) {
      int newStones = landingPit.stones;
      landingPit.stones = 0;
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      state = state.copyWith(
        board: board.copy(),
        stonesInHand: newStones, 
      );
      _distributeStones(board, currentIndex, newStones);
    } else {
      _finalizeMove(board, currentIndex);
    }
  }

  Future<void> _finalizeMove(Board board, int lastIndex) async {
    bool captured = MorubaEngine.checkAndApplyCapture(board, lastIndex, state.currentPlayer);

    Player opponent = state.currentPlayer.opponent;
    int opponentRemainingStones = 0;
    int n = board.pitsPerRow;
    int startIdx = opponent == Player.player1 ? 0 : n * 2;
    int endIdx = opponent == Player.player1 ? (n * 2) - 1 : (n * 4) - 1;
    
    for (int i = startIdx; i <= endIdx; i++) {
      opponentRemainingStones += board.getPit(i).stones;
    }

    if (captured && opponentRemainingStones > 0) {
      state = state.copyWith(
        board: board.copy(),
        movingStones: {},
        stonesInHand: 0, 
        canCapture: true, 
      );
      
      if (state.isSinglePlayer && state.currentPlayer == Player.player2) {
        _triggerAICapture();
      }
    } else {
      state = state.copyWith(stonesInHand: 0, canCapture: false); 
      _checkWinAndSwitch(board);
    }
  }

  void bankStones(int pitIndex) async {
    if (!state.canCapture || state.isPaused || state.isGameOver) return;
    
    Board board = state.board.copy();
    Pit targetPit = board.getPit(pitIndex);
    
    if (targetPit.owner == state.currentPlayer || targetPit.type == PitType.bank) return;

    int capturedStones = targetPit.stones;
    targetPit.stones = 0;
    Pit bank = board.getBank(state.currentPlayer);
    
    state = state.copyWith(
      canCapture: false, 
      movingStones: {pitIndex: capturedStones}
    );

    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(movingStones: {bank.index: capturedStones});
    await Future.delayed(const Duration(milliseconds: 500));

    bank.stones += capturedStones;
    
    state = state.copyWith(
      board: board.copy(),
      movingStones: {},
    );

    _checkWinAndSwitch(board);
  }

  void _checkWinAndSwitch(Board board) {
    Player? winner = MorubaEngine.checkWinner(board);
    state = state.copyWith(
      board: board,
      winner: winner,
      activePit: null,
      movingStones: {},
    );

    if (winner == null) {
      state = state.copyWith(currentPlayer: state.currentPlayer.opponent);
      
      if (state.isSinglePlayer && state.currentPlayer == Player.player2) {
        _triggerAIMove();
      }
    }
  }

  void _triggerAIMove() async {
  await Future.delayed(const Duration(milliseconds: 1200));
  if (state.isGameOver || state.isPaused || state.currentPlayer != Player.player2) return;
  
  // Passes the runtime active difficulty selection variable smoothly into the calculation engine
  int bestMove = AIEngine.getBestMove(state.board, Player.player2, state.aiDifficulty);
  makeMove(bestMove);
  }

  void _triggerAICapture() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (state.isGameOver || state.isPaused || state.currentPlayer != Player.player2 || !state.canCapture) return;
    int bestTarget = AIEngine.getBestCapture(state.board, Player.player2);
    bankStones(bestTarget);
  }

  void resetGame({int? newSize, AIDifficulty? difficulty}) {
  bool wasSingle = state.isSinglePlayer;
  int size = newSize ?? state.boardSize;
  AIDifficulty diff = difficulty ?? state.aiDifficulty;
  
  state = GameState(
    board: Board.initial(pitsPerRow: size), 
    isSinglePlayer: wasSingle, 
    boardSize: size,
    aiDifficulty: diff
  );
}

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
    if (!state.isPaused && state.isSinglePlayer && state.currentPlayer == Player.player2) {
      if (state.canCapture) _triggerAICapture();
      else if (state.movingStones.isEmpty) _triggerAIMove();
    }
  }
}