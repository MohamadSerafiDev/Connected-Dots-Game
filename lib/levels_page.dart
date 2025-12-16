import 'package:dot_connec_project/game_state.dart';
import 'package:dot_connec_project/main.dart';
import 'package:flutter/material.dart';

class LevelsPage extends StatelessWidget {
  final List<GameState> levels;

  const LevelsPage({super.key, required this.levels});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generated Levels')),
      body: ListView.builder(
        itemCount: levels.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Level ${index + 1}'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NumberLinkGame(
                    initialGameState: levels[index],
                    isGeneratePage: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
