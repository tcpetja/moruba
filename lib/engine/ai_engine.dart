import 'dart:math';
import '../domain/board.dart';
import '../domain/player.dart';
import '../domain/pit.dart';
import '../state/game_state.dart';
import 'moruba_engine.dart';

class AIEngine {
  static final Random _random = Random();

  static int getBestCapture(Board board, Player aiPlayer) {
    int n = board.pitsPerRow;
    int startIdx = aiPlayer == Player.player1 ? n * 2 : 0;
    int endIdx = aiPlayer == Player.player1 ? (n * 4) - 1 : (n * 2) - 1;

    int bestPit = startIdx;
    int maxStones = -1;

    for (int i = startIdx; i <= endIdx; i++) {
      if (board.getPit(i).stones > maxStones) {
        maxStones = board.getPit(i).stones;
        bestPit = i;
      }
    }
    return bestPit; 
  }

  /// NEW: Handles dynamic choice calculation parameters based on level selection
  static int getBestMove(Board board, Player aiPlayer, AIDifficulty difficulty) {
    int n = board.pitsPerRow;
    List<int> validMoves = [];
    int startIdx = aiPlayer == Player.player1 ? 0 : n * 2;
    int endIdx = aiPlayer == Player.player1 ? (n * 2) - 1 : (n * 4) - 1;

    for (int i = startIdx; i <= endIdx; i++) {
      if (MorubaEngine.isValidMove(board, i, aiPlayer)) {
        validMoves.add(i);
      }
    }

    if (validMoves.isEmpty) return startIdx; 

    // LEVEL 1: BEGINNER - Picks any completely random legal pile
    if (difficulty == AIDifficulty.beginner) {
      return validMoves[_random.nextInt(validMoves.length)];
    }

    // Determine simulation depth boundaries
    int maxDepth = 1; // Intermediate default
    if (difficulty == AIDifficulty.expert) maxDepth = 3;
    if (difficulty == AIDifficulty.master) maxDepth = 5;

    int bestMove = validMoves[0];
    int bestScore = -99999;

    for (int move in validMoves) {
      Board simulatedBoard = _simulateTurn(board.copy(), move, aiPlayer, 0, maxDepth);
      int score = _evaluateBoard(simulatedBoard, aiPlayer, difficulty);
      
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    return bestMove;
  }

  static int _evaluateBoard(Board board, Player aiPlayer, AIDifficulty difficulty) {
    Player opponent = aiPlayer.opponent;
    int myBank = board.getBank(aiPlayer).stones;
    int oppBank = board.getBank(opponent).stones;
    
    int myFrontStones = _countRowStones(board, aiPlayer, true);
    int oppFrontStones = _countRowStones(board, opponent, true);

    // LEVEL 2: INTERMEDIATE - Pure simple greed (only counts absolute bank points)
    if (difficulty == AIDifficulty.intermediate) {
      return (myBank - oppBank) * 100;
    }

    // LEVEL 3 & 4: EXPERT / MASTER - Positional evaluation heuristics
    return (myBank - oppBank) * 100 + (myFrontStones - oppFrontStones) * 15;
  }

  static int _countRowStones(Board board, Player player, bool isFront) {
    int count = 0;
    int n = board.pitsPerRow;
    int start = player == Player.player1 ? (isFront ? n : 0) : (isFront ? n * 3 : n * 2);
    int end = player == Player.player1 ? (isFront ? (n * 2) - 1 : n - 1) : (isFront ? (n * 4) - 1 : (n * 3) - 1);
    
    for (int i = start; i <= end; i++) {
      count += board.getPit(i).stones;
    }
    return count;
  }

  static Board _simulateTurn(Board board, int startIndex, Player player, int depth, int maxDepth) {
    if (depth > maxDepth || depth > 20) return board; 

    int currentIndex = startIndex;
    int remaining = board.getPit(currentIndex).stones;
    board.getPit(currentIndex).stones = 0;

    while (remaining > 0) {
      currentIndex = MorubaEngine.getNextPit(currentIndex, player, board.pitsPerRow);
      board.getPit(currentIndex).stones++;
      remaining--;
    }

    Pit landingPit = board.getPit(currentIndex);
    if (landingPit.stones > 1) {
        return _simulateTurn(board, currentIndex, player, depth + 1, maxDepth);
    } else {
        bool captured = MorubaEngine.checkAndApplyCapture(board, currentIndex, player);
        if (captured) {
            int capturePit = getBestCapture(board, player);
            int gained = board.getPit(capturePit).stones;
            board.getPit(capturePit).stones = 0;
            board.getBank(player).stones += gained;
        }
    }
    return board;
  }
}