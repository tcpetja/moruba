import 'pit.dart';
import 'player.dart';

class Board {
  final Map<int, Pit> pits;
  final int pitsPerRow;

  Board({required this.pits, required this.pitsPerRow});

  static Board initial({int pitsPerRow = 12}) {
    Map<int, Pit> initialPits = {};
    int totalStandard = pitsPerRow * 4;
    
    // 1. Fill all standard pits with 2 stones initially
    for (int i = 0; i < pitsPerRow * 2; i++) {
      initialPits[i] = Pit(index: i, stones: 2, owner: Player.player1, type: PitType.standard);
    }
    for (int i = pitsPerRow * 2; i < totalStandard; i++) {
      initialPits[i] = Pit(index: i, stones: 2, owner: Player.player2, type: PitType.standard);
    }
    
    // 2. Apply the starting rules based on board size
    if (pitsPerRow == 24 || pitsPerRow == 32) {
      // Player 1 leading pits: 0, 0, 1, 2
      initialPits[pitsPerRow]!.stones = 0;
      initialPits[pitsPerRow + 1]!.stones = 0;
      initialPits[pitsPerRow + 2]!.stones = 1;
      // initialPits[pitsPerRow + 3] is already 2 from the loop above

      // Player 2 leading pits: 0, 0, 1, 2
      initialPits[(pitsPerRow * 4) - 1]!.stones = 0;
      initialPits[(pitsPerRow * 4) - 2]!.stones = 0;
      initialPits[(pitsPerRow * 4) - 3]!.stones = 1;
      // initialPits[(pitsPerRow * 4) - 4] is already 2
    } else {
      // Standard Moruba starting rules for 12 and 18 pits
      initialPits[pitsPerRow]!.stones = 0;
      initialPits[pitsPerRow + 1]!.stones = 1;
      initialPits[(pitsPerRow * 4) - 1]!.stones = 0;
      initialPits[(pitsPerRow * 4) - 2]!.stones = 1;
    }

    // 3. Setup the Banks
    initialPits[totalStandard] = Pit(index: totalStandard, stones: 0, owner: Player.player1, type: PitType.bank);
    initialPits[totalStandard + 1] = Pit(index: totalStandard + 1, stones: 0, owner: Player.player2, type: PitType.bank);

    return Board(pits: initialPits, pitsPerRow: pitsPerRow);
  }

  Pit getPit(int index) => pits[index]!;

  Pit getBank(Player player) {
    return player == Player.player1 ? pits[pitsPerRow * 4]! : pits[pitsPerRow * 4 + 1]!;
  }

  bool isSingleStonesPhase(Player player) {
    int startIdx = player == Player.player1 ? 0 : pitsPerRow * 2;
    int endIdx = player == Player.player1 ? (pitsPerRow * 2) - 1 : (pitsPerRow * 4) - 1;
    
    for (int i = startIdx; i <= endIdx; i++) {
      if (pits[i]!.stones > 1) return false;
    }
    return true;
  }

  Board copy() {
    Map<int, Pit> newPits = {};
    pits.forEach((key, pit) {
      newPits[key] = Pit(index: pit.index, stones: pit.stones, owner: pit.owner, type: pit.type);
    });
    return Board(pits: newPits, pitsPerRow: pitsPerRow);
  }
}