import 'dart:developer' as dev;
import 'dart:math';

import 'package:dot_connec_project/cell.dart';
import 'package:dot_connec_project/color_pair.dart';
import 'package:dot_connec_project/game_state.dart';
import 'package:dot_connec_project/levels_page.dart';
import 'package:dot_connec_project/position.dart';
import 'package:dot_connec_project/winning_states_screen.dart';
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
  final GameState? initialGameState;
  final bool? isGeneratePage;
  const NumberLinkGame({super.key, this.initialGameState, this.isGeneratePage});

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
    const Color.fromARGB(255, 170, 124, 235),
    const Color(0xFFF7DC6F),
  ];
  // A simple static weights grid (6x6) used for UCS runs.
  // Lower numbers are cheaper; this is intentionally uniform.
  final List<List<int>> simpleWeights = const [
    [1, 2, 1, 1, 10],
    // [1, 1, 1, 1, 10],
    // [1, 1, 1, 1, 10],
    // [1, 1, 1, 1, 10],
    // [1, 1, 1, 1, 10],
    [2, 1, 1, 1, 10],
    [0, 1, 1, 1, 10],
    [1, 2, 2, 1, 10],
    [1, 1, 1, 1, 10],
  ];
  @override
  void initState() {
    super.initState();
    if (widget.initialGameState != null) {
      gameState = widget.initialGameState!;
      statesHistory.add(gameState.copyState());
      visitedStates.add(gameState.getHashOfState());
      selectedColor = null;
      isComplete = false;
      message = 'Select a color to start connecting!';
    } else {
      initializeGame();
    }
  }

  void initializeGame() {
    //solvable with HC
    // int size = 4;
    // List<ColorPair> colorPairs = [
    //   ColorPair(color: 'A', start: Position(0, 0), end: Position(2, 3)),

    //   ColorPair(color: 'B', start: Position(3, 2), end: Position(3, 3)),
    // ];
    const size = 5;
    final colorPairs = [
      ColorPair(color: 'A', start: Position(1, 0), end: Position(1, 2)),
      ColorPair(color: 'B', start: Position(2, 0), end: Position(0, 3)),
      ColorPair(color: 'C', start: Position(1, 1), end: Position(2, 2)),
      // ColorPair(color: 'D', start: Position(2, 0), end: Position(4, 2)),
      // ColorPair(color: 'E', start: Position(2, 5), end: Position(6, 1)),
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

  Future<void> generateLevels() async {
    setState(() {
      message = 'Generating levels...';
    });

    final List<GameState> levels = [];
    const int gridSize = 5;
    final random = Random();

    for (int i = 0; i < 5; i++) {
      late GameState newGameState;
      bool isSolvable = false;

      while (!isSolvable) {
        final List<Position> usedPositions = [];
        final List<ColorPair> colorPairs = [];

        for (int j = 0; j < 3; j++) {
          late Position start, end;
          do {
            start = Position(
              random.nextInt(gridSize),
              random.nextInt(gridSize),
            );
            dev.log(start.toString(), name: 'start');
          } while (usedPositions.any((p) => p.x == start.x && p.y == start.y));
          dev.log(usedPositions.toString(), name: 'used positions');
          usedPositions.add(start);

          do {
            end = Position(random.nextInt(gridSize), random.nextInt(gridSize));
          } while (usedPositions.any((p) => p.x == end.x && p.y == end.y) ||
              (start.x - end.x).abs() + (start.y - end.y).abs() <= 2);
          usedPositions.add(end);

          colorPairs.add(
            ColorPair(
              color: String.fromCharCode(65 + j),
              start: start,
              end: end,
            ),
          );
        }

        newGameState = GameState(size: gridSize, colorPairs: colorPairs);
        final solution = await newGameState.solveWithDFS().last;
        if (solution.isFinalState()) {
          isSolvable = true;
        }
      }
      levels.add(newGameState);
    }

    setState(() {
      message = 'Levels generated!';
    });

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => LevelsPage(levels: levels)));
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
        dev.log(stateHash);
        message = 'State already visited';
      } else {
        dev.log(stateHash);
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

  Future<void> handleDfsSolve() async {
    setState(() {
      message = 'Solving...';
    });
    final solution = await gameState.solveWithDFS().last;
    if (solution.isFinalState()) {
      setState(() {
        dev.log('solved!!');
        gameState = solution;
        isComplete = true;
        message = 'Solved!';
      });
    } else {
      setState(() {
        message = 'No solution found.';
      });
    }
  }

  Future<void> visualizeDFS() async {
    setState(() {
      message = 'visualizing DFS...';
    });
    var numSearches = 0;
    await for (final state in gameState.solveWithDFS()) {
      setState(() {
        gameState = state;
      });
      numSearches++;
      await Future.delayed(const Duration(milliseconds: 50));
    }
    setState(() {
      message = 'Visualization complete, searches: ${numSearches.toString()}';
    });
  }

  Future<void> visualizeBFS() async {
    setState(() {
      message = 'visualizing BFS...';
    });
    var numSearches = 0;
    await for (final state in gameState.solveWithBFS()) {
      setState(() {
        gameState = state;
      });
      numSearches++;
      await Future.delayed(const Duration(milliseconds: 20));
    }
    setState(() {
      message = 'Visualization complete, searches: ${numSearches.toString()}';
    });
  }

  Future<void> visualizeUCS([List<List<int>>? weights]) async {
    setState(() {
      message = 'visualizing UCS...';
    });

    final w =
        weights ??
        List.generate(gameState.size, (_) => List.filled(gameState.size, 1));

    var numSearches = 0;
    await for (final state in gameState.solveWithUCS(w)) {
      setState(() {
        gameState = state;
      });
      numSearches++;
      await Future.delayed(const Duration(milliseconds: 50));
    }

    setState(() {
      message = 'Visualization complete, searches: ${numSearches.toString()}';
    });
  }

  Future<void> handleSolveWithUCS([List<List<int>>? weights]) async {
    setState(() {
      message = 'Solving with UCS...';
    });

    final w =
        weights ??
        List.generate(gameState.size, (_) => List.filled(gameState.size, 1));

    final solution = await gameState.solveWithUCS(w).last;
    if (solution.isFinalState()) {
      setState(() {
        dev.log('solved with UCS!!');
        gameState = solution;
        isComplete = true;
        message = 'Solved with UCS!';
      });
    } else {
      setState(() {
        message = 'No solution found with UCS.';
      });
    }
  }

  Future<void> handleSolveWithHillClimbing() async {
    setState(() => message = 'Solving with Hill Climbing...');

    // Attempt to get the last state yielded by the stream
    final solution = await gameState.solveWithHillClimbing().last;

    // --- CODE TO ANSWER YOUR QUESTION ---
    // 1. Get a unique representation (hash) of the last state.
    String lastStateHash = solution.getHashOfState();
    // 2. Check if this last state is the final/solved state.
    bool isFinal = solution.isFinalState();

    // Print the results to the debug console
    dev.log(
      'Last State Hash Reached by Hill Climbing: $lastStateHash',
      name: 'HillClimbingResult',
    );
    dev.log(
      'Is the Last State the Final State (Solved)? $isFinal',
      name: 'HillClimbingResult',
    );
    // ------------------------------------

    if (solution.isFinalState()) {
      setState(() {
        gameState = solution;
        isComplete = true;
        message = 'Solved with Hill Climbing!';
      });
    } else {
      setState(() {
        gameState = solution; // Show where it got stuck
        message = 'Hill Climbing Stuck (Local Max)!';
      });
    }
  }

  Future<void> visualizeHillClimbing() async {
    setState(() => message = 'Visualizing Hill Climbing...');
    var steps = 0;
    await for (final state in gameState.solveWithHillClimbing()) {
      setState(() => gameState = state);
      steps++;
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Slower delay to see decisions
    }
    setState(() => message = 'Hill Climbing ended. Steps: $steps');
  }

  Future<void> handleSolveWithAStar() async {
    setState(() => message = 'Solving with A*...');
    // Uses simpleWeights (UCS weights) for G cost
    final solution = await gameState.solveWithAStar(simpleWeights).last;

    if (solution.isFinalState()) {
      setState(() {
        gameState = solution;
        isComplete = true;
        message = 'Solved with A*!';
      });
    } else {
      setState(() => message = 'No solution found with A*.');
    }
  }

  Future<void> visualizeAStar() async {
    setState(() => message = 'Visualizing A*...');
    var searches = 0;
    await for (final state in gameState.solveWithAStar(simpleWeights)) {
      setState(() => gameState = state);
      searches++;
      await Future.delayed(
        const Duration(milliseconds: 20),
      ); // Fast to show search spread
    }
    setState(() => message = 'A* Complete. Searches: $searches');
  }

  Color getColorForCell(String color) {
    final colorIndex = color.codeUnitAt(0) - 65;
    return colors[colorIndex % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 202, 162, 255),
        toolbarHeight: 24,
      ),
      body: SingleChildScrollView(
        child: Container(
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
                          widget.isGeneratePage == null
                              ? ElevatedButton.icon(
                                  onPressed: generateLevels,
                                  icon: const Icon(
                                    Icons.auto_awesome,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'Generate Levels',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                )
                              : SizedBox(),
                          ElevatedButton.icon(
                            onPressed: () async {
                              dev.log('start solving');
                              await handleDfsSolve();
                            },
                            icon: const Icon(Icons.auto_awesome, size: 20),
                            label: const Text(
                              'Solve with DFS',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: visualizeDFS,
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: const Text(
                              'Visualize DFS',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigoAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: visualizeBFS,
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: const Text(
                              'Visualize BFS',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await handleSolveWithUCS(simpleWeights);
                            },
                            icon: const Icon(Icons.auto_awesome, size: 20),
                            label: const Text(
                              'Solve with UCS',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => visualizeUCS(simpleWeights),
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: const Text(
                              'Visualize UCS',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          // ... existing UCS buttons ...

                          // --- HILL CLIMBING BUTTONS ---
                          ElevatedButton.icon(
                            onPressed: handleSolveWithHillClimbing,
                            icon: const Icon(Icons.terrain, size: 20),
                            label: const Text(
                              'Solve Hill Climb',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: visualizeHillClimbing,
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: const Text(
                              'Visualize HC',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown[300],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          // --- A* BUTTONS ---
                          ElevatedButton.icon(
                            onPressed: handleSolveWithAStar,
                            icon: const Icon(Icons.star, size: 20),
                            label: const Text(
                              'Solve A*',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: visualizeAStar,
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: const Text(
                              'Visualize A*',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
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
      ),
    );
  }
}
