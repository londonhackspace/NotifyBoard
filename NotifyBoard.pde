/*
Copyright 2010 Charles Yarnold charlesyarnold@gmail.com
 
 NotifyBoard is free software: you can redistribute it and/or modify it under the terms of
 the GNU General Public License as published by the Free Software Foundation, either
 version 3 of the License, or (at your option) any later version.
 
 NotifyBoard is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with NotifyBoard.
 If not, see http://www.gnu.org/licenses/.
 
*/

/* Includes various minor modifications by London Hackspace */

/*
This sketch requires the arduino Library from:
 http://github.com/solexious/MatrixDisplay
 
 Version 0.4
 */

//#include <FatReader.h>
//#include <SdReader.h>
//#include <avr/pgmspace.h>
#include <TimedAction.h>
//#include "WaveUtil.h"
//#include "WaveHC.h"


/*SdReader card;    // This object holds the information for the card
 FatVolume vol;    // This holds the information for the partition on the card
 FatReader root;   // This holds the information for the filesystem on the card
 FatReader f;      // This holds the information for the file we're play
 
 WaveHC wave;      // This is the only wave (audio) object, since we will only play one at a time*/

#include "MatrixDisplay.h"
#include "DisplayToolbox.h"
#include "font.h"

// Required when using Makefile - would be nice to get rid of this
void scroll();
void initText(void);
void drawString(int x, int y, char* c);
void drawStringW(int x, int y, char* c);


// Easy to use function
#define setMaster(dispNum, CSPin) initDisplay(dispNum,CSPin,true)
#define setSlave(dispNum, CSPin) initDisplay(dispNum,CSPin,false)

// 4 = Number of displays
// Data = 10
// WR == 11
// False - we dont need a shadow buffer for this example. saves 50% memory!

// Init Matrix
MatrixDisplay disp(4,15,14, false);
MatrixDisplay dispW(1,4,5, false);
// Pass a copy of the display into the toolbox
DisplayToolbox toolbox(&disp);
DisplayToolbox toolboxW(&dispW);

// Text settings
int x;
boolean scrolling;
int minLeft;

// Prepare boundaries
int X_MAX = 0;
int Y_MAX = 0;
int X_MAXW = 0;
int Y_MAXW = 0;

int jonty = 0;
int car = 0;

// Pins for car control
#define CAR_FWD 9
#define CAR_BACK 11
#define CAR_LEFT 8
#define CAR_RIGHT 10
#define FWD_TURN_TIME 600 
#define BACK_TURN_TIME 600
#define DRIVE_TIME 250 

//serial in stuff
#define INLENGTH 162
char inString[INLENGTH+1];
char inSerialString[INLENGTH+1];
int inCount;

TimedAction timedAction = TimedAction(35, scroll);

void setup() {
  Serial.begin(9600); 

  timedAction.disable();

  // Fetch bounds
  X_MAX = disp.getDisplayCount() * disp.getDisplayWidth();
  Y_MAX = disp.getDisplayHeight();
  X_MAXW = dispW.getDisplayCount() * dispW.getDisplayWidth();
  Y_MAXW = dispW.getDisplayHeight();

  // Prepare displays
  // The first number represents how the buffer/display is stored in memory. Could be useful for reorganising the displays or matching 
  // he physical layout
  // The number is a array index and is sequential from 0. You can't use 4-8. You must use the numbers 0-4
  disp.setMaster(0,16);
  disp.setSlave(1,17);
  disp.setSlave(2,18);
  disp.setSlave(3,19);
  dispW.setMaster(0,6);

  //wave hc stuff
  byte i;

  //putstring("Free RAM: ");       // This can help with debugging, running out of RAM is bad
  //Serial.println(freeRam());      // if this is under 150 bytes it may spell trouble!

  // Set the output pins for the DAC control. This pins are defined in the library
  pinMode(2, OUTPUT);
  pinMode(3, OUTPUT);
  pinMode(4, OUTPUT);
  pinMode(5, OUTPUT);

  // pin13 LED
  pinMode(6, OUTPUT);
  /*
  //  if (!card.init(true)) { //play with 4 MHz spi if 8MHz isn't working for you
   if (!card.init()) {         //play with 8 MHz spi (default faster!)  
   putstring_nl("Card init. failed!");  // Something went wrong, lets print out why
   sdErrorCheck();
   while(1);                            // then 'halt' - do nothing!
   }
   
   // enable optimize read - some cards may timeout. Disable if you're having problems
   card.partialBlockRead(true);
   
   // Now we will look for a FAT partition!
   uint8_t part;
   for (part = 0; part < 5; part++) {     // we have up to 5 slots to look in
   if (vol.init(card, part)) 
   break;                             // we found one, lets bail
   }
   if (part == 5) {                       // if we ended up not finding one  :(
   putstring_nl("No valid FAT partition!");
   sdErrorCheck();      // Something went wrong, lets print out why
   while(1);                            // then 'halt' - do nothing!
   }
   
   // Lets tell the user about what we found
   putstring("Using partition ");
   Serial.print(part, DEC);
   putstring(", type is FAT");
   Serial.println(vol.fatType(),DEC);     // FAT16 or FAT32?
   
   // Try to open the root directory
   if (!root.openRoot(vol)) {
   putstring_nl("Can't open root dir!"); // Something went wrong,
   while(1);                             // then 'halt' - do nothing!
   }
   
   // Whew! We got past the tough parts.
   putstring_nl("Ready!");*/

  // INITALISE
  dispW.clear();
  //drawStringW(1,0,"HELLO");
  //toolboxW.setPixel(0,0, 1);
  //drawCharW(0, 0, *"H");
  dispW.syncDisplays();
  //delay(5000);
  initText();
}

