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

  static int _getFocusPercentage(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.beginner: return 55;
      case AIDifficulty.intermediate: return 70;
      case AIDifficulty.expert: return 85;
      case AIDifficulty.master: return 100;
    }
  }

  static List<int> getBestMove(Board board, Player aiPlayer, AIDifficulty difficulty, bool isFirstMove) {
    if (MorubaEngine.isMutualStandoff(board)) {
      return _getBestStandoffJump(board, aiPlayer, difficulty, isFirstMove);
    }

    int n = board.pitsPerRow;
    List<int> validMoves = [];
    int startIdx = aiPlayer == Player.player1 ? 0 : n * 2;
    int endIdx = aiPlayer == Player.player1 ? (n * 2) - 1 : (n * 4) - 1;

    for (int i = startIdx; i <= endIdx; i++) {
      if (MorubaEngine.isValidMove(board, i, aiPlayer, isFirstMove: isFirstMove)) {
        validMoves.add(i);
      }
    }

    if (validMoves.isEmpty) return [startIdx]; 

    int focusChance = _getFocusPercentage(difficulty);
    bool isFocused = _random.nextInt(100) < focusChance;

    if (!isFocused) {
      return [validMoves[_random.nextInt(validMoves.length)]];
    }

    int maxDepth = difficulty == AIDifficulty.master ? 4 : 2;
    int bestMove = validMoves[0];
    int bestScore = -999999;

    for (int move in validMoves) {
      Board simulatedBoard = _simulateTurn(board.copy(), move, aiPlayer, 0, maxDepth);
      int score = _evaluateBoard(simulatedBoard, aiPlayer);
      
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return [bestMove];
  }

  static List<int> _getBestStandoffJump(Board board, Player aiPlayer, AIDifficulty difficulty, bool isFirstMove) {
    List<List<int>> validJumps = [];
    List<int> path = MorubaEngine.getPlayerPath(board.pitsPerRow, aiPlayer);
    int leadingIdx = MorubaEngine.getLeadingStonePathIndex(board, aiPlayer);

    for (int i = 0; i < path.length; i++) {
      int fromPit = path[i];
      if (board.getPit(fromPit).stones == 1 && !isFirstMove) {
        int nextPit = MorubaEngine.getNextPit(fromPit, aiPlayer, board.pitsPerRow);
        if (board.getPit(nextPit).stones == 0) {
          validJumps.add([fromPit, nextPit]);
        }
        
        // Jumps MUST be ahead of the current stone (i + 1) AND behind the leading stone (leadingIdx)
        for (int j = i + 1; j < leadingIdx; j++) {
          int toPit = path[j];
          if (board.getPit(toPit).stones == 0 && toPit != nextPit) {
            validJumps.add([fromPit, toPit]);
          }
        }
      }
    }

    if (validJumps.isEmpty) return [path[0], path[1]]; 

    int focusChance = _getFocusPercentage(difficulty);
    bool isFocused = _random.nextInt(100) < focusChance;

    if (!isFocused) {
      return validJumps[_random.nextInt(validJumps.length)];
    }

    int bestScore = -999999;
    List<int> bestJump = validJumps[0];

    for (var jump in validJumps) {
      Board sim = board.copy();
      sim.getPit(jump[0]).stones = 0;
      sim.getPit(jump[1]).stones = 1;
      
      bool captured = MorubaEngine.checkAndApplyCapture(sim, jump[1], aiPlayer);
      if (captured) {
        int capPit = getBestCapture(sim, aiPlayer);
        sim.getBank(aiPlayer).stones += sim.getPit(capPit).stones;
        sim.getPit(capPit).stones = 0;
      }
      
      int score = _evaluateBoard(sim, aiPlayer);
      if (score > bestScore) {
        bestScore = score;
        bestJump = jump;
      }
    }
    return bestJump;
  }

  static int _evaluateBoard(Board board, Player aiPlayer) {
    Player opponent = aiPlayer.opponent;
    int myBank = board.getBank(aiPlayer).stones;
    int oppBank = board.getBank(opponent).stones;
    
    int oppMaxCounterAttack = _getOpponentMaxCapture(board, opponent);

    return (myBank * 100) - (oppBank * 100) - (oppMaxCounterAttack * 150);
  }

  static int _getOpponentMaxCapture(Board board, Player opponent) {
    int maxCap = 0;
    int n = board.pitsPerRow;
    int startIdx = opponent == Player.player1 ? 0 : n * 2;
    int endIdx = opponent == Player.player1 ? (n * 2) - 1 : (n * 4) - 1;

    for (int i = startIdx; i <= endIdx; i++) {
      if (MorubaEngine.isValidMove(board, i, opponent)) {
        Board sim = _simulateTurn(board.copy(), i, opponent, 0, 1);
        int cap = sim.getBank(opponent).stones - board.getBank(opponent).stones;
        if (cap > maxCap) maxCap = cap;
      }
    }
    return maxCap;
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