import de.looksgood.ani.*;

// Configuration
int cellSize = 25;
float probabilityOfAliveAtStart = 15;
float generationDuration = 3.0; // Seconds per generation
int lastRecordedTime = 0;

// State constants
final int DEAD = 0;
final int BIRTH = 1;
final int ALIVE = 2;
final int DYING = 3;

// Colors
color aliveColor = color(100, 255, 150);
color birthColor = color(50, 200, 100);
color dyingColor = color(150, 100, 50);
color deadColor = color(20, 20, 25);

// Simulation grid
Cell[][] cells;
int cols, rows;

// UI/State
boolean pause = false;

class Cell {
  int x, y;
  int state = DEAD;
  int nextState = DEAD;
  float diameter = 0;
  float opacity = 0;
  float offsetX = 0;
  float offsetY = 0;

  // For "oozing" effect
  ArrayList<PVector> parents = new ArrayList<PVector>();

  Cell(int x, int y) {
    this.x = x;
    this.y = y;
  }

  void updateState() {
    state = nextState;
  }

  void triggerAnimations() {
    float duration = generationDuration * 0.9; // Leave a small buffer

    if (state == BIRTH) {
      // Ooze in from parents
      diameter = 0;
      opacity = 0;

      // Pick a random parent to "ooze" from if available
      if (parents.size() > 0) {
        PVector p = parents.get(int(random(parents.size())));
        offsetX = (p.x - x) * cellSize;
        offsetY = (p.y - y) * cellSize;
        Ani.to(this, duration, "offsetX", 0, Ani.EXPO_OUT);
        Ani.to(this, duration, "offsetY", 0, Ani.EXPO_OUT);
      }

      Ani.to(this, duration, "diameter", cellSize * 0.8, Ani.ELASTIC_OUT);
      Ani.to(this, duration, "opacity", 255, Ani.LINEAR);
    }
    else if (state == DYING) {
      // Evaporate
      Ani.to(this, duration, "diameter", 0, Ani.EXPO_IN);
      Ani.to(this, duration, "opacity", 0, Ani.LINEAR);
      Ani.to(this, duration, "offsetY", -cellSize * 0.5, Ani.QUAD_IN); // Float up slightly
    }
    else if (state == ALIVE) {
      // Keep solid
      diameter = cellSize * 0.8;
      opacity = 255;
      offsetX = 0;
      offsetY = 0;
    }
    else {
      // Dead
      diameter = 0;
      opacity = 0;
    }
  }

  void draw() {
    if (opacity <= 0 && state == DEAD) return;

    pushMatrix();
    translate(x * cellSize + cellSize/2 + offsetX, y * cellSize + cellSize/2 + offsetY);

    noStroke();
    if (state == BIRTH) fill(birthColor, opacity);
    else if (state == DYING) fill(dyingColor, opacity);
    else fill(aliveColor, opacity);

    // Blob shape (slightly irregular ellipse)
    float pulse = sin(frameCount * 0.05 + (x + y)) * 2;
    ellipse(0, 0, diameter + pulse, diameter - pulse);

    popMatrix();
  }
}

void setup() {
  size(1200, 800);
  frameRate(60);

  Ani.init(this);

  cols = width / cellSize;
  rows = height / cellSize;
  cells = new Cell[cols][rows];

  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      cells[i][j] = new Cell(i, j);
      if (random(100) < probabilityOfAliveAtStart) {
        cells[i][j].state = ALIVE;
        cells[i][j].diameter = cellSize * 0.8;
        cells[i][j].opacity = 255;
      }
    }
  }

  lastRecordedTime = millis();
}

void draw() {
  background(deadColor);

  // Draw grid subtle
  stroke(30, 30, 40);
  for (int i = 0; i <= width; i += cellSize) line(i, 0, i, height);
  for (int j = 0; j <= height; j += cellSize) line(0, j, width, j);

  // Update and draw cells
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      cells[i][j].draw();
    }
  }

  // Timer for logic
  if (!pause && millis() - lastRecordedTime > generationDuration * 1000) {
    iteration();
    lastRecordedTime = millis();
  }

  // UI Info
  fill(255, 150);
  text("Generation Time: " + nf(generationDuration, 1, 1) + "s (Use +/- to change)", 20, 30);
  text("Space: Pause | R: Reset | C: Clear", 20, 50);
}

void iteration() {
  // 1. Calculate next states based on current states
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      int neighbors = countNeighbors(i, j);
      Cell c = cells[i][j];

      c.parents.clear();

      if (c.state == ALIVE || c.state == BIRTH) {
        if (neighbors < 2 || neighbors > 3) {
          c.nextState = DYING;
        } else {
          c.nextState = ALIVE;
        }
      } else {
        if (neighbors == 3) {
          c.nextState = BIRTH;
          // Find parents for oozing effect
          findParents(i, j);
        } else {
          c.nextState = DEAD;
        }
      }
    }
  }

  // 2. Apply states and trigger animations
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      cells[i][j].updateState();
      cells[i][j].triggerAnimations();
    }
  }
}

int countNeighbors(int x, int y) {
  int count = 0;
  for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <= 1; j++) {
      if (i == 0 && j == 0) continue;

      int col = (x + i + cols) % cols;
      int row = (y + j + rows) % rows;

      if (cells[col][row].state == ALIVE || cells[col][row].state == BIRTH) {
        count++;
      }
    }
  }
  return count;
}

void findParents(int x, int y) {
  for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <= 1; j++) {
      if (i == 0 && j == 0) continue;

      int col = (x + i + cols) % cols;
      int row = (y + j + rows) % rows;

      if (cells[col][row].state == ALIVE || cells[col][row].state == BIRTH) {
        cells[x][y].parents.add(new PVector(col, row));
      }
    }
  }
}

void keyPressed() {
  if (key == ' ') pause = !pause;
  if (key == 'r' || key == 'R') reset();
  if (key == 'c' || key == 'C') clearGrid();
  if (key == '+' || key == '=') generationDuration = max(0.1, generationDuration - 0.5);
  if (key == '-' || key == '_') generationDuration += 0.5;
}

void reset() {
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      if (random(100) < probabilityOfAliveAtStart) {
        cells[i][j].state = ALIVE;
        cells[i][j].diameter = cellSize * 0.8;
        cells[i][j].opacity = 255;
      } else {
        cells[i][j].state = DEAD;
        cells[i][j].diameter = 0;
        cells[i][j].opacity = 0;
      }
      cells[i][j].offsetX = 0;
      cells[i][j].offsetY = 0;
    }
  }
}

void clearGrid() {
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      cells[i][j].state = DEAD;
      cells[i][j].diameter = 0;
      cells[i][j].opacity = 0;
    }
  }
}

void mousePressed() {
  int i = mouseX / cellSize;
  int j = mouseY / cellSize;
  if (i >= 0 && i < cols && j >= 0 && j < rows) {
    if (cells[i][j].state == DEAD) {
      cells[i][j].state = ALIVE;
      cells[i][j].diameter = cellSize * 0.8;
      cells[i][j].opacity = 255;
    } else {
      cells[i][j].state = DEAD;
      cells[i][j].diameter = 0;
      cells[i][j].opacity = 0;
    }
  }
}