//************************ START LOOP **********************

void loop()
{

  if (Serial.available() > 0)
  {
    inCount = 0;
    do {
      inSerialString[inCount] = Serial.read(); // get it
      if (inSerialString[inCount] == 10 || inSerialString[inCount] == 13 || inSerialString[inCount] == 0) break; // 0x0a or 0x0d aka LF or CR, or NULL
      if (inCount > INLENGTH) break;
      //Serial.println(inString[inCount]); 
      if (inSerialString[inCount] > 0 ) inCount++;
    } 
    while (1==1);
    inSerialString[inCount] = 0;




    if(strstr(inSerialString,"$W$")){
      // Send srting to mini board
      char* miniString = inSerialString;
      miniString +=3;
      dispW.clear();
      drawStringW(0,0,miniString);
      dispW.syncDisplays();
    }
    else{
      
      for(int a=0; a<162; a++){
        inString[a] = inSerialString[a];
      }
      
      timedAction.disable();
      if (strlen(inString) < 21)
      {
        x = floor ((128 - ((strlen(inString)*6) - 1)) / 2);
        scrolling = false;
        minLeft = 0;
      }
      else
      {
        x = X_MAX;
        scrolling = true;
        minLeft = 0 - (strlen(inString)*6);
      }


      if (strstr(inString,"jonty"))
        digitalWrite(13, HIGH);       // turn on pullup resistors
      else
        digitalWrite(13, LOW);       // turn on pullup resistors

      if (strstr(inString,"car")) {
        if (strlen(inString) > 3) {
          char car_cmd = inString[3];

          switch (car_cmd){
          case '1':
            digitalWrite(CAR_LEFT, HIGH);
            digitalWrite(CAR_FWD, HIGH);
            delay(FWD_TURN_TIME);
            digitalWrite(CAR_LEFT, LOW);
            digitalWrite(CAR_FWD, LOW);
            break;
          case '2':
            digitalWrite(CAR_RIGHT, HIGH);
            digitalWrite(CAR_FWD, HIGH);
            delay(FWD_TURN_TIME);
            digitalWrite(CAR_RIGHT, LOW);
            digitalWrite(CAR_FWD, LOW);
            break;
          case '3':
            digitalWrite(CAR_LEFT, HIGH);
            digitalWrite(CAR_BACK, HIGH);
            delay(BACK_TURN_TIME);
            digitalWrite(CAR_LEFT, LOW);
            digitalWrite(CAR_BACK, LOW);
            break;
          case '4':
            digitalWrite(CAR_RIGHT, HIGH);
            digitalWrite(CAR_BACK, HIGH);
            delay(BACK_TURN_TIME);
            digitalWrite(CAR_RIGHT, LOW);
            digitalWrite(CAR_BACK, LOW);
            break;
          case '5':
            digitalWrite(CAR_FWD, HIGH);
            delay(DRIVE_TIME);
            digitalWrite(CAR_FWD, LOW);
            break;
          case '6':
            digitalWrite(CAR_BACK, HIGH);
            delay(DRIVE_TIME);
            digitalWrite(CAR_BACK, LOW);                  
            break;
          case '7':
            digitalWrite(CAR_LEFT, HIGH);
            delay(DRIVE_TIME);
            digitalWrite(CAR_LEFT, LOW);
            break;
          case '8':
            digitalWrite(CAR_RIGHT, HIGH);
            delay(DRIVE_TIME);
            digitalWrite(CAR_RIGHT, LOW);                  
            break;
          }
        }
      }

      disp.clear();
      drawString(x,0,inString);
      disp.syncDisplays(); 
      //playfile("PING.WAV");
      Serial.print("Displaying: ");
      Serial.println(inString);
      if (scrolling) timedAction.enable();
    }
    
    if (strstr(inString,"jonty"))
      digitalWrite(13, HIGH);       // turn on pullup resistors
    else
      digitalWrite(13, LOW);       // turn on pullup resistors

    if (strstr(inString,"car")) {
      if (strlen(inString) > 3) {
        char car_cmd = inString[3];

	switch (car_cmd){
          case '1':
	    digitalWrite(CAR_LEFT, HIGH);
	    digitalWrite(CAR_FWD, HIGH);
	    delay(FWD_TURN_TIME);
	    digitalWrite(CAR_LEFT, LOW);
	    digitalWrite(CAR_FWD, LOW);
	    break;
          case '2':
            digitalWrite(CAR_RIGHT, HIGH);
            digitalWrite(CAR_FWD, HIGH);
            delay(FWD_TURN_TIME);
            digitalWrite(CAR_RIGHT, LOW);
            digitalWrite(CAR_FWD, LOW);
            break;
          case '3':
            digitalWrite(CAR_LEFT, HIGH);
            digitalWrite(CAR_BACK, HIGH);
            delay(BACK_TURN_TIME);
            digitalWrite(CAR_LEFT, LOW);
            digitalWrite(CAR_BACK, LOW);
            break;
          case '4':
            digitalWrite(CAR_RIGHT, HIGH);
            digitalWrite(CAR_BACK, HIGH);
            delay(BACK_TURN_TIME);
            digitalWrite(CAR_RIGHT, LOW);
            digitalWrite(CAR_BACK, LOW);
            break;
          case '5':
            digitalWrite(CAR_FWD, HIGH);
            delay(DRIVE_TIME);
            digitalWrite(CAR_FWD, LOW);
            break;
          case '6':
            digitalWrite(CAR_BACK, HIGH);
            delay(DRIVE_TIME);
            digitalWrite(CAR_BACK, LOW);                  
            break;
          case '7':
            digitalWrite(CAR_LEFT, HIGH);
            delay(DRIVE_TIME);
            digitalWrite(CAR_LEFT, LOW);
            break;
          case '8':
            digitalWrite(CAR_RIGHT, HIGH);
            delay(DRIVE_TIME);
            digitalWrite(CAR_RIGHT, LOW);                  
            break;
	}
      }
    }

    disp.clear();
    drawString(x,0,inString);
    disp.syncDisplays(); 
    //playfile("PING.WAV");
    Serial.print("Displaying: ");
    Serial.println(inString);
    if (scrolling) timedAction.enable();
  }
  timedAction.check();
}
// ******************************** END LOOP **********************************
//wave hc stuff
/*
// this handy function will return the number of bytes currently free in RAM, great for debugging!   
 int freeRam(void)
 {
 extern int  __bss_end; 
 extern int  *__brkval; 
 int free_memory; 
 if((int)__brkval == 0) {
 free_memory = ((int)&free_memory) - ((int)&__bss_end); 
 }
 else {
 free_memory = ((int)&free_memory) - ((int)__brkval); 
 }
 return free_memory; 
 } 
 
 void sdErrorCheck(void)
 {
 if (!card.errorCode()) return;
 putstring("\n\rSD I/O error: ");
 Serial.print(card.errorCode(), HEX);
 putstring(", ");
 Serial.println(card.errorData(), HEX);
 while(1);
 }
 
 // Plays a full file from beginning to end with no pause.
 void playcomplete(char *name) {
 // call our helper to find and play this name
 playfile(name);
 while (wave.isplaying) {
 // do nothing while its playing
 }
 // now its done playing
 }
 
 void playfile(char *name) {
 // see if the wave object is currently doing something
 if (wave.isplaying) {// already playing something, so stop it!
 wave.stop(); // stop it
 }
 // look in the root directory and open the file
 if (!f.open(root, name)) {
 putstring("Couldn't open file "); 
 Serial.print(name); 
 return;
 }
 // OK read the file and turn it into a wave object
 if (!wave.create(f)) {
 putstring_nl("Not a valid WAV"); 
 return;
 }
 
 // ok time to play! start playback
 wave.play();
 }*/

