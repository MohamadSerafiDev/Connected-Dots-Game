# Number Link Game Logic Explained

This document provides a comprehensive explanation of the Number Link game's code, from its structure to its core logic.

## Introduction

The game is a classic Number Link puzzle. The objective is to connect pairs of matching colored dots on a grid by drawing paths between them. The paths cannot cross each other, and the entire grid must be filled to complete the puzzle.

## File Structure

The game's logic is contained within the `lib` directory. Here's a breakdown of each file:

-   `main.dart`: This is the main entry point of the application. It contains the UI for the game board, handles user interactions, and manages the overall game flow.
-   `game_state.dart`: This is the heart of the game's logic. The `GameState` class represents the state of the game at any given moment, including the board, the paths of the colors, and the color pairs to be connected.
-   `cell.dart`: This file defines the `Cell` class, which represents a single cell on the game board. A cell has a `color` and a `type` (start, end, or path).
-   `color_pair.dart`: This class represents a pair of colors to be connected. It contains the `color` and the `start` and `end` positions on the grid.
-   `position.dart`: A simple class to represent a position on the grid with `x` and `y` coordinates.
-   `move_result.dart`: A class that represents the result of a move, indicating whether it was successful and providing a message if it failed.
-   `winning_states_screen.dart`: This screen is displayed when the game is won. It shows a list of all the unique states the player went through to solve the puzzle.

## Game Initialization

The game is initialized in the `_NumberLinkGameState`'s `initializeGame` method in `main.dart`. Here's what happens:

1.  **Grid Size and Color Pairs:** The size of the grid and the color pairs (with their start and end positions) are defined.
2.  **`GameState` Creation:** A new `GameState` object is created with the specified size and color pairs.
3.  **State Tracking:**
    -   A `statesHistory` list is created to store each state of the game, allowing for the "Undo" functionality.
    -   A `visitedStates` set is created to store a unique hash of each visited state. This is used to detect if a player has returned to a previous state.
4.  **UI Reset:** The UI is reset to its initial state, with no color selected and a welcome message.

## Game Play and Logic

### Handling User Input

User input is handled by the `handleCellClick` method in `main.dart`. When a user taps a cell on the grid, this method is called with the `x` and `y` coordinates of the cell.

### Selecting a Color

-   If the tapped cell is a "start" point of a color, that color is selected as the `selectedColor`. The UI is updated to indicate the selected color.

### Making a Move

-   If a color is already selected, the game attempts to make a move to the tapped cell.
-   A copy of the current `GameState` is created to represent the new state after the move.
-g   The `makeMove` method in `GameState` is called with the coordinates of the tapped cell and the `selectedColor`.

### Pathfinding and Validation in `makeMove`

The `makeMove` method in `game_state.dart` is responsible for validating and applying a move. Here's how it works:

1.  **Adjacency Check:** It first checks if the tapped cell is directly adjacent (top, bottom, left, or right) to the last cell of the current color's path. If not, the move is invalid.
2.  **Cell Occupancy:** It then checks if the tapped cell is already occupied by another path. If so, the move is invalid.
3.  **End Point:** If the tapped cell is an "end" point, it checks if it's the end point for the *same* color. If it's for a different color, the move is invalid.
4.  **Applying the Move:** If the move is valid, the new position is added to the color's path, and the cell on the board is updated to be a "path" cell.

### State Tracking

-   After a successful move, a unique hash of the new game state is generated using the `getHashOfState` method in `GameState`.
-   This hash is checked against the `visitedStates` set.
    -   If the hash is already in the set, the `message` is updated to "State already visited".
    -   If it's a new hash, it's added to the set, and the `message` is updated to "New state".
-   The new `GameState` is added to the `statesHistory` list.

## Winning the Game

### Checking for the Win Condition

-   After each successful move that completes a color's path, the `isFinalState` method in `GameState` is called.
-   This method checks if all color pairs have been successfully connected (i.e., their paths start at the `start` position and end at the `end` position).
-   It also checks if the entire board is filled.

### Displaying the Winning States

-   If `isFinalState` returns `true`, the game is won.
-   The `isComplete` flag is set to `true`, and a success message is displayed.
-   The app then navigates to the `WinningStatesScreen`, passing the list of visited state hashes. This screen displays each unique state hash in a list.

## Other Features

### Undo Functionality

-   The `handleUndo` method in `main.dart` allows the user to undo their last move.
-   It removes the last state from the `statesHistory` list and sets the current `gameState` to the new last state in the history.

### Clearing a Path

-   The `handleClearPath` method in `main.dart` allows the user to clear the entire path for the currently `selectedColor`.
-   It calls the `clearPath` method in `GameState`, which removes all "path" cells for that color from the board and resets the color's path to just the start position.
