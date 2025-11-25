# How the DFS Algorithm Works

This document explains the step-by-step process of the Depth-First Search (DFS) algorithm used to solve the Number Link puzzle in this application.

## 1. Initialization

- **Randomize Color Pairs:** The algorithm begins by shuffling the list of color pairs. This is to ensure that the algorithm doesn't always try to solve the colors in the same order, which can be inefficient for some puzzle layouts.

- **Initialize the Stack:** A stack is created to store the states of the game to be explored. Each element in the stack is a tuple containing:
    - `GameState`: A snapshot of the game board, including the paths of the colors.
    - `pairIndex`: The index of the color pair that the algorithm is currently trying to connect.

- **Initialize the Visited Set:** A set is created to store the hash of the game states that have already been visited. This is to prevent the algorithm from getting stuck in a loop by exploring the same states over and over again. The hash is a unique string representation of the game board, and it is combined with the `pairIndex` to make the visited state unique to the current color being solved.

## 2. The Main Loop

The algorithm then enters a loop that continues as long as the stack is not empty. In each iteration of the loop, the algorithm does the following:

1.  **Pop a State:** It pops a state from the top of the stack. This state contains the current game board and the index of the color pair to be solved.

2.  **Check for Solution:** It checks if all color pairs have been connected. If they have, the algorithm has found a solution, and it returns the current game state.

3.  **Explore Possible Moves:** If a solution has not been found yet, the algorithm gets the current color pair to be solved and finds all the possible moves for that color.

## 3. Exploring Possible Moves

For each possible move, the algorithm does the following:

1.  **Create a New State:** It creates a copy of the current game state and applies the move to it.

2.  **Check for Path Completion:** It checks if the move completes the path for the current color.
    - If the path is complete, the `pairIndex` is incremented to move to the next color.
    - If the path is not complete, the `pairIndex` remains the same.

3.  **Check if Visited:** It calculates the hash of the new state and checks if it has already been visited.
    - If the new state has not been visited, it is added to the visited set and pushed onto the stack to be explored later.
    - If the new state has been visited, it is discarded.

## 4. Backtracking

If the algorithm reaches a state where there are no more possible moves for the current color, it means that the current path is a dead end. In this case, the algorithm simply moves to the next state in the stack, effectively "backtracking" to a previous state to explore a different path.

## 5. Termination

The algorithm terminates when one of the following conditions is met:

- **Solution Found:** A solution is found, and the algorithm returns the final game state.
- **Stack is Empty:** The stack becomes empty, which means that all possible states have been explored, and no solution was found. In this case, the algorithm returns `null`.