//sure display
void drawCharW(int x, int y, char c)
{
  if(c==46){
    toolboxW.setPixel(x, 0+y, 0);
    toolboxW.setPixel(x, 1+y, 0);
    toolboxW.setPixel(x, 2+y, 0);
    toolboxW.setPixel(x, 3+y, 0);
    toolboxW.setPixel(x, 4+y, 0);
    toolboxW.setPixel(x, 5+y, 0);
    toolboxW.setPixel(x, 6+y, 1);
  }
  else{
    uint8_t dots;
    for (char col=0; col< 5; col++) {
      dots = pgm_read_byte_near(&myfont[c][col]);
      for (char row=0; row < 8; row++) {
        if (x+col<0)
        {

        }
        else if (dots & (0x80>>row))   	     // only 7 rows.
          toolboxW.setPixel(x+col, y+row, 1);
        else 
          toolboxW.setPixel(x+col, y+row, 0);
      }
    }
  }
}

void drawChar(int x, int y, char c)
{
  uint8_t dots;
  for (char col=0; col< 5; col++) {
    dots = pgm_read_byte_near(&myfont[c][col]);
    for (char row=0; row < 8; row++) {
      if (x+col<0)
      {

      }
      else if (dots & (0x80>>row))   	     // only 7 rows.
        toolbox.setPixel(x+col, y+row, 1);
      else 
        toolbox.setPixel(x+col, y+row, 0);
    }
  }
}


