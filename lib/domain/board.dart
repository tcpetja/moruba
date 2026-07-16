import 'pit.dart';
import 'player.dart';

class Board {
  final Map<int, Pit> pits;
  final int pitsPerRow;

  Board({required this.pits, required this.pitsPerRow});

  static Board initial({int pitsPerRow = 6}) {
    Map<int, Pit> initialPits = {};
    int totalStandard = pitsPerRow * 4;
    
    // 1. Fill all standard pits with 2 stones initially
    for (int i = 0; i < pitsPerRow * 2; i++) {
      initialPits[i] = Pit(index: i, stones: 2, owner: Player.player1, type: PitType.standard);
    }
    for (int i = pitsPerRow * 2; i < totalStandard; i++) {
      initialPits[i] = Pit(index: i, stones: 2, owner: Player.player2, type: PitType.standard);
    }
    
    // 2. Apply the standard Moruba starting rules (The 0 and 1 pits)
    // Player 1: Front row, leftmost pits
    initialPits[pitsPerRow] = Pit(index: pitsPerRow, stones: 0, owner: Player.player1, type: PitType.standard);
    initialPits[pitsPerRow + 1] = Pit(index: pitsPerRow + 1, stones: 1, owner: Player.player1, type: PitType.standard);

    // Player 2: Front row, rightmost pits (Mirrors Player 1 perfectly)
    initialPits[(pitsPerRow * 4) - 1] = Pit(index: (pitsPerRow * 4) - 1, stones: 0, owner: Player.player2, type: PitType.standard);
    initialPits[(pitsPerRow * 4) - 2] = Pit(index: (pitsPerRow * 4) - 2, stones: 1, owner: Player.player2, type: PitType.standard);

    // 3. Setup the Banks
    initialPits[totalStandard] = Pit(index: totalStandard, stones: 0, owner: Player.player1, type: PitType.bank);
    initialPits[totalStandard + 1] = Pit(index: totalStandard + 1, stones: 0, owner: Player.player2, type: PitType.bank);

    return Board(pits: initialPits, pitsPerRow: pitsPerRow);
  }

  Pit getPit(int index) => pits[index]!;
  
  Pit getBank(Player player) {
    return player == Player.player1 ? pits[pitsPerRow * 4]! : pits[pitsPerRow * 4 + 1]!;
  }
  
  Board copy() {
    Map<int, Pit> newPits = {};
    pits.forEach((key, pit) {
      newPits[key] = Pit(index: pit.index, stones: pit.stones, owner: pit.owner, type: pit.type);
    });
    return Board(pits: newPits, pitsPerRow: pitsPerRow);
  }
}