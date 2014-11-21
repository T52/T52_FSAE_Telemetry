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
boolean mockMode = true;                  //  Defines which mode of operation to use.
                                           //    - True denotes Mock Data Mode
                                           //    - False denotes Data Acquistion Mode

boolean sendConfigInfo = true;             //  This is an option to send an initial
                                           //  set of configuration settings, giving
                                           //  the plotting program more information
                                           //  on what data it is handling.

int configUpdateLimit = 10;                //  If config info strings are enabled,
                                           //  sets the maximum time elapsed before
                                           //  program should send an config update.
                                           
boolean xbeeMode = true;                  //  This condition determines whether Xbees
                                           //  are being used. Usually this would be
                                           //  true, except for testing without the
                                           //  Xbee.
                                           
boolean SDMode = true;                    //  Condition to execute optional SD
                                           //  functionality. This is provided for
                                           //  testing purposes where the SD might
                                           //  not be used.

int sigNum = 9;                            //  This allows quick changes to be made to
                                           //  the number of signals when in mock mode,
                                           //  which helps with testing transmission 
                                           //  capacity.
                                           
int dataRateDelay = 20;                  //  Sets the delay between each transmission
                                           
//================================Setup Global Variables=================================                                            
float bdata = 0.00;   //set start point on 'B' data stream
float binc = 0.20;    //set increment on 'B' data stream
File myFile;
boolean transBegin = false;
                                            //  These are default names for data sets.
                                            //  They may be changed freely by user, or 
                                            //  program functions.
String DataSet1_Name = "Time_Base";
String DataSet2_Name = "HV_Voltage";
String DataSet3_Name = "HV_Amp";
String DataSet4_Name = "Inverter_Faults";
String DataSet5_Name = "Throttle_Position";
String DataSet6_Name = "Brake_Position";
String DataSet7_Name = "Car_Fault_Code";
String DataSet8_Name = "LV_Battery_Voltage";
String DataSet9_Name = "Energy_Used";

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
  Serial.println("----------Configuring Transmitting Xbee Module----------");
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
    
    Serial.println("OK received. Xbee Configuration complete\n");
    
      
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~SD Card Implementation~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if(SDMode)                              //  SD only needs to be initialized if SD is being
  {                                       //  used. Otherwise, initialization will fail.
    Serial.println("----------Configuring SD Card Backup----------");
    pinMode(10, OUTPUT);                  //  Setup pin configuration
    
    if (!SD.begin(4)) {                   //  Check if SD card is present
      Serial.println("Initialization failed: Card may not be present");
      return;
    }
                                          //  Delete existing data on SD card
    Serial.println("Erasing existing data on card...");
    boolean fileFlag = true;
    int m=0;
    while(fileFlag)
    {
       char fileName[15];
       sprintf(fileName, "data%d.txt", m);
       if(SD.exists(fileName))  
       {
         Serial.print("Removing ");
         Serial.println(fileName);
         SD.remove(fileName);
       }
       else fileFlag = false;
       m++;
    }
    Serial.println("All files removed");
    Serial.println("SD configuration complete.");
    
  }
    
  }
  
  //~~~~~~~~~~~~~~~~~~~~~~~Send Initial Configuration Information~~~~~~~~~~~~~~~~~~~~~~~~
  sendConfigString();
}

