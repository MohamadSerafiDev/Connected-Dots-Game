import 'dart:developer';
import 'dart:io';

import 'package:dot_connec_project/cell.dart';
import 'package:dot_connec_project/color_pair.dart';
import 'package:dot_connec_project/move_result.dart';
import 'package:dot_connec_project/position.dart';

class GameState {
  final int size;
  late List<List<Cell?>> board;
  final List<ColorPair> colorPairs;
  late Map<String, List<Position>> paths;
  List<Position> possibleMoves = [];

  GameState({required this.size, required this.colorPairs}) {
    board = List.generate(size, (_) => List.filled(size, null));
    paths = {};

    // Initialize board with start/end points
    for (var pair in colorPairs) {
      board[pair.start.y][pair.start.x] = Cell(
        color: pair.color,
        type: CellType.start,
      );
      board[pair.end.y][pair.end.x] = Cell(
        color: pair.color,
        type: CellType.end,
      );
      paths[pair.color] = [pair.start];
    }
  }

  void updatePossibleMoves(String? color) {
    if (color == null) {
      possibleMoves.clear();
    } else {
      possibleMoves = getPossibleMoves(color);
    }
  }

  bool isFinalState() {
    // Check if all color pairs are connected
    for (var pair in colorPairs) {
      final path = paths[pair.color];
      if (path == null || path.length < 2) return false;

      final lastPos = path.last;
      if (lastPos.x != pair.end.x || lastPos.y != pair.end.y) {
        return false;
      }
    }
    return true;
  }

  String getHashOfState() {
    return board
        .map(
          (row) => row.map((cell) => cell == null ? '0' : cell.color).join(','),
        )
        .join(',');
  }

  GameState copyState() {
    final newState = GameState(size: size, colorPairs: colorPairs);
    newState.board = List.generate(
      size,
      (y) => List.generate(size, (x) => board[y][x]?.copy()),
    );
    newState.paths = {};
    paths.forEach((color, path) {
      newState.paths[color] = path.map((pos) => pos.copy()).toList();
    });
    return newState;
  }

  MoveResult makePossibleMoves(int x, int y, String color) {
    final currentPath = paths[color];
    if (currentPath == null || currentPath.isEmpty) {
      return MoveResult(
        success: false,
        message: 'No active path for this color',
      );
    }

    final lastPos = currentPath.last;
    final targetPos = Position(x, y);

    // check if the selected square around the last cell selected
    final isAdjacent =
        (lastPos.x == targetPos.x &&
            (lastPos.y - 1 == targetPos.y || lastPos.y + 1 == targetPos.y)) ||
        (lastPos.y == targetPos.y &&
            (lastPos.x - 1 == targetPos.x || lastPos.x + 1 == targetPos.x));

    if (!isAdjacent) {
      return MoveResult(
        success: false,
        message: 'Move must be to an adjacent square',
      );
    }

    final cell = board[y][x];

    // validate move
    if (cell != null && cell.type != CellType.end) {
      return MoveResult(success: false, message: 'Cell already occupied');
    }

    if (cell != null && cell.type == CellType.end && cell.color != color) {
      return MoveResult(
        success: false,
        message: 'Cannot connect different colors',
      );
    }

    currentPath.add(targetPos);

    // Update board
    if (cell == null || cell.type != CellType.end) {
      board[y][x] = Cell(color: color, type: CellType.path);
    }

    return MoveResult(success: true);
  }

  bool removeLastMove(String color) {
    final path = paths[color];

    if (path == null || path.length <= 1) return false;
    log(path.first.x.toString(), name: 'last x');
    log(path.first.y.toString(), name: 'last y');
    final lastPos = path.removeLast();
    final cell = board[lastPos.y][lastPos.x];

    if (cell != null && cell.type == CellType.path) {
      board[lastPos.y][lastPos.x] = null;
    }

    return true;
  }

  void clearPath(String color) {
    final path = paths[color];
    if (path == null || path.length <= 1) return;

    // keep start position
    for (int i = 1; i < path.length; i++) {
      final pos = path[i];
      final cell = board[pos.y][pos.x];
      if (cell != null && cell.type == CellType.path) {
        board[pos.y][pos.x] = null;
      }
    }

    final pair = colorPairs.firstWhere((p) => p.color == color);
    paths[color] = [pair.start];
  }

  void printBoard() {
    log('\n=== Number Link Board ===');
    for (int y = 0; y < size; y++) {
      String row = '';
      for (int x = 0; x < size; x++) {
        final cell = board[y][x];
        if (cell == null) {
          row += '. ';
        } else {
          row += '${cell.color} ';
        }
      }
      log(row, name: 'board');
    }
    log('========================\n');
  }

  List<Position> getPossibleMoves(String color) {
    final path = paths[color];
    if (path == null || path.isEmpty) return [];

    final lastPos = path.last;
    final moves = <Position>[];
    final directions = [
      Position(0, -1), // up
      Position(1, 0), // right
      Position(0, 1), // down
      Position(-1, 0), // left
    ];

    for (var dir in directions) {
      final newX = lastPos.x + dir.x;
      final newY = lastPos.y + dir.y;

      if (newX >= 0 && newX < size && newY >= 0 && newY < size) {
        final cell = board[newY][newX];

        // move to empty the end point of same color
        if (cell == null ||
            (cell.type == CellType.end && cell.color == color)) {
          moves.add(Position(newX, newY));
        }
      }
    }

    return moves;
  }
}


// String getHashOfState() {
//     String hash = '';
//     for (int y = 0; y < size; y++) {
//       for (int x = 0; x < size; x++) {
//         final cell = board[y][x];
//         if (cell == null) {
//           hash += '|0|';
//         } else {
//           hash += '|${cell.color}|';
//         }
//       }
//     }
//     return hash;
//   }