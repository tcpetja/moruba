import '../domain/board.dart';
import '../domain/player.dart';
import '../domain/pit.dart';

class MorubaEngine {
  
  /// THE FIX: Anti-Stalling Rule implemented!
  static bool isValidMove(Board board, int index, Player player) {
    final pit = board.getPit(index);
    
    // 1. Basic checks: Must be your pit, must have stones, cannot be the bank
    if (pit.owner != player || pit.stones == 0 || pit.type == PitType.bank) {
      return false;
    }

    // 2. If it has more than 1 stone, it's always a legal move
    if (pit.stones > 1) return true;

    // 3. If it has exactly 1 stone, we must verify you don't have any bigger piles
    int n = board.pitsPerRow;
    int startIdx = player == Player.player1 ? 0 : n * 2;
    int endIdx = player == Player.player1 ? (n * 2) - 1 : (n * 4) - 1;

    for (int i = startIdx; i <= endIdx; i++) {
      if (board.getPit(i).stones > 1) {
        // We found a pit with multiple stones! 
        // Therefore, playing this 1-stone pit is illegal right now.
        return false; 
      }
    }

    // If we made it here, all your non-empty pits have exactly 1 stone, so it's legal!
    return true; 
  }

  static int getNextPit(int currentIndex, Player player, int pitsPerRow) {
    int n = pitsPerRow;

    if (player == Player.player1) {
      if (currentIndex >= 0 && currentIndex < n - 1) return currentIndex + 1;
      if (currentIndex == n - 1) return (n * 2) - 1;
      if (currentIndex > n && currentIndex <= (n * 2) - 1) return currentIndex - 1;
      if (currentIndex == n) return 0;
    } else {
      if (currentIndex > n * 2 && currentIndex <= (n * 3) - 1) return currentIndex - 1;
      if (currentIndex == n * 2) return n * 3;
      if (currentIndex >= n * 3 && currentIndex < (n * 4) - 1) return currentIndex + 1;
      if (currentIndex == (n * 4) - 1) return (n * 3) - 1;
    }
    
    return currentIndex; 
  }

  static bool checkAndApplyCapture(Board board, int lastIndex, Player player) {
    int n = board.pitsPerRow;
    int p1FrontStart = n;
    int p1FrontEnd = (n * 2) - 1;
    int p2FrontStart = n * 3;
    int p2FrontEnd = (n * 4) - 1;

    bool isFrontRow = false;
    int col = -1; 

    if (player == Player.player1 && lastIndex >= p1FrontStart && lastIndex <= p1FrontEnd) {
      isFrontRow = true;
      col = lastIndex - p1FrontStart;
    } else if (player == Player.player2 && lastIndex >= p2FrontStart && lastIndex <= p2FrontEnd) {
      isFrontRow = true;
      col = lastIndex - p2FrontStart;
    }

    if (!isFrontRow) return false;

    int oppFrontIndex;
    int oppBackIndex;

    if (player == Player.player1) {
      oppFrontIndex = (n * 3) + col;
      oppBackIndex = (n * 2) + col;
    } else {
      oppFrontIndex = n + col;
      oppBackIndex = col;
    }

    if (board.getPit(oppFrontIndex).stones > 0) {
      int capturedStones = board.getPit(oppFrontIndex).stones;
      board.getPit(oppFrontIndex).stones = 0;

      capturedStones += board.getPit(oppBackIndex).stones;
      board.getPit(oppBackIndex).stones = 0;

      board.getBank(player).stones += capturedStones;

      return true; 
    }
    
    return false;
  }

  static Player? checkWinner(Board board) {
    int p1Stones = 0;
    int p2Stones = 0;
    int p1End = (board.pitsPerRow * 2) - 1;
    int p2End = (board.pitsPerRow * 4) - 1;

    for (int i = 0; i <= p1End; i++) p1Stones += board.getPit(i).stones;
    for (int i = board.pitsPerRow * 2; i <= p2End; i++) p2Stones += board.getPit(i).stones;

    if (p1Stones == 0) return Player.player2;
    if (p2Stones == 0) return Player.player1;
    return null;
  }
}