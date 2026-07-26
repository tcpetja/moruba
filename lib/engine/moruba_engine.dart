import '../domain/board.dart';
import '../domain/player.dart';
import '../domain/pit.dart';

class MorubaEngine {

  // Generates the strict linear path a player's stones travel along
  static List<int> getPlayerPath(int n, Player player) {
    List<int> path = [];
    if (player == Player.player1) {
      for (int i = 0; i < n; i++) path.add(i); // Back row: Left to right
      for (int i = (n * 2) - 1; i >= n; i--) path.add(i); // Front row: Right to left
    } else {
      for (int i = (n * 3) - 1; i >= n * 2; i--) path.add(i); // Back row: Right to left
      for (int i = n * 3; i < n * 4; i++) path.add(i); // Front row: Left to right
    }
    return path;
  }

  // Finds the index in the path array of the leading stone
  static int getLeadingStonePathIndex(Board board, Player player) {
    List<int> path = getPlayerPath(board.pitsPerRow, player);
    for (int i = path.length - 1; i >= 0; i--) {
      if (board.getPit(path[i]).stones > 0) return i;
    }
    return 0;
  }
  
  static bool isValidMove(Board board, int index, Player player, {bool isFirstMove = false, int? selectedPitForJump}) {
    final pit = board.getPit(index);
    if (pit.owner != player || pit.type == PitType.bank) return false;

    bool isSinglePhase = board.isSingleStonesPhase(player);

    if (isSinglePhase) {
      if (selectedPitForJump == null) {
         // Stage 1: Selecting a stone to move
         return pit.stones == 1 && (!isFirstMove);
      } else {
         // Stage 2: Selecting the destination
         if (pit.stones != 0) return false; // Must drop into empty pit

         int nextOfSelected = getNextPit(selectedPitForJump, player, board.pitsPerRow);
         if (index == nextOfSelected) return true; // Standard 1-step forward into an empty pit is valid

         // Jump Logic: Validate it's before the leading stone AND not behind the current stone
         List<int> path = getPlayerPath(board.pitsPerRow, player);
         int leadingIdx = getLeadingStonePathIndex(board, player);
         int targetIdx = path.indexOf(index);
         int sourceIdx = path.indexOf(selectedPitForJump);
         
         // The target must be strictly ahead of the current stone, and strictly behind the leading stone
         return targetIdx > sourceIdx && targetIdx < leadingIdx;
      }
    }

    // Standard mode logic
    if (pit.stones == 0) return false;
    if (isFirstMove && pit.stones == 1) return false;

    if (pit.stones == 1) {
      int n = board.pitsPerRow;
      int startIdx = player == Player.player1 ? 0 : n * 2;
      int endIdx = player == Player.player1 ? (n * 2) - 1 : (n * 4) - 1;
      for (int i = startIdx; i <= endIdx; i++) {
        if (board.getPit(i).stones > 1) return false;
      }
    }
    
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