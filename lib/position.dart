class Position {
  final int x;
  final int y;

  Position(this.x, this.y);

  Position copy() => Position(x, y);
}
