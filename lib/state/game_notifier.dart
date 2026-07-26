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
    if (state.isGameOver || state.movingStones.isNotEmpty || state.jumpMove != null || state.isPaused || state.canCapture) return;

    Board currentBoard = state.board.copy();
    Pit tappedPit = currentBoard.getPit(pitIndex);

    // 1. Single Stones Phase 2-Tap Logic
    if (currentBoard.isSingleStonesPhase(state.currentPlayer)) {
      if (state.selectedPitForJump == null) {
        if (MorubaEngine.isValidMove(currentBoard, pitIndex, state.currentPlayer, isFirstMove: state.isFirstMove)) {
          state = state.copyWith(selectedPitForJump: pitIndex);
        }
        return;
      } else {
        // Tapped pit while a stone is selected
        if (pitIndex == state.selectedPitForJump) {
          state = state.copyWith(clearSelectedPit: true); // Deselect
          return;
        }
        
        if (MorubaEngine.isValidMove(currentBoard, pitIndex, state.currentPlayer, selectedPitForJump: state.selectedPitForJump)) {
          // Execute Jump/Move
          int fromPit = state.selectedPitForJump!;
          state = state.copyWith(
            clearSelectedPit: true,
            jumpMove: {fromPit: pitIndex},
            isFirstMove: false,
          );
          _executeJump(fromPit, pitIndex, currentBoard);
          return;
        } else if (tappedPit.stones == 1 && tappedPit.owner == state.currentPlayer) {
          // Change selection to another stone
          state = state.copyWith(selectedPitForJump: pitIndex);
          return;
        }
        return; // Invalid target tap ignored
      }
    }

    // 2. Standard Sowing Logic
    if (!MorubaEngine.isValidMove(currentBoard, pitIndex, state.currentPlayer, isFirstMove: state.isFirstMove)) return;

    int stonesToMove = tappedPit.stones;
    tappedPit.stones = 0;

    state = state.copyWith(
      board: currentBoard,
      activePit: pitIndex,
      movingStones: {pitIndex: stonesToMove},
      stonesInHand: stonesToMove, 
      canCapture: false,
      isFirstMove: false, 
    );

    _distributeStones(currentBoard, pitIndex, stonesToMove);
  }

  void _executeJump(int fromPit, int toPit, Board board) async {
    board.getPit(fromPit).stones = 0;
    board.getPit(toPit).stones = 1;
    
    // UI triggers flying stone animation via jumpMove Map
    await Future.delayed(const Duration(milliseconds: 350));
    
    state = state.copyWith(clearJumpMove: true, board: board);
    _finalizeMove(board, toPit);
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
      clearSelectedPit: true,
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

    List<int> bestMove = AIEngine.getBestMove(state.board, Player.player2, state.aiDifficulty, state.isFirstMove);
    
    // Process jump vs standard move
    if (bestMove.length == 2) {
      state = state.copyWith(selectedPitForJump: bestMove[0]);
      await Future.delayed(const Duration(milliseconds: 600)); // AI 'thinking' delay
      makeMove(bestMove[1]);
    } else {
      makeMove(bestMove[0]);
    }
  }

  void _triggerAICapture() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (state.isGameOver || state.isPaused || state.currentPlayer != Player.player2 || !state.canCapture) return;

    int bestTarget = AIEngine.getBestCapture(state.board, Player.player2);
    bankStones(bestTarget);
  }

  void resetGame({int? newSize, AIDifficulty? difficulty, Player? startingPlayer}) {
    bool wasSingle = state.isSinglePlayer;
    int size = newSize ?? state.boardSize;
    AIDifficulty diff = difficulty ?? state.aiDifficulty;
    Player start = startingPlayer ?? Player.player1;

    state = GameState(
      board: Board.initial(pitsPerRow: size), 
      isSinglePlayer: wasSingle, 
      boardSize: size,
      aiDifficulty: diff,
      currentPlayer: start,
      isFirstMove: true,
    );

    if (wasSingle && start == Player.player2) {
      _triggerAIMove();
    }
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
    if (!state.isPaused && state.isSinglePlayer && state.currentPlayer == Player.player2) {
      if (state.canCapture) _triggerAICapture();
      else if (state.movingStones.isEmpty) _triggerAIMove();
    }
  }
}