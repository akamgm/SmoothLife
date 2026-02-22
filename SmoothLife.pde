import de.looksgood.ani.*;

// Configuration
int cellSize = 25;
int boardCols = 48; // Set to 0 to auto-fit window
int boardRows = 32; // Set to 0 to auto-fit window
boolean torusBoard = true; // If true, edges wrap around
float probabilityOfAliveAtStart = 15;
float generationDuration = 3.0; // Seconds per generation
float generationStartTime = 0; // millis() when current generation began

// State constants
final int DEAD = 0;
final int BIRTH = 1;
final int ALIVE = 2;
final int DYING = 3;

// Colors
color aliveColor = color(100, 255, 150);
color birthColor = color(50, 200, 100);
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

  // Organic blob shape: per-cell random angular offsets and radii
  int blobPoints = 8;
  float[] blobAngleOffset = new float[blobPoints];
  float[] blobRadiusMult  = new float[blobPoints]; // multipliers around 1.0

  // For "oozing" effect
  ArrayList<PVector> parents = new ArrayList<PVector>();

  Cell(int x, int y) {
    this.x = x;
    this.y = y;
    // Generate stable per-cell shape noise
    for (int k = 0; k < blobPoints; k++) {
      blobAngleOffset[k] = random(-0.25, 0.25);   // slight angular jitter
      blobRadiusMult[k]  = random(0.72, 1.15);    // radius varies per lobe
    }
  }

  void updateState() {
    state = nextState;
  }

  void triggerAnimations() {
    // Animations fill the full generation duration — no buffer gap
    float duration = generationDuration;

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
      // Shrink and fade (keep current color — don't change it)
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
    else fill(aliveColor, opacity); // DYING uses aliveColor — just shrinks and fades

    // Organic blob using closed Catmull-Rom curve through jittered radial points
    float baseR = diameter * 0.5;
    // Slow per-cell breathing wobble
    float breathe = sin(frameCount * 0.04 + x * 0.7 + y * 1.1) * 0.06;
    beginShape();
    for (int k = 0; k < blobPoints + 3; k++) {
      int idx = k % blobPoints;
      float angle = TWO_PI * idx / blobPoints + blobAngleOffset[idx];
      float r = baseR * blobRadiusMult[idx] * (1.0 + breathe);
      curveVertex(cos(angle) * r, sin(angle) * r);
    }
    endShape(CLOSE);

    popMatrix();
  }
}

void setup() {
  size(1200, 800);
  frameRate(60);

  Ani.init(this);

  cols = (boardCols > 0) ? boardCols : width / cellSize;
  rows = (boardRows > 0) ? boardRows : height / cellSize;
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

  // Compute the first generation immediately and start animating
  iteration();
  generationStartTime = millis();
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

  // Advance generation exactly when the current animation period ends
  if (!pause && millis() - generationStartTime >= generationDuration * 1000) {
    generationStartTime += generationDuration * 1000; // Step forward, not reset — prevents drift
    iteration();
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

      int col, row;
      if (torusBoard) {
        col = (x + i + cols) % cols;
        row = (y + j + rows) % rows;
      } else {
        col = x + i;
        row = y + j;
        if (col < 0 || col >= cols || row < 0 || row >= rows) continue;
      }

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

      int col, row;
      if (torusBoard) {
        col = (x + i + cols) % cols;
        row = (y + j + rows) % rows;
      } else {
        col = x + i;
        row = y + j;
        if (col < 0 || col >= cols || row < 0 || row >= rows) continue;
      }

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
  if (key == '+' || key == '=') {
    generationDuration = max(0.5, generationDuration - 0.5);
    generationStartTime = millis(); // Restart current period at new duration
  }
  if (key == '-' || key == '_') {
    generationDuration += 0.5;
    generationStartTime = millis(); // Restart current period at new duration
  }
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
  iteration();
  generationStartTime = millis();
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
