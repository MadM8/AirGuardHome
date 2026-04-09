#include <Arduino.h>
#include <DHT.h>

#define DHTPIN 4      // GPIO pin connected to DHT22 DATA
#define DHTTYPE DHT22 // Sensor type

DHT dht(DHTPIN, DHTTYPE);

// put function declarations here:
int myFunction(int, int);

void setup()
{
  // put your setup code here, to run once:
  Serial.begin(115200);
  dht.begin();
  Serial.println("ESP32 DHT22 Node Ready");
}

void loop()
{
  delay(2000); // DHT22 needs ~2s between readings

  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature(); // Celsius
  float heatIndex = dht.computeHeatIndex(temperature, humidity, false);

  // Check for failed readings
  if (isnan(humidity) || isnan(temperature))
  {
    Serial.println("ERROR: Failed to read from DHT22!");
    return;
  }
  Serial.printf("Temp: %.2f°C | Humidity: %.2f%% | Heat Index: %.2f°C\n",
                temperature, humidity, heatIndex);
}

// put function definitions here:
int myFunction(int x, int y)
{
  return x + y;
}