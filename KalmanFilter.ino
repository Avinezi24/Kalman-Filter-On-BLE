#include <BLEDevice.h>
#include <cmath>

int scanTime = 1;
int iteration = 0;
const int maxIterations = 200;

float Q = 0.01;  
float R = 0.3;   
float kalmanGain = 0;
float estimatedRSSI = 0;  
float estimatedError = 1;

float rssiRaw[maxIterations];
float rssiFiltered[maxIterations];
float distanceFiltered[maxIterations];
float distanceRaw[maxIterations];  
float actualDistance = 3.0;  

float kalmanFilter(float rssi) {
  // Inisialisasi estimasi awal
  if (iteration == 0) {
    estimatedRSSI = rssi;
  }
  estimatedError = estimatedError + Q; 
  kalmanGain = estimatedError / (estimatedError + R);
  estimatedRSSI = estimatedRSSI + kalmanGain * (rssi - estimatedRSSI);
  estimatedError = (1 - kalmanGain) * estimatedError;  
  return estimatedRSSI;
}

// Fungsi untuk menghitung jarak dari RSSI (log-distance path loss model)
float calculateDistance(float rssi) {
  float txPower = -69;                          // RSSI pada 1 meter
  if (rssi == 0) return -1;                     // Jika tidak ada sinyal
  return pow(10, (txPower - rssi) / (10 * 2));  // n = 2 (path loss exponent)
}

float calculateRMSE(float *distances, int size, float actualValue) {
  float sumError = 0.0;
  for (int i = 0; i < size; i++) {
    float error = distances[i] - actualValue;
    sumError += error * error;
  }
  return sqrt(sumError / size);
}

class MyAdvertisedDeviceCallbacks : public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice advertisedDevice) {
    if (advertisedDevice.getName() == "rahman" && iteration < maxIterations) {
      float rssi = advertisedDevice.getRSSI();

      float filteredRSSI = kalmanFilter(rssi);

      float rawDistance = calculateDistance(rssi);
      float filteredDistance = calculateDistance(filteredRSSI);

      rssiRaw[iteration] = rssi;
      rssiFiltered[iteration] = filteredRSSI;
      distanceRaw[iteration] = rawDistance;  // Menyimpan jarak mentah sebelum filter
      distanceFiltered[iteration] = filteredDistance;

      Serial.print(rssi);
      Serial.print(", ");
      Serial.print(filteredRSSI);
      Serial.print(", ");
      Serial.print(filteredDistance);
      Serial.print(", ");
      Serial.print(rawDistance);

      iteration++;

      if(filteredDistance <=4){
        Serial.print(", ");
        Serial.println("aktif");
      }
      else{
        Serial.print(", ");
        Serial.println("tidak aktif");
      }

      if (iteration == maxIterations) {
        float rmseFiltered = calculateRMSE(distanceFiltered, maxIterations, actualDistance);
        float rmseUnfiltered = calculateRMSE(distanceRaw, maxIterations, actualDistance);

        float accuracyPercentage1 = (1 - (rmseFiltered / actualDistance)) * 100.0;
        float accuracyPercentage2 = (1 - (rmseUnfiltered / actualDistance)) * 100.0;

        Serial.println("\n=== Hasil Akhir jarak dengan rssi terfilter ===");
        Serial.print("RMSE (Distance): ");
        Serial.println(rmseFiltered);
        Serial.print("Actual Distance: ");
        Serial.println(actualDistance);
        Serial.print(" accuracy percentage: ");
        Serial.print(accuracyPercentage1);
        Serial.println("%");

        Serial.println("\n=== Hasil Akhir jarak tanpa rssi terfilter  ===");
        Serial.print("RMSE (Distance): ");
        Serial.println(rmseUnfiltered);
        Serial.print("Actual Distance: ");
        Serial.println(actualDistance);
        Serial.print(" accuracy percentage: ");
        Serial.print(accuracyPercentage2);
        Serial.println("%");
        
      }
    }
  }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Memulai pemindaian BLE...");

  BLEDevice::init("");
  BLEScan *pBLEScan = BLEDevice::getScan();
  pBLEScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks());

  pBLEScan->setActiveScan(true);
  pBLEScan->setInterval(10);
  pBLEScan->setWindow(9);
}

void loop() {
  BLEScan *pBLEScan = BLEDevice::getScan();
  pBLEScan->start(scanTime, false);
  pBLEScan->stop();

  if (iteration >= maxIterations) {
    delay(1000000);
    delay(5);
  }
}