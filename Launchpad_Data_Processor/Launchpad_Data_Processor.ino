/*                                                                   25th SEPTEMBER 2014
========================================================================================
========================= Engineering Design 3A - FSAE TEAM 52 =========================
========================================================================================
==================   This program is used to acquire and/or generate  ==================
==================   Serial Data. User can select between the         ==================
==================   following operation modes:                       ==================
==================     - Mock Data Mode                               ==================
==================     - Data Acquisition Mode                        ==================
==================                                                    ==================
==================   Under Mock Data Mode, data is output in the      ==================
==================   following format:                                ==================
==================   "T A B C D E \n"                                 ==================
==================                                                    ==================
==================   where each letter is a sample of one data set:   ==================
==================   T data stream = time in seconds running          ==================
==================   A data stream = 0-999 random                     ==================
==================   B data stream = 0-1000 with a 0.2 increment      ==================
==================   C data stream = 3-5 random                       ==================
==================   D data stream = 100-500 random                   ==================
==================   E data stream = 600-1000 random                  ==================
==================                                                    ==================
==================   Under Data Acquisition Mode, ...                 ==================
==================   DESCRIPTION YET TO BE ADDED                      ==================
==================                                                    ==================
==================                                                    ==================
==================                                                    ==================
==================                                                    ==================
==================                                                    ==================
==================                                                    ==================
========================================================================================
*/
// ref1: http://forum.arduino.cc/index.php/topic,46643.0.html
// ref2: http://arduino.cc/en/Serial/read
// ref3: http://arduino.cc/en/Reference/millis
// ref4: 

//===================================Library Includes====================================
#include <EEPROM.h>
#include <SD.h>
#include <SPI.h>
//=====================================Definitions=======================================
#define dataSetLength 6
#define EEPROM_TIMEBASE_ADDR 0

//===================================Program Settings====================================
boolean mockMode = false;                  //  Defines which mode of operation to use.
                                           //    - True denotes Mock Data Mode
                                           //    - False denotes Data Acquistion Mode

boolean sendConfigInfo = true;             //  This is an option to send an initial
                                           //  set of configuration settings, giving
                                           //  the plotting program more information
                                           //  on what data it is handling.

int configUpdateLimit = 10;                //  If config info strings are enabled,
                                           //  sets the maximum time elapsed before
                                           //  program should send an config update.
                                           
boolean xbeeMode = false;                  //  This condition determines whether Xbees
                                           //  are being used. Usually this would be
                                           //  true, except for testing without the
                                           //  Xbee.
                                           
boolean SDMode = false;                    //  Condition to execute optional SD
                                           //  functionality. This is provided for
                                           //  testing purposes where the SD might
                                           //  not be used.

int sigNum = 6;                            //  This allows quick changes to be made to
                                           //  the number of signals when in mock mode,
                                           //  which helps with testing transmission 
                                           //  capacity.
                                           
//================================Setup Global Variables=================================                                            
float bdata = 0.00;   //set start point on 'B' data stream
float binc = 0.20;    //set increment on 'B' data stream

                                            //  These are default names for data sets.
                                            //  They may be changed freely by user, or 
                                            //  program functions.
String DataSet1_Name = "Time_Base";
String DataSet2_Name = "Level";
String DataSet3_Name = "Speed";
String DataSet4_Name = "Acceleration";
String DataSet5_Name = "Engine_Temperature";
String DataSet6_Name = "Vehicle_Fault_Indicators";

//==================================Program Setup========================================
void setup() {
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Serial Initialization~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Serial.begin(115200);                       // Choose Default Baud rate of 9600
                                            //  Other support baud rates are: 
                                            //  110, 300, 600, 1200, 2400, 4800, 
                                            //  9600, 14400, 19200, 38400, 57600, 
                                            //  115200, 230400, 460800, 921600
  Serial2.begin(115200);
                                            
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Xbee Configuration~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if(xbeeMode)
  {
    int ok_count = 0;
    do
    { 
      Serial2.flush();
      switch(ok_count)
      {
        case 0:
        {
          Serial2.print("+++");
          Serial.println("Printed: +++");
          break;
        }
        case 1:
        {
          Serial2.println("atap 0");                                                                                                                                                                                                 
          Serial.println("Printed: atap 0");
          break;
        }
        case 2:
        {
          Serial2.println("atwr");
          Serial.println("Printed: atwr");
          break;
        }
        case 3:
        {
          Serial2.println("atcn");
          Serial.println("Printed: atcn");
          break;
        }
        default:
        {
          Serial.println("Xbee Config Error");
          break;
        }
      }
      
      delay(1000);
      int timeCheck = millis()/1000;
      while(Serial2.available() < 2)
      {
        if((millis()/1000 - timeCheck) > 5) break;
      }
      if((Serial2.available() > 1) && (Serial2.available() < 100))
      {
        char start_buf[10] = "";
        Serial2.readBytes(start_buf, Serial2.available());
        
        if(String(start_buf).equals("OK\r"))
        {
          Serial.print(String(start_buf));
          Serial.println(" Found");
        }
        else 
        {
          Serial.print("No OK received. Serial read was: ");
          Serial.println(String(start_buf));
          continue;
        }
      }
      else 
      {
        char error_buf[1] = "";
        while(Serial2.available() > 0)
        {
          Serial.print(".");
          Serial2.readBytes(error_buf, 1);
        }
        Serial.println("Buffer Flushed.");
        continue;
      }
      ok_count++;
      Serial.flush();
      //Serial.print(ok_count);
      //Serial.println(" OK found");  
    }  while(ok_count < 4); 
    
    Serial.println("OK received. Configuration complete");
    
  }
  
  //~~~~~~~~~~~~~~~~~~~~~~~Send Initial Configuration Information~~~~~~~~~~~~~~~~~~~~~~~~
  sendConfigString();
}