//=================================Main Program Loop=====================================
void loop() {
  float timeElapsed = 0;
  float addedTime = 0;
  float execTime = 0;
  float initRead = 0;
  float resetTime = 0;
  int n=0;                                // Count loops around print routine
  int i=0;
  int transStat = 0;
  int prevStat = 0;
  float batteryLevel = 100;                 //  100% battery by default
  float vehicleSpeed = 0;                   //  Speed starts at 0ms
  float vehicleAccel = 0;                   //  Acceleration starts at 0ms^2
  float engineTemp = 20;                    //  Engine temperature starts at 20 degrees
  int vehicleIndicators = 0;
  
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
        Serial.print("Received string was: ");
        Serial.println(String(start_buf));
        
        if(String(start_buf) == "!!!")  
        {
          Serial.println("----------Start Transmission Signal Received----------");
          createNewSDFile();
          transBegin = true;
        }
        if(String(start_buf) == "~~~")  
        {
          Serial.println("----------Stop Transmission Signal Received----------");
          closeSDFile();
          transBegin = false;
        }
        if(String(start_buf) == "---")
        {
          Serial.println("----------Timer Reset Signal Received----------");
          Serial2.println("$");
          Serial.println("Returned reset acknowledgement.");
          while(Serial2.available() < 2);
          memset(&start_buf, 0, sizeof(start_buf));
          Serial2.readBytes(start_buf, Serial2.available());
          Serial.print("Confirmation received: ");
          Serial.println(start_buf);
           
          n=0;
          initRead = 0;
          resetTime = execTime;
          closeSDFile();
          createNewSDFile();
        }
        if(String(start_buf) == "===")
        {
          Serial.println("Initiating SD Download");
          downloadSD();
        }
        char error_buf[1] = "";
        while(Serial2.available() > 0)
        {
          Serial.print(".");
          Serial2.readBytes(error_buf, 1);
        }
        Serial.println("Buffer Flushed.\n"); 
        
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
        if(String(start_buf) == "===")
        {
          Serial.println("Initiating SD Download");
          
        }
        
      }
      if(!transBegin) continue;
    }
    
    if(mockMode)
    {
      //~~~~~~~~~~~~~~~Print mock data string to serial port~~~~~~~~~~~~~~~~~~~~~~~~    
         float mockSig = 0;      
         for(i=0; i < sigNum; i++)
         {
           switch(i)
           {
             case(0):
             {
               mockSig = execTime;            // - Time Base
               break;
             }
             case(1):
             {
               mockSig = random(0, 500);      // - HV Voltage
               break;
             }
             case(2):
             {
               mockSig = random(0, 200);      // - HV Amp
               break;
             }
             case(3):
             {
               mockSig = random(0, 15);      // - Inverter Faults
               break;
             }
             case(4):
             {
               mockSig = random(0, 100);      // - Throttle Position
               break;
             }
             case(5):
             {
               mockSig = random(0, 100);      // - Brake Position
               break;
             }
             case(6):
             {
               mockSig = random(0, 15);      // - Car Fault Code
               break;
             }
             case(7):
             {
               mockSig = random(0, 150);      // - LV Battery Voltage
               break;
             }
             case(8):
             {
               mockSig = random(0, 800);      // - Energy Used
               break;
             }
             default:
             {
               Serial.println("Error: Number of signals exceeded");
               break;
             }
           }
  
           Serial2.print(mockSig);               
           Serial2.print(" ");
                                                 //  SD Card Implementation
          if(myFile) {
            myFile.print(mockSig);           // Print dataset to SD Card
            myFile.print(" ");                         // Formatting
           }
         }
         myFile.print("\r");
         Serial2.print(" \r");
         delay(dataRateDelay);
         n++; 
         
    }
    else
    {
      //~~~~~~~~~~~~~~~~~~~~~~~~~Generate Data for transmission~~~~~~~~~~~~~~~~~~~~~~~~~~
                                                //  Creates realistic string of variables as 
                                                //  to those that would be expected.
      
      
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
                                              //  Transmit each data set
            Serial2.print(currentDataSet[i]);
            Serial2.print(" ");
            if(i == (sizeof(currentDataSet)/sizeof(float) - 1)) Serial2.print("\r");
                                              //  SD Card Implementation
            if(myFile) {
              myFile.print(currentDataSet[i]);           // Print dataset to SD Card
              myFile.print(" ");                         // Formatting
              if(i == (sizeof(currentDataSet)/sizeof(float) - 1)) myFile.print("\r");
            }
          }
          else
          {
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
      delay(dataRateDelay);
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
    Serial2.print(" ");
    Serial2.print(DataSet7_Name);
    Serial2.print(" ");
    Serial2.print(DataSet8_Name);
    Serial2.print(" ");
    Serial2.print(DataSet9_Name);
    Serial2.print(" \r");
    delay(100);  
    return;
}

void downloadSD()
{
  String dataSet;
  int bytesStored = 0;
  int byteCount = 0;
          
                      //  Close and save current SD file
  Serial.println("SD File Saved.");
  myFile.close();
  
                      //  Determine how many files exist on SD card
  boolean fileFlag = true;
  int m=0;
  char fileName[15];
  while(fileFlag)
  {
     sprintf(fileName, "data%d.txt", m);
     if(SD.exists(fileName))  
     {
       Serial.print(fileName);
       Serial.println(" exists.");
     }
     else  
     {
       Serial.print(fileName);
       Serial.println(" does not exist.");
       fileFlag = false;
     }
     m++;
  }
  
                    //  Issue prompt to GUI on which file should be read
  Serial.println("Prompting user to select file");
  Serial2.print("%");
  for(int u=0; u<(m-1); u++)  
  {
    Serial2.print(u);
    Serial2.print(" ");
  }
  Serial2.print("\r");
                    //  Wait for response from GUI
  while(Serial2.available() == 0);
                    //  Read in response
  char file_buf[15] = "";
  Serial2.readBytes(file_buf, Serial2.available());
  String fileStr = "data" + String(file_buf) + ".txt";
  fileStr.toCharArray(fileName, fileStr.length() + 1);
  Serial.println(fileName);
                    //  Open selected file
  if(SD.exists(fileName))  myFile = SD.open(fileName, FILE_READ);
  else  
  {
    Serial.println("File selected does not exist. Download cancelled");
    return;
  }
  
  bytesStored = myFile.available();
  Serial.print(bytesStored);
  Serial.println(" bytes available on SD card.");
  
  while(byteCount <= bytesStored)
  {
    dataSet = "";
    for(int r=0; r<sigNum; r++)
    {
      String sampBuffer = "";
      int s=0;
      char sampChar;
      do
      {
        sampChar = myFile.read();
        byteCount++;
        sampBuffer += String(sampChar);
        s++;
      }  while((!String(sampChar).equals(" ")) && (byteCount <= bytesStored));
      dataSet += sampBuffer;
      if(byteCount > bytesStored) break;
    }
    if(byteCount >  bytesStored) break;
    
    Serial.print("Data Set was: ");
    Serial.println(dataSet);
    Serial2.print(dataSet);
    delay(100);
  }
  Serial2.print("\r");
  Serial2.print("#\r");
  Serial.println("Download complete.");
  
  closeSDFile();
  if(transBegin)  createNewSDFile();
  return;
}

void closeSDFile()
{
                            //  Close current SD file and create a new one
    Serial.println("Closing SD File...");
    myFile.close();
}
void createNewSDFile()
{                       
                            //  Check existing files to determine next file name
    Serial.println("Creating new SD File...");
    boolean fileFlag = true;
    int m=0;
    char fileName[15];
    while(fileFlag)
    {
       sprintf(fileName, "data%d.txt", m);
       if(SD.exists(fileName))   m++;  
       else                      fileFlag = false;
    }
    Serial.print("New file name is: ");
    Serial.println(fileName);
    myFile = SD.open(fileName, FILE_WRITE);
    
    return;
}
