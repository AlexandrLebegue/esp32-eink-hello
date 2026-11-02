#include <GxEPD2_BW.h>
#include <epd/GxEPD2_154_D67.h>
#include <Fonts/FreeMonoBold9pt7b.h>

// Écran e-paper 1,54" 200×200 N/B, contrôleur SSD1681.
// Broches ESP32 : CS = 5, DC = 17, RST = 16, BUSY = 4 (SPI matériel : SCK = 18, MOSI = 23).
GxEPD2_BW<GxEPD2_154_D67, GxEPD2_154_D67::HEIGHT> panel(
  GxEPD2_154_D67(5, 17, 16, 4));

void setup() {
  Serial.begin(115200);
  delay(2000);
  Serial.println("Hello World");

  panel.init();
  panel.setRotation(1);
  panel.setFont(&FreeMonoBold9pt7b);
  panel.setTextColor(GxEPD_BLACK);
  panel.fillScreen(GxEPD_WHITE);

  // Centrage du texte sur l'écran.
  const char *text = "Hello World";
  int16_t tbx, tby;
  uint16_t tbw, tbh;
  panel.getTextBounds(text, 0, 0, &tbx, &tby, &tbw, &tbh);
  int16_t x = ((panel.width() - tbw) / 2) - tbx;
  int16_t y = ((panel.height() - tbh) / 2) - tby;
  panel.setCursor(x, y);
  panel.print(text);

  panel.refresh();
  panel.hibernate();
}

void loop() {
}
