import 'dart:developer';

import 'package:dot_connec_project/cell.dart';
import 'package:dot_connec_project/color_pair.dart';
import 'package:dot_connec_project/game_state.dart';
import 'package:dot_connec_project/position.dart';
import 'package:dot_connec_project/winning_states_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const NumberLinkApp());
}

class NumberLinkApp extends StatelessWidget {
  const NumberLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Link Puzzle',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const NumberLinkGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NumberLinkGame extends StatefulWidget {
  const NumberLinkGame({super.key});

  @override
  State<NumberLinkGame> createState() => _NumberLinkGameState();
}

class _NumberLinkGameState extends State<NumberLinkGame> {
  late GameState gameState;
  String? selectedColor;
  bool isComplete = false;
  String message = '';
  List<GameState> statesHistory = [];
  Set<String> visitedStates = {};
  List<String> duplicateStates = [];

  final List<Color> colors = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFF45B7D1),
    const Color(0xFFFFA07A),
    const Color(0xFF98D8C8),
    const Color(0xFFF7DC6F),
  ];
  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  void initializeGame() {
    const size = 6;
    final colorPairs = [
      ColorPair(color: 'A', start: Position(0, 0), end: Position(0, 4)),
      ColorPair(color: 'B', start: Position(1, 0), end: Position(5, 5)),
      ColorPair(color: 'C', start: Position(2, 1), end: Position(2, 4)),
      ColorPair(color: 'D', start: Position(2, 0), end: Position(5, 2)),
    ];

    setState(() {
      gameState = GameState(size: size, colorPairs: colorPairs);
      statesHistory.clear();
      visitedStates.clear();
      statesHistory.add(gameState.copyState());
      visitedStates.add(gameState.getHashOfState());

      selectedColor = null;
      isComplete = false;
      message = 'Select a color to start connecting!';
    });

    gameState.printBoard();
  }

  void handleCellClick(int x, int y) {
    if (isComplete) return;

    final cell = gameState.board[y][x];

    // select a color by clicking its start point
    if (cell != null && cell.type == CellType.start) {
      setState(() {
        selectedColor = cell.color;
        gameState.updatePossibleMoves(selectedColor);
        message = 'Drawing path for color ${cell.color}';
      });
      return;
    }

    // no color selected -> ignore
    if (selectedColor == null) {
      setState(() {
        message = 'Please select a color first';
      });
      return;
    }

    // trying to make a move
    final newState = gameState.copyState();
    final result = newState.makePossibleMoves(x, y, selectedColor!);

    if (result.success) {
      final stateHash = newState.getHashOfState();
      if (visitedStates.contains(stateHash)) {
        duplicateStates.add(stateHash);
        log(stateHash);
        message = 'State already visited';
      } else {
        log(stateHash);
        visitedStates.add(stateHash);
        message = 'New state';
      }
      setState(() {
        gameState = newState;
        statesHistory.add(newState.copyState());

        // Check if this color is complete
        final pair = newState.colorPairs.firstWhere(
          (p) => p.color == selectedColor,
        );
        // log(pair.start.x.toString(), name: 'pair s x');
        // log(pair.start.y.toString(), name: 'pair s y');
        // log(pair.end.x.toString(), name: 'pair e x');
        // log(pair.end.y.toString(), name: 'pair e y');

        final path = newState.paths[selectedColor];
        final oldPos = path!.elementAt(path.length - 2);
        final newPos = path!.last;

        // log(newPos.x.toString(), name: 'newPos x');
        // log(newPos.y.toString(), name: 'newPos y');
        // validate if the solution is right
        if (newPos.x == pair.end.x &&
            newPos.y == pair.end.y &&
            (oldPos.x == path.last.x - 1 ||
                oldPos.x == path.last.x + 1 ||
                oldPos.y == path.last.y - 1 ||
                oldPos.y == path.last.y + 1)
        // && path.length > 1
        ) {
          message = 'Color $selectedColor completed! Select another color.';
          selectedColor = null;

          //  game is complete?
          if (newState.isFinalState()) {
            isComplete = true;
            message = '🎉 Puzzle Complete! All colors connected!';
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WinningStatesScreen(
                  winStates: visitedStates,
                  duplicateStates: duplicateStates,
                ),
              ),
            );
          }
        } else {
          gameState.updatePossibleMoves(selectedColor);
        }
      });

      gameState.printBoard();
    } else {
      setState(() {
        message = '❌ ${result.message}';
      });
    }
  }

  void handleUndo() {
    if (statesHistory.length > 1) {
      setState(() {
        statesHistory.removeLast();
        gameState = statesHistory.last.copyState();
        gameState.updatePossibleMoves(selectedColor);
        message = 'Undid last move';
      });
    }
  }

  void handleClearPath() {
    if (selectedColor == null) return;

    final newState = gameState.copyState();
    newState.clearPath(selectedColor!);
    setState(() {
      gameState = newState;
      gameState.updatePossibleMoves(selectedColor);
      message = 'Cleared path for color $selectedColor';
    });
    gameState.printBoard();
  }

  Color getColorForCell(String color) {
    final colorIndex = color.codeUnitAt(0) - 65;
    return colors[colorIndex % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE9D5FF), Color(0xFFDBEAFE)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Number Link Puzzle',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connect matching colors without crossing paths',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // status Message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isComplete
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isComplete
                              ? const Color(0xFF065F46)
                              : const Color(0xFF1E40AF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Color Selection
                    const Text(
                      'Select Color:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      runSpacing: 8,
                      children: gameState.colorPairs.map((pair) {
                        final isSelected = selectedColor == pair.color;
                        final path = gameState.paths[pair.color];
                        final isConnected =
                            path!.length > 1 &&
                            path.last.x == pair.end.x &&
                            path.last.y == pair.end.y;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Material(
                            color: getColorForCell(pair.color),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedColor = pair.color;
                                  gameState.updatePossibleMoves(pair.color);
                                  message =
                                      'Drawing path for color ${pair.color}';
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: isSelected
                                      ? Border.all(
                                          color: const Color(0xFF1F2937),
                                          width: 4,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        pair.color,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (isConnected)
                                        const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Game Board
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gameState.size,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: gameState.size * gameState.size,
                        itemBuilder: (context, index) {
                          final x = index % gameState.size;
                          final y = index ~/ gameState.size;
                          final cell = gameState.board[y][x];

                          final isPossibleMove = gameState.possibleMoves.any(
                            (p) => p.x == x && p.y == y,
                          );

                          return Material(
                            color: cell == null
                                ? Colors.white
                                : getColorForCell(cell.color).withOpacity(
                                    cell.type == CellType.path ? 0.6 : 1.0,
                                  ),
                            borderRadius: BorderRadius.circular(4),
                            child: InkWell(
                              onTap: () => handleCellClick(x, y),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: isPossibleMove
                                      ? Border.all(
                                          color: getColorForCell(
                                            selectedColor!,
                                          ),
                                          width: 6,
                                        )
                                      : cell != null &&
                                            (cell.type == CellType.start ||
                                                cell.type == CellType.end)
                                      ? Border.all(
                                          color: getColorForCell(cell.color),
                                          width: 3,
                                        )
                                      : cell != null
                                      ? Border.all(
                                          color: getColorForCell(cell.color),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child:
                                      cell != null &&
                                          (cell.type == CellType.start ||
                                              cell.type == CellType.end)
                                      ? Text(
                                          cell.color,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Controls
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: handleUndo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBBF24),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Undo Last',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: selectedColor != null
                              ? handleClearPath
                              : null,
                          icon: const Icon(Icons.close, size: 20),
                          label: const Text(
                            'Clear Path',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: initializeGame,
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text(
                            'New Game',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