//=================================Main Program Loop=====================================
void loop() {
  float timeElapsed = 0;
  float addedTime = 0;
  int n = 0;
  File myFile;
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~SD Card Implementation~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if(SDMode)                              //  SD only needs to be initialized if SD is being
  {                                       //  used. Otherwise, initialization will fail.
    pinMode(10, OUTPUT);
    
    if (!SD.begin(4)) {
      Serial.println("initialization failed!");
      return;
    }
    
    if(SD.exists("data.txt")){
      SD.remove("data.txt");
    }
        
    myFile = SD.open("data.txt", FILE_WRITE);
  }
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~Generate and Transmit Mock Data~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if(mockMode)                              //  Enters mock data transmission mode
  {
    int ramp = 0; 
    for(;;)                                 //  Loops in this mode forever
    {
           //~~~~~~~~~~~~~~~Print mock data string to serial port~~~~~~~~~~~~~~~~~~~~~~~~
           float exectime = float(millis())/1000; //  millis command is a long int that 
                                                  //  contains program execute time in ms.
                                                 
           Serial2.print(exectime);                // 'T' data stream 
           Serial2.print(" ");
           Serial2.print(ramp);
           Serial2.print(" ");
           ramp += 1;
           
           int i=2;
           for(i; i < sigNum; i++)
           {
             Serial2.print(random(0,1000));          // 'A' data stream
             Serial2.print(" ");
           }
           Serial2.print(" \r");
           
           delay(25);//delay in ms 250 = 4 times a second
           
           timeElapsed = exectime - addedTime;     //  Checks how much time has elapsed,
                                                   //  if it has been more than 5 seconds
                                                   /*
           if((timeElapsed > configUpdateLimit) && sendConfigInfo) 
           {                                       //  since last config update, sends a 
             sendConfigString();                   //  config string.
             addedTime = exectime;
           }
           */
           
  
      }
  }
  else                                      //  Enters data acquisition mode  
  {
                                            //  Creates realistic string of variables as 
                                            //  to those that would be expected.
    float execTime = 0;
    float batteryLevel = 100;               //  100% battery by default
    float vehicleSpeed = 0;                 //  Speed starts at 0ms
    float vehicleAccel = 0;                 //  Acceleration starts at 0ms^2
    float engineTemp = 20;                   //  Engine temperature starts at 20 degrees
    int vehicleIndicators = 0;
    float initRead = 0;
    float resetTime = 0;
    int n=0;                                // Count loops around print routine
    int i=0;
    boolean transBegin = false;
    boolean downloadBegin = false;
    
    for(;;)
    {
      //~~~~~~~~~~~~~~~~~~~~~~~Create simulation data for now~~~~~~~~~~~~~~~~~~~~~~~~~~~
      execTime = float(millis())/1000;     //  millis command is a long int that 
      
      timeElapsed = execTime - addedTime;     //  Checks how much time has elapsed,
                                              //  if it has been more than 5 seconds
      if((timeElapsed > configUpdateLimit) && sendConfigInfo) 
      {                                       //  since last config update, sends a 
         sendConfigString();                  //  config string.
         addedTime = execTime;
      }
      
      //~~~~~~~~~~~~~~~~~~~~~~~~~Check for signals from plotter~~~~~~~~~~~~~~~~~~~~~~~~~
     if(xbeeMode)
      {
        if(Serial2.available() > 2)
        {
          char start_buf[10] = "";
          Serial2.readBytes(start_buf, Serial2.available());
          Serial.print("Plotter string received was: ");
          Serial.println(String(start_buf));
          if(String(start_buf) == "!!!")  
          {
            transBegin = true;
          }
          if(String(start_buf) == "~~~")  transBegin = false;
          if(String(start_buf) == "---")
          {
            n=0;
            initRead = 0;
            resetTime = execTime;
          }
        }
        if(!transBegin) continue;
      }
      else
      {
        if(Serial.available() > 2)
        {
          char start_buf[10] = "";
          Serial.readBytes(start_buf, Serial.available());
          
          
          Serial.print("Plotter string received was: ");
          Serial.println(String(start_buf));
          if(String(start_buf) == "!!!")  
          {
            transBegin = true;
          }
          if(String(start_buf) == "~~~")  transBegin = false;
          if(String(start_buf) == "---")
          {
            n=0;
            initRead = 0;
            resetTime = execTime;
          }
        }
        if(!transBegin) continue;
      }
      
      //~~~~~~~~~~~~~~~~~~~~~~~~~Generate Data for transmission~~~~~~~~~~~~~~~~~~~~~~~~~~
      execTime = execTime - resetTime;
      
      i++;
      if((i>=10) || (n==0))
      {
        if(vehicleAccel < 0)  vehicleAccel = float(random(1000, 10000)/1000);
        else                  vehicleAccel = float(random(-10000, -1000)/1000);
        i=0;
      }

      vehicleSpeed = vehicleSpeed + vehicleAccel;
      if(vehicleSpeed < 0)  vehicleSpeed = 0;
      if(vehicleAccel > 0)  batteryLevel = batteryLevel - vehicleAccel/100;
      else                  batteryLevel = batteryLevel - float(random(50, 100)/1000);
      
      engineTemp = 20 + execTime/10;
      if(engineTemp > 100) engineTemp = 100;
      if(vehicleSpeed < 1) engineTemp--;
      
      vehicleIndicators = random(0, 15);

      //~~~~~~~~~~~~~~~~~~~Print compiled data list to serial port~~~~~~~~~~~~~~~~~~~~~
      float currentDataSet[] = {execTime, batteryLevel, vehicleSpeed, vehicleAccel, engineTemp, vehicleIndicators};
      for(int i=0; i < sizeof(currentDataSet)/sizeof(float); i++)
      {
        if(xbeeMode)
        {
          if(SDMode)
          {
            //SD with Xbee yet to be added, but should be much the same as below
            Serial.println("SD with Xbee yet to be added, but should be much the same");
          }
          else
          {
            Serial.println("Sending data...");
            Serial2.print(currentDataSet[i]);
            Serial2.print(" ");
            if(i == (sizeof(currentDataSet)/sizeof(float) - 1)) Serial2.print("\r");
          }
        }
        else                                  //  If Xbees aren't being used UART1
        {                                     //  is used instead.
          if(SDMode)                    
          {                                   //  If SD selected run SD routines
            // SD Card Implementation
            if(myFile) {
              Serial.println("---- WRITING TO SD ---- "); // Testing if SD Card Works
              myFile.print(currentDataSet[i]);           // Print dataset to SD Card
              myFile.print(" ");                         // Formatting
              if(i == (sizeof(currentDataSet)/sizeof(float) - 1)) myFile.print("\r");
            }
            
            if (n==100)                                 // SD Card Close Loop
            {                                           // Close to be Impl. by Plotter
              Serial.println("---- CLOSE SD ----");     // Testing if SD Card Works
              myFile.close();
            }
            
            //Serial.print(currentDataSet[i]);           // Print dataset to Serial
            //Serial.print(" ");
            
            if(i == (sizeof(currentDataSet)/sizeof(float) - 1)) Serial.print("\r");
          }
          else                                //  If SD is not selected, simply print 
          {                                   //  data to UART1.
            Serial.print(currentDataSet[i]);           // Print dataset to Serial
            Serial.print(" ");
            
            if(i == (sizeof(currentDataSet)/sizeof(float) - 1)) Serial.print("\r");
          }
        }
      }
      delay(100);
      n++;                                   //  Increment loop counter
    }                                        
  }                                          
  
  // each while loop has a wait 1000 milliseconds before the loop
  // repeats for the output to be constant and not
  // spam the other end.
}

//============================Configuration String Function==============================
void sendConfigString()
{                
                    //  Configuration string is sent in the format of:
                    //    "? DS_1_Name DS_2_Name DS_3_Name DS_4_Name DS_5_Name DS_6_Name \r"
                    //
                    //  So, the default for Mock Data Mode will be the following:
                    //    "? T A B C D E \r"
                      
    if(mockMode)  Serial2.print("? T A B C D E \r");
    else
    {
                      // Real data set names can be set by the variables above, or
                      //  may defined by other program functionality in the future.
      Serial2.print("? ");
      Serial2.print(DataSet1_Name);
      Serial2.print(" ");
      Serial2.print(DataSet2_Name);
      Serial2.print(" ");
      Serial2.print(DataSet3_Name);
      Serial2.print(" ");
      Serial2.print(DataSet4_Name);
      Serial2.print(" ");
      Serial2.print(DataSet5_Name);
      Serial2.print(" ");
      Serial2.print(DataSet6_Name);
      Serial2.print(" \r");
      delay(100);  
    }
    return;
}
