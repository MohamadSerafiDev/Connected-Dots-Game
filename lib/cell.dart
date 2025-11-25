class Cell {
  final String color;
  final CellType type;

  Cell({required this.color, required this.type});

  Cell copy() => Cell(color: color, type: type);
}

enum CellType { start, end, path }