// Write out an entire string (Null terminated)
void drawString(int x, int y, char* c)
{
  for(char i=0; i< strlen(c); i++)
  {
    if(x>-6)
    {
      if(x<X_MAX)
      {
        drawChar(x, y, c[i]);
      }
    }
    x+=6; // Width of each glyph
  }
}

void drawStringW(int x, int y, char* c)
{
  for(char i=0; i< strlen(c); i++)
  {
    if(x>-6)
    {
      if(x<X_MAXW)
      {
        drawCharW(x, y, c[i]);
      }
    }
    if(c[i]==46){
      x+=2;
    }
    else{
      x+=6; // Width of each glyph
    }
  }
}

void fadeIn(void)
{
  for(int i=0; i<16; ++i) // The displays have 15 different brightness settings
  {
    // This will set the brightness for ALL displays
    toolbox.setBrightness(i);
    // Alternatively you could set them individually
    // disp.setBrightness(displayNumber, i);
    delay(200); // Let's wait a bit or you'll miss it!
  }
}

void initText(void)
{
  drawString(0,0,"London Hackspace");
  disp.syncDisplays(); 
  fadeIn();
  disp.clear();
  drawString(0,0,"NotificationBoard 0.5");
  disp.syncDisplays(); 
  fadeIn();
  disp.clear();
  delay(100);
  drawString(0,0,"Loading, Please wait");
  disp.syncDisplays();
  delay(500);
  disp.clear();
  disp.syncDisplays(); 
  delay(500);
  drawString(0,0,"Loading, Please wait");
  disp.syncDisplays(); 
  delay(500);
  disp.clear();
  disp.syncDisplays(); 
  delay(500);
  drawString(0,0,"Loading, Please wait");
  disp.syncDisplays(); 
  delay(500);
  disp.clear();
  disp.syncDisplays(); 
  delay(500);
  disp.clear();
  drawString(0,0,"Ready for input");
  disp.syncDisplays(); 
  fadeIn();
  disp.clear();
  disp.syncDisplays(); 
}

void scroll()
{
  x--;
  if (x<minLeft) x = X_MAX;
  disp.clear();
  drawString(x,0,inString);
  disp.syncDisplays();
}



