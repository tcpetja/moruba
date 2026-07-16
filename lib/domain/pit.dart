import 'player.dart';

enum PitType { standard, bank }

class Pit {
  final int index;
  final Player owner;
  final PitType type;
  int stones;

  Pit({
    required this.index,
    required this.owner,
    this.type = PitType.standard,
    this.stones = 0,
  });

  /// Identifies if this pit is in the front row (closest to the opponent)
  bool get isFrontRow {
    if (type == PitType.bank) return false;
    return owner == Player.player1 
        ? (index >= 6 && index <= 11) 
        : (index >= 18 && index <= 23);
  }

  /// Identifies if this pit is in the back row
  bool get isBackRow {
    if (type == PitType.bank) return false;
    return owner == Player.player1 
        ? (index >= 0 && index <= 5) 
        : (index >= 12 && index <= 17);
  }

  /// Creates a deep copy of the pit for immutable state updates
  Pit copy() {
    return Pit(
      index: index,
      owner: owner,
      type: type,
      stones: stones,
    );
  }
}