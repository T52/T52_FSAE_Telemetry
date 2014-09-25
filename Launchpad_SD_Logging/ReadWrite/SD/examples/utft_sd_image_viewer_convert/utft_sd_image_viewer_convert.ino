// Arduino SD image viewer
// Written by Stanley Huang <stanleyhuangyc@gmail.com>
//
// This program requires the UTFT library.
//

#include <UTFT.h>
#include <SD.h>
#include <SPI.h>
// Declare which fonts we will be using
extern uint8_t SmallFont[];
extern uint8_t BigFont[];

// for Arduino 2009/Uno
UTFT myGLCD(TFT01_22SP,15,7,4,5,6);  
// for Arduino Mega
//UTFT myGLCD(ITDB32S,38,39,40,41);   // Remember to change the model parameter to suit your display module!

#define SD_PIN 32

File root;

#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 240

void ShowMessage(const char* msg1, const char* msg2 = 0)
{
 // SPI.setModule(2);
    myGLCD.setColor(255, 0, 0);
    myGLCD.fillRoundRect(50, 190, 270, 230);
    myGLCD.setColor(255, 255, 255);
    myGLCD.setBackColor(255, 0, 0);
    myGLCD.print(msg1, CENTER, 196);
    if (msg2) myGLCD.print(msg2, CENTER, 210);
    SPI.setModule(0);
}

void LoadImage(File& file)
{
  SPI.setModule(0);
    for (int y = 0; y < SCREEN_HEIGHT && file.available(); y++) {
        uint16_t buf[SCREEN_WIDTH];
        for (int x = SCREEN_WIDTH - 1; x >= 0; x--) {
            byte l = file.read();
            byte h = file.read();
            buf[x] = ((uint16_t)h << 8) | l;
        }
   //     SPI.setModule(2);
        myGLCD.drawPixelLine(0, y, SCREEN_WIDTH, buf);
        SPI.setModule(0);
    }
}

void WalkDirectory(File dir)
{
  SPI.setModule(0);
    for (;;) {
        File entry =  dir.openNextFile();
        if (! entry) {
            // no more files
            break;
        }
        if (entry.isDirectory()) {
            WalkDirectory(entry);
        } else {
            ShowMessage("Loading image from SD card", entry.name());
            LoadImage(entry);
        }
        entry.close();
        // delay for a while between each image
        delay(2000);
    }
}

void setup()
{
    // Setup the LCD
    SPI.begin();
    SPI.setModule(2);
  //  SPI.setClockDivider(SPI_CLOCK_DIV64);
    myGLCD.InitLCD();
    myGLCD.setFont(SmallFont);
    myGLCD.fillScr(0, 0, 255);
    myGLCD.print("hallo", CENTER, 196);
    ShowMessage(" from SD card");
SPI.setModule(0);
    pinMode(SD_PIN, OUTPUT);
    if (!SD.begin(SD_PIN)) {
        ShowMessage("SD not ready");
        return;
    }

    delay(1000);
    root = SD.open("/PICTURE");
    WalkDirectory(root);

    ShowMessage("That's the end of the show", "Press RESET to start over");
}

void loop()
{
}
