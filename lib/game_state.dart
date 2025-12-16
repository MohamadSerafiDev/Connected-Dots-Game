import 'dart:developer' as dev;
import 'dart:math';

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
    final rawHash = board
        .map(
          (row) => row.map((cell) => cell == null ? '0' : cell.color).join(''),
        )
        .join('');

    if (rawHash.isEmpty) {
      return '';
    }

    final StringBuffer compressedHash = StringBuffer();
    int count = 1;
    String? currentChar = rawHash[0];

    for (int i = 1; i < rawHash.length; i++) {
      if (rawHash[i] == currentChar) {
        count++;
      } else {
        if (count > 1) {
          compressedHash.write(count);
        }
        compressedHash.write(currentChar);
        currentChar = rawHash[i];
        count = 1;
      }
    }

    // Append the last character(s)
    if (count > 1) {
      compressedHash.write(count);
    }
    compressedHash.write(currentChar);

    return compressedHash.toString();
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
    dev.log(path.first.x.toString(), name: 'last x');
    dev.log(path.first.y.toString(), name: 'last y');
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
    dev.log('\n=== Number Link Board ===');
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
      dev.log(row, name: 'board');
    }
    dev.log('========================\n');
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

  Stream<GameState> solveWithDFS() async* {
    final colorSolvingPairs = List<ColorPair>.from(colorPairs);
    final visitedStates = <String>{};

    // state in the stack is a tuple: (GameState, indexOfPairToSolve)
    final stack = <(GameState, int)>[(this, 0)];
    visitedStates.add('${getHashOfState()}_0');

    while (stack.isNotEmpty) {
      final (currentState, pairIndex) = stack.removeLast();
      dev.log(stack.length.toString(), name: 'stacke length');

      // dev.log('pairIndex: $pairIndex', name: 'pairIndex');
      // dev.log(
      //   'currentState: ${currentState.getHashOfState()}',
      //   name: 'currentState',
      // );
      yield currentState;

      if (pairIndex == colorSolvingPairs.length) {
        if (currentState.isFinalState()) {
          yield currentState;
          return;
        }
        continue;
      }

      final pair = colorSolvingPairs[pairIndex];
      final color = pair.color;
      final path = currentState.paths[color]!;
      final lastPos = path.last;

      if (lastPos.x == pair.end.x && lastPos.y == pair.end.y) {
        // this color is already connected -> Move to the next one
        final nextStateTuple = (currentState, pairIndex + 1);
        final hash = '${currentState.getHashOfState()}_${pairIndex + 1}';
        if (!visitedStates.contains(hash)) {
          visitedStates.add(hash);
          stack.add(nextStateTuple);
        }
        continue;
      }

      // this color is not connected yet -> Find possible moves
      final possibleMoves = currentState.getPossibleMoves(color);

      for (final move in possibleMoves) {
        dev.log(move.x.toString(), name: 'move x');
        dev.log(move.y.toString(), name: 'move y');
        final newState = currentState.copyState();
        newState.makePossibleMoves(move.x, move.y, color);

        final newPath = newState.paths[color]!;
        final newLastPos = newPath.last;

        int nextPairIndex = pairIndex;
        if (newLastPos.x == pair.end.x && newLastPos.y == pair.end.y) {
          // the path for this color is complete -> move to the next color
          nextPairIndex = pairIndex + 1;
        }

        final hash = '${newState.getHashOfState()}_$nextPairIndex';
        if (!visitedStates.contains(hash)) {
          visitedStates.add(hash);
          stack.add((newState, nextPairIndex));
        }
      }
    }
  }

  Stream<GameState> solveWithBFS() async* {
    final colorSolvingPairs = List<ColorPair>.from(colorPairs);
    final visitedStates = <String>{};

    // state in the queue is a tuple: (GameState, indexOfPairToSolve)
    final queue = <(GameState, int)>[(this, 0)];
    visitedStates.add('${getHashOfState()}_0');

    while (queue.isNotEmpty) {
      final (currentState, pairIndex) = queue.removeAt(0);
      // dev.log(queue.length.toString(), name: 'queue length');

      // dev.log(
      //   'currentState: ${currentState.getHashOfState()}',
      //   name: 'currentState',
      // );
      yield currentState;

      if (pairIndex == colorSolvingPairs.length) {
        if (currentState.isFinalState()) {
          yield currentState;
          return;
        }
        continue;
      }

      final pair = colorSolvingPairs[pairIndex];
      final color = pair.color;
      final path = currentState.paths[color]!;
      final lastPos = path.last;

      if (lastPos.x == pair.end.x && lastPos.y == pair.end.y) {
        // this color is already connected -> move to the next one
        final nextStateTuple = (currentState, pairIndex + 1);
        final hash = '${currentState.getHashOfState()}_${pairIndex + 1}';
        if (!visitedStates.contains(hash)) {
          visitedStates.add(hash);
          queue.add(nextStateTuple);
        }
        continue;
      }

      // this color is not connected yet -> find possible moves
      final possibleMoves = currentState.getPossibleMoves(color);

      for (final move in possibleMoves) {
        // dev.log(move.x.toString(), name: 'move x');
        // dev.log(move.y.toString(), name: 'move y');
        final newState = currentState.copyState();
        newState.makePossibleMoves(move.x, move.y, color);

        final newPath = newState.paths[color]!;
        final newLastPos = newPath.last;

        int nextPairIndex = pairIndex;
        if (newLastPos.x == pair.end.x && newLastPos.y == pair.end.y) {
          // the path for this color is complete -> move to the next color
          nextPairIndex = pairIndex + 1;
        }

        final hash = '${newState.getHashOfState()}_$nextPairIndex';
        if (!visitedStates.contains(hash)) {
          dev.log(visitedStates.contains(hash).toString(), name: 'visited?');
          visitedStates.add(hash);
          queue.add((newState, nextPairIndex));
        }
      }
    }
  }

  Stream<GameState> solveWithUCS(List<List<int>> weights) async* {
    if (weights.length != size || weights.any((row) => row.length != size)) {
      throw ArgumentError('weights grid must match board size');
    }

    final colorSolvingPairs = List<ColorPair>.from(colorPairs);
    final visitedCosts = <String, int>{};

    // (state, pairIndex, cost).

    final queue = <(GameState, int, int)>[(this, 0, 0)];
    visitedCosts['${getHashOfState()}_0'] = 0;
    int allCost = 0;

    while (queue.isNotEmpty) {
      // lowest first
      queue.sort((a, b) {
        final (_, _, ca) = a;
        final (_, _, cb) = b;
        return ca.compareTo(cb);
      });

      final (currentState, pairIndex, currentCost) = queue.removeAt(0);
      yield currentState;

      if (pairIndex == colorSolvingPairs.length) {
        if (currentState.isFinalState()) {
          // dev.log(allCost.toString(), name: 'total cost');

          dev.log(currentState.paths.toString());

          // dev.log('15', name: 'solution cost');
          yield currentState;
          return;
        }
        continue;
      }

      final pair = colorSolvingPairs[pairIndex];
      final color = pair.color;
      final path = currentState.paths[color]!;
      final lastPos = path.last;

      if (lastPos.x == pair.end.x && lastPos.y == pair.end.y) {
        // This color already connected -> advance to next color.
        final nextStateTuple = (currentState, pairIndex + 1, currentCost);
        final hash = '${currentState.getHashOfState()}_${pairIndex + 1}';
        final prevCost = visitedCosts[hash];
        if (prevCost == null || currentCost < prevCost) {
          visitedCosts[hash] = currentCost;
          queue.add(nextStateTuple);
        }
        continue;
      }

      // Not connected yet -> expand possible moves
      final possibleMoves = currentState.getPossibleMoves(color);

      for (final move in possibleMoves) {
        final moveCost = weights[move.y][move.x];
        final newCost = currentCost + moveCost;

        if (moveCost > 9) {
          continue;
        }
        moveCost > 9 ? dev.log(moveCost.toString(), name: 'big move') : null;
        allCost = allCost + moveCost;
        final newState = currentState.copyState();
        newState.makePossibleMoves(move.x, move.y, color);

        final newPath = newState.paths[color]!;
        final newLastPos = newPath.last;

        int nextPairIndex = pairIndex;
        if (newLastPos.x == pair.end.x && newLastPos.y == pair.end.y) {
          nextPairIndex = pairIndex + 1;
        }

        final hash = '${newState.getHashOfState()}_$nextPairIndex';
        final prevCost = visitedCosts[hash];
        if (prevCost == null || newCost < prevCost) {
          visitedCosts[hash] = newCost;
          queue.add((newState, nextPairIndex, newCost));
        }
      }
    }
  }
  //advanced

  // ------------------------------------------------------------------------
  // HEURISTIC FUNCTIONS
  // ------------------------------------------------------------------------

  /// Calculates Manhattan distance between two positions: |x1 - x2| + |y1 - y2|
  int getManhattanDistance(Position p1, Position p2) {
    return (p1.x - p2.x).abs() + (p1.y - p2.y).abs();
  }

  /// Calculates the total H(n) for the current state.
  /// Sum of Manhattan distances from the current head of every color path
  /// to its target end position.
  int calculateHeuristic() {
    int totalDistance = 0;
    for (var pair in colorPairs) {
      final path = paths[pair.color];

      // If the color has a path started, measure from the last point (head).
      // If not (unlikely in this structure), measure from start.
      if (path != null && path.isNotEmpty) {
        totalDistance += getManhattanDistance(path.last, pair.end);
      } else {
        totalDistance += getManhattanDistance(pair.start, pair.end);
      }
    }
    return totalDistance;
  }

  // ------------------------------------------------------------------------
  // HILL CLIMBING ALGORITHM
  // ------------------------------------------------------------------------

  /// Hill Climbing: Iteratively moves to the neighbor with the lowest Heuristic value.
  /// Stops if no neighbor offers an improvement (Local Maximum).
  Stream<GameState> solveWithHillClimbing() async* {
    final colorSolvingPairs = List<ColorPair>.from(colorPairs);

    // We maintain a single "current" state pointer (Greedy approach)
    GameState currentState = this;
    int pairIndex = 0;

    yield currentState;

    while (pairIndex < colorSolvingPairs.length) {
      final pair = colorSolvingPairs[pairIndex];
      final color = pair.color;
      final path = currentState.paths[color]!;
      final lastPos = path.last;

      // 1. Check if current color is done
      if (lastPos.x == pair.end.x && lastPos.y == pair.end.y) {
        pairIndex++; // Move to next color
        continue; // Loop again to process next color
      }

      // 2. Find neighbors (possible moves)
      final possibleMoves = currentState.getPossibleMoves(color);

      if (possibleMoves.isEmpty) {
        dev.log(
          'Hill Climbing stuck: No moves available (Dead End)',
          name: 'HillClimbing',
        );
        return;
      }

      // 3. Evaluate neighbors
      GameState? bestNeighbor;
      int bestH = 999999;
      int currentH = currentState.calculateHeuristic();

      for (final move in possibleMoves) {
        final neighborState = currentState.copyState();
        neighborState.makePossibleMoves(move.x, move.y, color);

        // Calculate H for the neighbor
        int h = neighborState.calculateHeuristic();

        // Hill Climbing logic: Only track the strict best
        if (h < bestH) {
          bestH = h;
          bestNeighbor = neighborState;
        }
      }

      // 4. Decide to move or stop
      // If the best neighbor is not better than current, we are in a Local Maximum.
      if (bestNeighbor != null && bestH < currentH) {
        currentState = bestNeighbor;
        yield currentState;

        // Check if this move completed the game
        if (currentState.isFinalState()) {
          return;
        }
      } else {
        dev.log(
          'Hill Climbing stuck: Local Maximum reached (Best H: $bestH >= Current H: $currentH)',
          name: 'HillClimbing',
        );
        // In strict Hill Climbing, we stop here.
        return;
      }
    }
  }

  // ------------------------------------------------------------------------
  // A* ALGORITHM
  // ------------------------------------------------------------------------

  /// A*: Uses a Priority Queue to minimize F(n) = G(n) + H(n)
  /// G(n): Cost from start (accumulated weights)
  /// H(n): Heuristic estimate (Manhattan distance)
  Stream<GameState> solveWithAStar(List<List<int>> weights) async* {
    if (weights.length != size || weights.any((row) => row.length != size)) {
      throw ArgumentError('weights grid must match board size');
    }

    final colorSolvingPairs = List<ColorPair>.from(colorPairs);
    final visitedCosts =
        <String, int>{}; // Map state_hash -> lowest G cost found so far

    // Priority Queue List.
    // Elements: (GameState, pairIndex, g_score, f_score)
    // We sort this list every iteration to simulate a Min-Heap.
    final queue = <(GameState, int, int, int)>[];

    // Initial State
    int startH = calculateHeuristic();
    queue.add((this, 0, 0, 0 + startH));
    visitedCosts['${getHashOfState()}_0'] = 0;

    while (queue.isNotEmpty) {
      // Sort by F-score (lowest first). If F is equal, sort by H (closest to goal).
      queue.sort((a, b) {
        final fCompare = a.$4.compareTo(b.$4);
        if (fCompare != 0) return fCompare;
        // Tie-breaker: prefer lower H (greedy bias often helps speed)
        final hA = a.$4 - a.$3; // F - G = H
        final hB = b.$4 - b.$3;
        return hA.compareTo(hB);
      });

      final (currentState, pairIndex, currentG, currentF) = queue.removeAt(0);
      yield currentState;

      // Goal Check
      if (pairIndex == colorSolvingPairs.length) {
        if (currentState.isFinalState()) {
          dev.log('A* Solution Found! Final Cost (G): $currentG', name: 'A*');
          yield currentState;
          return;
        }
        continue;
      }

      final pair = colorSolvingPairs[pairIndex];
      final color = pair.color;
      final path = currentState.paths[color]!;
      final lastPos = path.last;

      // Case A: Color is already connected -> Switch to next color
      if (lastPos.x == pair.end.x && lastPos.y == pair.end.y) {
        final nextPairIndex = pairIndex + 1;
        final hash = '${currentState.getHashOfState()}_$nextPairIndex';

        // No movement cost to switch context, but we need to check visited
        if (!visitedCosts.containsKey(hash) || currentG < visitedCosts[hash]!) {
          visitedCosts[hash] = currentG;
          // H might change slightly if we calculate based on active color context,
          // but strictly summing Manhattan distances stays same.
          int h = currentState.calculateHeuristic();
          queue.add((currentState, nextPairIndex, currentG, currentG + h));
        }
        continue;
      }

      // Case B: Move the current color
      final possibleMoves = currentState.getPossibleMoves(color);
      for (final move in possibleMoves) {
        final moveCost = weights[move.y][move.x];

        // Optional: Skip extremely high weights if they act as "walls"
        if (moveCost > 50) continue;

        final newG = currentG + moveCost;

        final newState = currentState.copyState();
        newState.makePossibleMoves(move.x, move.y, color);

        // Determine next pair index
        final newLastPos = newState.paths[color]!.last;
        int nextPairIndex = pairIndex;
        if (newLastPos.x == pair.end.x && newLastPos.y == pair.end.y) {
          nextPairIndex = pairIndex + 1;
        }

        final hash = '${newState.getHashOfState()}_$nextPairIndex';

        if (!visitedCosts.containsKey(hash) || newG < visitedCosts[hash]!) {
          visitedCosts[hash] = newG;
          int h = newState.calculateHeuristic();
          queue.add((newState, nextPairIndex, newG, newG + h));
        }
      }
    }
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
