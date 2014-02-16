import de.looksgood.ani.*;

// Size of cells
int cellSize = 20;

// How likely for a cell to be alive at start (in percentage)
float probabilityOfAliveAtStart = 15;

// Variables for timer
int interval = 100;
int lastRecordedTime = 0;

final int DEAD = 0;
final int DYING = 1;
final int BIRTH = 2;
final int ALIVE = 3;

// Colors for active/inactive cells
color aliveColor = color(0, 200, 0);
color birthColor = color(0, 100, 0);
color dyingColor = color(30, 30, 30);
color deadColor = color(0);

// Array of cells
Cell[][] cells; 
// Buffer to record the state of the cells and use this while changing the others in the interations
Cell[][] cellsBuffer; 

// Pause
boolean pause = false;

class Cell {
 int xpos, ypos, state, diameter;
 Cell (int x, int y, int s) {
   xpos = x;
   ypos = y;
   state = s;
   diameter = cellSize;
 }
 void draw() {
  switch (state) {
    case DEAD:
      fill(deadColor);
      break;
    case DYING:
      fill(dyingColor);
      break;
    case BIRTH:
      fill(birthColor);
      break;
    case ALIVE:
      fill(aliveColor);
      break;
    }
    ellipse(xpos*cellSize+cellSize/2, ypos*cellSize+cellSize/2, diameter, diameter); 
 }
 
}

void setup() {
  size (1280, 720);

   Ani.init(this);
   Ani.setDefaultEasing(Ani.BACK_IN_OUT);

  // Instantiate arrays 
  cells = new Cell[width/cellSize][height/cellSize];
  cellsBuffer = new Cell[width/cellSize][height/cellSize];

  // This stroke will draw the background grid
  stroke(48);
  smooth();

  // Initialization of cells
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      float state = random (100);
      //cells[x][y] = (state > probabilityOfAliveAtStart) ? DEAD : ALIVE;
      cells[x][y] = new Cell(x, y, (state > probabilityOfAliveAtStart) ? DEAD : ALIVE);
      cellsBuffer[x][y] = new Cell(x, y, DEAD);
    }
  } 
  background(0); // Fill in black in case cells don't cover all the windows
}


void draw() {

  //Draw grid
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      cells[x][y].draw();
    }
  }
  // Iterate if timer ticks
  if (millis()-lastRecordedTime>interval) {
    if (!pause) {
      iteration();
      lastRecordedTime = millis();
    }
  }

  // Create  new cells manually on pause
  if (pause && mousePressed) {
    // Map and avoid out of bound errors
    int xCellOver = int(map(mouseX, 0, width, 0, width/cellSize));
    xCellOver = constrain(xCellOver, 0, width/cellSize-1);
    int yCellOver = int(map(mouseY, 0, height, 0, height/cellSize));
    yCellOver = constrain(yCellOver, 0, height/cellSize-1);

    // Check against cells in buffer
    if (cellsBuffer[xCellOver][yCellOver].state >= BIRTH) { // Cell is alive
      cells[xCellOver][yCellOver].state =DEAD; // Kill
      fill(deadColor); // Fill with kill color
    } else { // Cell is dead
      cells[xCellOver][yCellOver].state = ALIVE; // Make alive
      fill(aliveColor); // Fill alive color
    }
  } 
  else if (pause && !mousePressed) { // And then save to buffer once mouse goes up
    // Save cells to buffer (so we opeate with one array keeping the other intact)
    for (int x=0; x<width/cellSize; x++) {
      for (int y=0; y<height/cellSize; y++) {
        cellsBuffer[x][y].state = cells[x][y].state;
      }
    }
  }
}



void iteration() { // When the clock ticks
  // Save cells to buffer (so we opeate with one array keeping the other intact)
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      cellsBuffer[x][y].state = cells[x][y].state;
    }
  }

  // Visit each cell:
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      // And visit all the neighbours of each cell
      int neighbours = 0; // We'll count the neighbours
      for (int xx=x-1; xx<=x+1;xx++) {
        for (int yy=y-1; yy<=y+1;yy++) {  
          if (((xx>=0)&&(xx<width/cellSize))&&((yy>=0)&&(yy<height/cellSize))) { // Make sure you are not out of bounds
            if (!((xx==x)&&(yy==y))) { // Make sure to to check against self
              if (cellsBuffer[xx][yy].state >= BIRTH){
                neighbours ++; // Check alive neighbours and count them
              }
            } // End of if
          } // End of if
        } // End of yy loop
      } //End of xx loop
      // We've checked the neigbours: apply rules!
      if (cellsBuffer[x][y].state >=BIRTH) { // The cell is alive: kill it if necessary
        if (neighbours < 2 || neighbours > 3) {
          cells[x][y].state = DYING; // Die unless it has 2 or 3 neighbours
        } else {
          cells[x][y].state = ALIVE; // upgrade birthed cells to fully alive
        }
      } 
      else { // The cell is dying or dead: make it live if necessary      
        if (neighbours == 3 ) {
          cells[x][y].state = BIRTH; // Only if it has 3 neighbours
        } else {
          cells[x][y].state = DEAD; // upgrade dying cells to fully dead
        }
      } // End of if
    } // End of y loop
  } // End of x loop
  
/*  
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      if (cells[x][y].state >= BIRTH) {
        Ani.to(cells[x][y], interval/2, "diameter", cellSize);
      } else {
        Ani.from(cells[x][y], interval/2, "diameter", 0);   
      }     
    }
  }
*/
  
} // End of function

void keyPressed() {
  if (key=='r' || key == 'R') {
    // Restart: reinitialization of cells
    for (int x=0; x<width/cellSize; x++) {
      for (int y=0; y<height/cellSize; y++) {
        float state = random (100);
        cells[x][y].state = (state > probabilityOfAliveAtStart) ? DEAD : ALIVE;
      }
    }
  }
  if (key==' ') { // On/off of pause
    pause = !pause;
  }
  if (key=='c' || key == 'C') { // Clear all
    for (int x=0; x<width/cellSize; x++) {
      for (int y=0; y<height/cellSize; y++) {
        cells[x][y].state = DEAD; // Save all to zero
      }
    }
  }
}

