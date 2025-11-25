import 'package:flutter/material.dart';

class WinningStatesScreen extends StatelessWidget {
  final Set<String> winStates;
  final List<String> duplicateStates;

  const WinningStatesScreen({
    super.key,
    required this.winStates,
    required this.duplicateStates,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Winning Path')),
      body: ListView.builder(
        itemCount: winStates.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              tileColor: duplicateStates.contains(winStates.toList()[index])
                  ? Colors.red[100]
                  : Colors.greenAccent[100],
              title: Text('State ${index + 1}'),
              subtitle: Text(winStates.toList()[index]),
            ),
          );
        },
      ),
    );
  }
}
