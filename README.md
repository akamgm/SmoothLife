# SmoothLife

A visually smooth version of Conway's Game of Life implemented in Processing.

This version moves away from the rigid, grid-based flashing of traditional Game of Life and focuses on organic, fluid transitions.

## Key Features

- **Oozing Birth**: New cells don't just appear; they "ooze" into existence from one of their neighboring parent cells.
- **Evaporating Death**: Dying cells slowly shrink and float upwards, giving the appearance of evaporation.
- **Organic Blobs**: Cells are rendered as pulsating blobs rather than simple squares.
- **Variable Speed**: The time it takes for a generation to transition is variable (defaulting to 3 seconds).

## Controls

- **Space**: Pause/Resume simulation.
- **R**: Reset the grid with random cells.
- **C**: Clear the grid.
- **+ / =**: Speed up (decrease generation time).
- **- / _**: Slow down (increase generation time).
- **Mouse Click**: Toggle cell state manually.

## Dependencies

This project uses the **Ani** library for Processing to handle smooth animations and easings.