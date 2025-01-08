import g4p_controls.*;
import processing.serial.*;
import java.awt.Font;

Serial myPort;

// Data arrays
int maxIterations = 200;
float[] rssi = new float[maxIterations];
float[] filteredRSSI = new float[maxIterations];
String[] distances = new String[maxIterations];

int currentIndex = 0;

// Scrollable text area
GTextArea textArea;

void setup() {
  size(1800, 900);
  background(255);

  // Initialize serial communication
  println(Serial.list());
  String portName = "COM15"; // Ganti dengan port yang sesuai
  myPort = new Serial(this, portName, 115200);
  myPort.clear();

  // Create a scrollable text area for distance values
  //textArea = new GTextArea(this, 50, 450, 900, 300);
  //textArea.setOpaque(true);
  
  //// Apply font style
  //Font font = new Font("Arial", Font.PLAIN, 12); 
  //textArea.setFont(font);
  //textArea.setTextEditEnabled(false); // Read-only
}

void draw() {
  background(255);

  // Draw RSSI and filtered RSSI line graphs
  drawAxes();
  plotLine(rssi, color(255, 0, 0), "RSSI (Red)");
  plotLine(filteredRSSI, color(0, 0, 255), "Filtered RSSI (Blue)");

  drawLegendRSSI();

  // Update text area with distance values
  //updateDistanceText();
  displayDistances();
}

void serialEvent(Serial myPort) {
  String data = myPort.readStringUntil('\n');
  if (data != null) {
    data = trim(data);
    println("Data from ESP32: " + data);
    String[] values = split(data, ',');

    if (values.length >= 5) {
      try {
        float val0 = float(values[0]);  // RSSI value
        float val1 = float(values[1]);  // Filtered RSSI value
        // Only use the numeric part for distances, skip the last value (which is "aktif")
        String val2 = values[4]; // Distance is a string like "aktif"

        // Store RSSI and filtered RSSI
        if (currentIndex < maxIterations) {
          rssi[currentIndex] = val0;
          filteredRSSI[currentIndex] = val1;
          distances[currentIndex] = val2;  // Store "aktif" or whatever string is received
          currentIndex++;
        } else {
          // Shift data to make room for new values
          arrayCopy(rssi, 1, rssi, 0, maxIterations - 1);
          arrayCopy(filteredRSSI, 1, filteredRSSI, 0, maxIterations - 1);
          arrayCopy(distances, 1, distances, 0, maxIterations - 1);
          rssi[maxIterations - 1] = val0;
          filteredRSSI[maxIterations - 1] = val1;
          distances[maxIterations - 1] = val2;
        }
      } catch (Exception e) {
        println("Error parsing data: " + e.getMessage());
      }
    }
  }
}

void drawAxes() {
  stroke(0);
  line(50, 400, width - 50, 400); // X-axis
  line(50, 50, 50, 400);          // Y-axis

  // Draw X-axis labels
  fill(0);
  textSize(12);
  for (int i = 0; i <= maxIterations; i += 50) {
    float x = map(i, 0, maxIterations, 50, width - 50);
    text(i, x, 420);
  }

  // Draw Y-axis labels (-30 to -100)
  for (int i = -30; i >= -100; i -= 10) {
    float y = map(i, -30, -100, 400, 50);
    text(i, 20, y);
  }
}

void plotLine(float[] data, color c, String label) {
  stroke(c);
  strokeWeight(2);
  noFill();
  beginShape();
  for (int i = 0; i < currentIndex; i++) {
    float x = map(i, 0, maxIterations - 1, 50, width - 50);
    float y = map(data[i], -30, -100, 400, 50); // Adjust scale
    vertex(x, y);
  }
  endShape();
}

void drawLegendRSSI() {
  fill(255, 0, 0);
  rect(60, 60, 10, 10);
  fill(0);
  text("RSSI (Red)", 80, 70);

  fill(0, 0, 255);
  rect(60, 80, 10, 10);
  fill(0);
  text("Filtered RSSI (Blue)", 80, 90);
}

// Helper function to check if a string is numeric
boolean isNumeric(String str) {
  try {
    Float.parseFloat(str);  // Try converting to a float
    return true;  // Success means it's a valid numeric string
  } catch (NumberFormatException e) {
    return false;  // If an exception occurs, it's not numeric
  }
}

void displayDistances() {
  fill(0);
  textSize(12);
  int startX = 50;
  int startY = 500;
  int counter = 0;
  for (int i = 0; i < currentIndex; i++) {
    if (counter == 19) {
      startX = 50;
      startY += 20;
      counter = 0;
    }

    // If the distance is numeric, format it
    String distanceText = distances[i];
    if (isNumeric(distanceText)) {
      float distanceValue = float(distanceText);
      distanceText = nf(distanceValue, 1, 2);  // Format the distance
    }

    text("Status[" + i + "]: " + distanceText, startX, startY);
    startX += 90;
    counter++;
  }
}
