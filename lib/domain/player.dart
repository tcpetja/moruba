enum Player {
  player1,
  player2;

  Player get opponent => this == Player.player1 ? Player.player2 : Player.player1;
}