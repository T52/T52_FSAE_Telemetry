/*                                                                          12TH NOV 2014
=========================================================================================
======================== Engineering Design 3A - FSAE TEAM 52 ===========================
=========================================================================================
==================   This program plots and logs serial data to a     ===================
==================   .CSV file. The plotter is designed to be used    ===================
==================   in conjunction with the 'Launchpad Data          ===================
==================   Processor' program to manage the transmission    ===================
==================   of data to and from the remote microcontroller.  ===================
==================                                                    ===================
==================   Most program functionality is controllable       ===================
==================   from the GUI, however, those that are not,       ===================
==================   can be set manually by the variables below:      ===================
==================                                                    ===================
==================   serialPortName: Sets the computer serial port    ===================
==================   that the wireless module is connected to.        ===================
==================                                                    ===================
==================   Baudrate: Sets the serial baud rate of           ===================
==================   the serial port. For these Xbee modules, this    ===================
==================   should remain at 115200.                         ===================
==================                                                    ===================
==================   sigNum: Sets the number of signals to be         ===================
==================   transmitted, plotted, and logged. This           ===================
==================   variable should be the same for the 'Launchpad   ===================
==================   Data Processor also'.                            ===================
==================                                                    ===================
=========================================================================================
*/





//===============================import general libraries================================
import controlP5.*; //GUI drawer
import processing.serial.*; //serialport handler





//==============================import Java Core Libraries===============================
import java.awt.Frame;
import java.awt.BorderLayout;
import java.applet.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 





//===================================Program Settings====================================
String serialPortName = "COM12";          // - Select Serial port to connect to.
int Baudrate = 115200;                   // - Set baud rate (by default 115200).

int sigNum = 6;                          // - Allows for varied number of signals, for 
                                         // testing purposes.


                                         
//================================Setup Global Variables=================================
Serial serialPort;                       // - Create Serial port object.
ControlP5 cp5;                           // - Define GUI variable.
JSONObject plotterConfigJSON;            // - Set configuration file, to save plotter 
                                         // settings.





//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Plotting Variables~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                                    // - Define line graph GUI object
Graph LineGraph = new Graph(225, 30, 600, 500, color (20, 20, 200)); 

//:::::::::::::::::::::::::::::::::Data Set Variables::::::::::::::::::::::::::::::::::::
                                         // - Define main data array. Each floatlist within
                                         // the array represents an individual data set.
                                         // The first data set is always the time base.
FloatList[] lineGraphDataList = new FloatList[sigNum];  
String myString = "";                    // - String to hold the most recent sample.
String[] nums;                           // - Array to hold the individual values of each
                                         // data set. 
int timeIndexMin = 0;                    //  - Creates index references for the sections 
int timeIndexMax = 0;                    //  of the data array to be plotted.  

//::::::::::::::::::::::::::::::::GUI Display Variables::::::::::::::::::::::::::::::::::
color[] graphColors = new color[10];     // - Define graph colour objects.
color[] fontColors = new color[3];       // - Define font colours.
PFont[] textFonts = new PFont[3];        // - Define fonts.

                                         // - Define array of text labels for displaying 
                                         // current vehicle stats.
Textlabel[] vehicleStats = new Textlabel[5];
Textarea[] terminal = new Textarea[1];   // - Define text area for GUI terminal display.



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Create event flags~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//::::::::::::::::::::::::::::::::::::GUI Flags:::::::::::::::::::::::::::::::::::::::::
boolean rangeFlag = false;               // - Flag to monitor status of slider while in
                                         // time base mode.
                                         
boolean resetFlag = false;               // - Flag to signal a reset occuring.

boolean startFlag = false;               // - Flag to signal transmissions start.

//:::::::::::::::::::::::::::::::::::State Flags::::::::::::::::::::::::::::::::::::::::
boolean xbeeConfigFlag = false;          // - Flag that disables serialEvent in
                                         // instances where xbee config is run
                                         
boolean downloadFlag = false;            // - Flag to recognise that a download
                                         // has been initiated.
                                         
boolean plotTrigger = false;             // - Flag to trigger a plot routine. This is
                                         // set after data is added to the lineGraphDataList
                                         // arrays.
                                         
boolean readError = false;               // - Flag to signify a read error, prompting
                                         // a change to the LED.
                                         
boolean appendData = false;              // - Flag to determine how information should be
                                         // added to the arrays after a download request.
                                         
                                         // i.e. If anything other than the most recent
                                         // file is requested, the arrays are cleared, and
                                         // downloaded data should be appended rather than
                                         // inserted into existing data.

//:::::::::::::::::::::::::::::::::Legend References::::::::::::::::::::::::::::::::::::
int speedArrayRef = 0;                   // - Act as references to the GUI as whether
int batteryArrayRef = 0;                 // the expected data sets of speed, battery, and
int tempArrayRef = 0;                    // temperature have been confirmed by the legend.

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Data Logging Information~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
String topSketchPath = "";               // - Helper for saving the executing 
                                         // path.
String dataFolder;                       // - Setup datalog output.
PrintWriter output;                      // - Output variable for logging data.





//==================================Program Setup=======================================
void setup() 
{                                        // - Add a window title.
  frame.setTitle("RMIT T52FSAE Realtime Serial Data Plotter");     
  size(1020, 690);                       // - Define window size.
  background(255);                       // - Set background color.
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~set line graph colors~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  graphColors[0] = color(255, 102, 102);
  graphColors[1] = color(255, 153, 51);
  graphColors[2] = color(230, 230, 0);
  graphColors[3] = color(102, 204, 0);
  graphColors[4] = color(0, 153, 76);
  graphColors[5] = color(102, 255, 255);
  graphColors[6] = color(51, 153, 255);
  graphColors[7] = color(127, 0, 255);
  graphColors[8] = color(204, 0, 204);
  graphColors[9] = color(102, 0, 51);

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Set Font Colors~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  fontColors[0] = color(0, 0, 0);        // - Black font.
  fontColors[1] = color(255, 0, 0);      // - Red font.
  fontColors[2] = color(0, 255, 0);      // - Green font.
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Set Fonts~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  textFonts[0] = createFont("arial", 12);
  textFonts[1] = createFont("arial", 10);
  textFonts[2] = createFont("courier Bold", 18);
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~Graph Settings save file~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  topSketchPath = sketchPath;            // - Set sketch path.
                                         // - Set config file location.
  plotterConfigJSON = loadJSONObject(topSketchPath+"/datalog_config.json");
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~Set Datalog name and location~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  dataFolder = "Datalog/";               // - set top level save folder
  String fileName = new SimpleDateFormat("yyyy-MM-dd'_T['HH''mm''ss'].csv'").format(new Date());
  output = createWriter(dataFolder + fileName);
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~create GUI  object~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  cp5 = new ControlP5(this);             // - Create GUI class object
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~Start Serial Communication~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                         // - Create serial port object
  serialPort = new Serial(this, serialPortName, Baudrate);
  xbeeConfigFlag = true;                 // - Set config flag to disable serial interrupt
                                         // while configuring Xbee module.
  xbeesetupfunct();                      // - Run xbee configuration/
  serialPort.write("~~~");               // - Stop transmission (if running).
                                         // - Flush the serial buffer
  while(serialPort.available() > 0) serialPort.readBytesUntil('\r', inBuffer);
  serialPort.clear();
  serialPort.bufferUntil('\r');          // - Buffers serial data until carriage return
                                         // is received before triggering interrupt.
  
  //~~~~~~~~~~~~~~~Save some default plotter configuration settings~~~~~~~~~~~~~~~~~~~
  plotterConfigJSON.setString("lgMinX", "0");              // - Set X-axis minimum
  plotterConfigJSON.setString("lgMaxX", "0");              // - Set X-axis maximum
  plotterConfigJSON.setString("Plot Pause", "0");          // - Unpause by default
  plotterConfigJSON.setString("Transmit Stat", "0");       // - Not transmitting by 
                                                           // default
                                         // - Save settings to config file
  saveJSONObject(plotterConfigJSON, topSketchPath+"/datalog_config.json");
  
  //~~~~~~~Setup array of lists used to plot a continually expanding data set~~~~~~~~~
  for(int i=0; i<sigNum; i++)
  {
     lineGraphDataList[i] = new FloatList();
     //lineGraphDataList[i].append(0);    // - Set first value to 0.
  }
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Build the GUI~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  int x = 0;                            // - X and Y variables for drawing GUI.
  int y = 0;
  final int yRangeX = 150;              // - Static positions and properties of GUI 
  final int yRangeY = 60;               // elements.
  final int leftMargin = 10;
  final int rightMargin = 10;
  final int topMargin = 10;
  final int leftTextMargin = leftMargin - 4;
  final int rightTextMargin = rightMargin + 4;
  final int ySpacing = 2;
  final int xDataSetToggle = leftMargin;
  final int yDataSetToggle = 200;
  final int xDataSetMultipliers = 60;
  final int fieldHeight = 20;
  final int fieldWidth = 40;
  final int xButtonCentre = leftMargin + 52;
  final int transButtonWidth = 112;
  final int buttonWidth = 52;
  final int yErrorField = 130;
  final int xErrorLED = 100;
  final int errorLEDHeight = 14;
  final int errorLEDWidth = 20;
  final int xSlider = 225;
  final int ySlider = 50;
  final int sliderWidth = 605;
  final int sliderHeight  = 10;
  final int xErrorMessage = 260;
  final int yErrorMessage = 300;
  final int xTimerButton = 900;
  final int yTimerButton = 500;
  final int timerButtonWidth = 58;
  final int xLegend = 750;
  final int yLegend = 70;
  final int xVehicleStats = 880;
  final int yVehicleStats = 40;
  final int vehicleStatBoxWidth = 100;
  final int vehicleStatBoxHeight = 32;
  final int yTerminal = 580;
  final int terminalWidth = 1000;
  final int terminalHeight = 70;
  
  
  //:::::::::::::::::::::Adds fields to set the range of the Y-axis:::::::::::::::::::::
  x = yRangeX;
  y = yRangeY;
  cp5.addTextfield("lgMaxY").setPosition(x, y=y).setText(getPlotterConfigString("lgMaxY")).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMinY").setPosition(x, y=y+477).setText(getPlotterConfigString("lgMinY")).setWidth(40).setAutoClear(false);
  
  //:::::::::::::::::::::::::::::::Main GUI button labels:::::::::::::::::::::::::::::::
  cp5.addTextlabel("on/off").setText("On/Off").setPosition(leftTextMargin, yDataSetToggle).setColor(fontColors[0]).setHeight(fieldHeight);
  cp5.addTextlabel("multipliers").setText("Multipliers").setPosition(xDataSetMultipliers-4, yDataSetToggle).setColor(fontColors[0]).setHeight(fieldHeight);
  
  //::::::::::::::::::::::::::::::multipliers for data sets:::::::::::::::::::::::::::::
  x = xDataSetMultipliers;
  y = yDataSetToggle - fieldHeight;
  for(int i=1; i<=sigNum; i++)
    cp5.addTextfield("lgMultiplier"+i).setPosition(x, y=y+2*fieldHeight).setText(getPlotterConfigString("lgMultiplier"+i)).setWidth(fieldWidth).setHeight(fieldHeight).setAutoClear(false);
  
  //::::::::::::::::::::::::::::toggle switches for data sets:::::::::::::::::::::::::::
  x = xDataSetToggle;
  y = yDataSetToggle - fieldHeight;
  for(int i=1; i<=sigNum; i++)
    cp5.addToggle("lgVisible"+i).setPosition(x, y=y+2*fieldHeight).setHeight(fieldHeight).setValue(int(getPlotterConfigString("lgVisible"+i))).setMode(ControlP5.SWITCH).setColorActive(graphColors[i-1]);
  
  //::::::::::::::::::::::::::::::::labels for data sets::::::::::::::::::::::::::::::::
  x = leftTextMargin;
  y = yDataSetToggle + ySpacing;
  for(int i=1; i<=sigNum; i++)
    cp5.addTextlabel("Data Set "+i).setText("Data Set "+i).setPosition(x, y=y+2*fieldHeight).setHeight(fieldHeight).setColor(fontColors[0]).setColorBackground(graphColors[0]); //Change as needed
  
  //::::::::::::::::::::::::::::::::::Button controls:::::::::::::::::::::::::::::::::::
  x = xButtonCentre;
  y = topMargin;
  
  cp5.addButton("Start/Stop Transmission").setPosition(x-transButtonWidth/2,y).setWidth(transButtonWidth).setHeight(fieldHeight);
  
  x = xButtonCentre - buttonWidth/2;
  cp5.addButton("Plot Pause").setPosition(x,y=y+fieldHeight+ySpacing).setWidth(buttonWidth).setHeight(fieldHeight);
  cp5.addButton("Reset Plot").setPosition(x, y=y+fieldHeight+ySpacing).setWidth(buttonWidth).setHeight(fieldHeight);
  cp5.addButton("Download").setPosition(x, y=y+fieldHeight+ySpacing).setWidth(buttonWidth).setHeight(fieldHeight);  
  cp5.addButton("Save & Quit").setPosition(x,y=y+fieldHeight+ySpacing).setWidth(buttonWidth).setHeight(fieldHeight);
  
  //::::::::::::::::::::::::::::::::Add Indicator Labels::::::::::::::::::::::::::::::::
  x = leftTextMargin;
  y = yErrorField;

  cp5.addTextlabel("Read Error Detected").setText("Read Error Detected").setPosition(x, y).setColor(fontColors[0]).setHeight(fieldHeight);
  cp5.addTextlabel("Time Base Error").setText("Time Base Error").setPosition(x, y=y+fieldHeight).setColor(fontColors[0]).setHeight(fieldHeight);
  cp5.addTextlabel("Resolution Exceeded").setText("Resolution Exceeded").setPosition(x, y=y+fieldHeight).setColor(fontColors[0]).setHeight(fieldHeight);
  
  //::::::::::::::::::::::::::::::::::Add Indicator LEDs::::::::::::::::::::::::::::::::
  x = xErrorLED;
  y = yErrorField - ySpacing;
  
  fill(0, 255, 0);                     // - Read Error     
  stroke(255);                         
  rect(x, y, errorLEDWidth, errorLEDHeight);        
  
  fill(0, 255, 0);                     // - TimeBase Error        
  stroke(255);                         
  rect(x, y=y+fieldHeight, errorLEDWidth, errorLEDHeight);   
  
  fill(0, 255, 0);                     // - Resolution Error        
  stroke(255);                         
  rect(x, y=y+fieldHeight, errorLEDWidth, errorLEDHeight);   

  //::::::::::::::::::::::::::slider for time/sample range::::::::::::::::::::::::::::
  cp5.addRange("scaleRangeControl", 0, 100, 0, 100, xSlider, ySlider, sliderWidth, sliderHeight);
  
  //:::::::::::::::::::::::::::::::Reset error message::::::::::::::::::::::::::::::::
  cp5.addTextlabel("Reset Message").setPosition(xErrorMessage, yErrorMessage).setVisible(false).setColor(fontColors[1]).setText("An error has occurred in the timebase received. This could be due to a hardware reset. Please press Plot Reset to resume plotting.");    
  
  //:::::::::::::::::::::::::::::::::Reset Timer Button:::::::::::::::::::::::::::::::
  cp5.addButton("Reset Timer").setPosition(xTimerButton, yTimerButton).setWidth(timerButtonWidth);
  cp5.addTextlabel("Timer Label").setPosition(xVehicleStats, yTimerButton + fieldHeight).setColor(fontColors[0]).setText("Current Time").setFont(textFonts[1]);
  
  fill(0,0,0);                         // - Timer Display box
  stroke(255,255,255);
  rect(xVehicleStats, yTimerButton + 2*fieldHeight, vehicleStatBoxWidth, vehicleStatBoxHeight);
  
  //::::::::::::::::::::::::::::::::Add Data Set Legend:::::::::::::::::::::::::::::::::
  x = xLegend;
  y = yLegend;
  cp5.addTextlabel("Data Legend:").setText("Data Legend:").setPosition(x, y).setColor(fontColors[0]).setFont(textFonts[0]);
  
  x = xLegend + 10;
  for(int i=1; i<=sigNum; i++)
    cp5.addTextlabel("Data Label " + i).setText("Data Set " + i).setPosition(x, y=y+20).setColor(graphColors[i-1]);

  //::::::::::::::::::::::::::::::Add Vehicle Stat Displays:::::::::::::::::::::::::::::
  x = xVehicleStats;
  y = yVehicleStats;
  cp5.addTextlabel("Current Vehicle Stats").setPosition(x, y).setColor(fontColors[0]).setText("Current Vehicle Stats").setFont(textFonts[0]);
  cp5.addTextlabel("Current Speed Label").setPosition(x, y=y+20).setColor(fontColors[0]).setText("Current Speed:").setFont(textFonts[1]);
  cp5.addTextlabel("Maximum Speed Label").setPosition(x, y=y+100).setColor(fontColors[0]).setText("Max Speed:").setFont(textFonts[1]);
  cp5.addTextlabel("Battery Remaining Label").setPosition(x, y=y+100).setColor(fontColors[0]).setText("Battery Remaining:").setFont(textFonts[1]);
  cp5.addTextlabel("Current Temperature Label").setPosition(x, y=y+100).setColor(fontColors[0]).setText("Current Temperature:").setFont(textFonts[1]);
  
  
  vehicleStats[0] = cp5.addTextlabel("Current Speed").setPosition(x, y=yVehicleStats+40).setColor(fontColors[2]).setText("0.00").setFont(textFonts[2]);
  vehicleStats[1] = cp5.addTextlabel("Maximum Speed").setPosition(x, y=y+100).setColor(fontColors[2]).setText("0.00").setFont(textFonts[2]);
  vehicleStats[2] = cp5.addTextlabel("Battery Remaining").setPosition(x, y=y+100).setColor(fontColors[2]).setText("100%").setFont(textFonts[2]);
  vehicleStats[3] = cp5.addTextlabel("Current Temperature").setPosition(x, y=y+100).setColor(fontColors[2]).setText("0.00").setFont(textFonts[2]);
  vehicleStats[4] = cp5.addTextlabel("Timer").setPosition(x, y=y+200).setColor(fontColors[2]).setFont(textFonts[2]);
 
  //:::::::::::::::::::::Add Displays for current Vehicle Stats::::::::::::::::::::
  y = yVehicleStats + 2*fieldHeight - 4;
  fill(0,0,0);
  stroke(255, 255, 255);
  rect(x, y, vehicleStatBoxWidth, vehicleStatBoxHeight);
  
  fill(0,0,0);
  stroke(255, 255, 255);
  rect(x, y=y+100, vehicleStatBoxWidth, vehicleStatBoxHeight);
  
  fill(0,0,0);
  stroke(255, 255, 255);
  rect(x, y=y+100, vehicleStatBoxWidth, vehicleStatBoxHeight);
  
  fill(0,0,0);
  stroke(255, 255, 255);
  rect(x, y=y+100, vehicleStatBoxWidth, vehicleStatBoxHeight);
  
  //:::::::::::::::::::::::::::::::Add terminal window:::::::::::::::::::::::::::::
  terminal[0] = cp5.addTextarea("Terminal").setPosition(leftMargin, yTerminal).setWidth(terminalWidth).setHeight(terminalHeight).setColorBackground(0).setFont(textFonts[0]);  
  terminal[0].setText("--------------------------------------------------------------------------------------------------Data Plotter Terminal Window------------------------------------------------------------------------------------------------------------\n");
  terminal[0].scroll(1);
  
  //:::::::::::::::::::::::::::::Add terminal text field:::::::::::::::::::::::::::
  cp5.addTextlabel("Command:").setText("Command:").setPosition(leftMargin,y=yTerminal+75).setWidth(terminalWidth).setHeight(fieldHeight).setFont(textFonts[0]).setColor(fontColors[0]);
  cp5.addTextfield("Terminal Command").setPosition(leftMargin+65, y).setWidth(terminalWidth-65).setHeight(fieldHeight).setColorBackground(0).setFont(textFonts[0]);
}





//===================================Main Program Loop==================================
void draw() 
{
  xbeeConfigFlag = false;                      // - After setup, reactivate the serialEvent
                                               // routine.
                                               
  //~~~~~~~~~~~~~~~~~~~Read in serial stream and if data is available~~~~~~~~~~~~~~~~~~~
  if (plotTrigger  && !resetFlag) {
    //String todlog = "";
    background(255);                           // - Set Main background colour.

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Check for read errors~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    final int yErrorField = 130;
    final int xErrorLED = 100;
    final int errorLEDHeight = 14;
    final int errorLEDWidth = 20;
    final int fieldHeight = 20;
    
    if(!readError) 
    {   
      fill(0, 255, 0);                         // - Display green (no errors).     
      stroke(255);                         
      rect(xErrorLED, yErrorField, errorLEDWidth, errorLEDHeight);                  
    }
    else
    {
      fill(255, 0, 0);                         // - Display red (read errors detected).
      stroke(255);
      rect(xErrorLED, yErrorField, errorLEDWidth, errorLEDHeight);                      
    }

    //~~~~~~~~~~~~~~~~count number of line graphs to hide [linked to GUI]~~~~~~~~~~~~~~~
    int numberOfInvisibleLineGraphs = 0;
    for (int i=0; i<sigNum; i++) {
      if (int(getPlotterConfigString("lgVisible"+(i+1))) == 0) {
        numberOfInvisibleLineGraphs++;
      }
    }
    
    //:::::::::::::::::Isolate time base data set into its own array:::::::::::::::::
    float[] timeBase = lineGraphDataList[0].array();
                                               // - Y Coordinates for timeBase LED.
    final int yTimeBase = yErrorField + fieldHeight;
                                               // - Check that timebase is continually 
                                               // ascending, if not, then a reset may  
                                               // have occurred on the sending module.   
                                               
    if((timeBase[0] != min(timeBase)) || (timeBase[timeBase.length-1] != max(timeBase)))         
    {                                          // - If not, an error indicator turns red.
      println(timeBase);
      fill(255, 0, 0);                       
      stroke(255);
      rect(xErrorLED, yTimeBase, errorLEDWidth, errorLEDHeight);                    
                                               // - Display an error message to user.
      Textlabel resetMessage = ((Textlabel)cp5.getController("Reset Message"));
      resetMessage.setVisible(true);
      terminal[0].append("An error has occurred in the timebase received. This could be due to a hardware reset. Please press Plot Reset to resume plotting.\n");
      return;
    }
    else                                     // - Else, it remains green.
    {
      fill(0, 255, 0);
      stroke(255);
      rect(xErrorLED, yTimeBase, errorLEDWidth, errorLEDHeight);                                
      
      Textlabel resetMessage = ((Textlabel)cp5.getController("Reset Message"));
      resetMessage.setVisible(false);
    }
    
    //::::::::::::::::::::::Timer to display most recent sample::::::::::::::::::::::
    float timeDiv = 1;
    if(timeBase[timeBase.length-1] > 60)    timeDiv = 60;
    if(timeBase[timeBase.length-1] > 3600)  timeDiv = 3600;
    if(timeDiv == 1) vehicleStats[4].setText(nf(timeBase[timeBase.length-1]/timeDiv, 2, 2) + "s");
    if(timeDiv == 60) vehicleStats[4].setText(nf(timeBase[timeBase.length-1]/timeDiv, 2, 2) + "m");
    if(timeDiv == 3600) vehicleStats[4].setText(nf(timeBase[timeBase.length-1]/timeDiv, 2, 2) + "h");

    //:::::::::::::::::::::Add Displays for current Vehicle Stats::::::::::::::::::::
    final int xVehicleStats = 880;
    int yVehicleStats = 36 + 2*fieldHeight;
    final int vehicleStatWidth = 100;
    final int vehicleStatHeight = 32;
    
    fill(0,0,0);
    stroke(255, 255, 255);
    rect(xVehicleStats, yVehicleStats, vehicleStatWidth, vehicleStatHeight);
    
    fill(0,0,0);
    stroke(255, 255, 255);
    rect(xVehicleStats, yVehicleStats = yVehicleStats+100, vehicleStatWidth, vehicleStatHeight);
    
    fill(0,0,0);
    stroke(255, 255, 255);
    rect(xVehicleStats, yVehicleStats = yVehicleStats+100, vehicleStatWidth, vehicleStatHeight);
    
    fill(0,0,0);
    stroke(255, 255, 255);
    rect(xVehicleStats, yVehicleStats = yVehicleStats+100, vehicleStatWidth, vehicleStatHeight);
    
    fill(0,0,0);
    stroke(255,255,255);
    rect(xVehicleStats, yVehicleStats = yVehicleStats+164, vehicleStatWidth, vehicleStatHeight);
    
    //::::::::::::::::::::::::::Save range settings to file::::::::::::::::::::::::::   
    
    timeDiv = 1;
    int timeRes = 20;

    if(getPlotterConfigString("Plot Pause") == "1"); //  If pause has been pressed,
                                                     //  leave indexes unchanged.
                                                     
    else if(rangeFlag == false)              //  If range slider has not been moved
    {                                        //  or is at full range, set limits
                                             //  to array boundaries.
      if((max(timeBase)-min(timeBase)) > 60) timeDiv = 60;
      if((max(timeBase)-min(timeBase)) > 3600) timeDiv = 3600;
      
      plotterConfigJSON.setString("lgMinX", (min(timeBase)/timeDiv)+ "");
      plotterConfigJSON.setString("lgMaxX", (max(timeBase)/timeDiv)+ "");
      timeIndexMax = timeBase.length - 1;    //  Set the maximum index to the length
    }
     
    else                    //  Determine the appropriate range to plot depending on the 
    {                       //  range value set.
      int i=0; 
      for(i=0; i<(timeBase.length-1); i++)  //  Finds the index of the minimum x value
      {
        if(timeBase[i] >= (min(timeBase) + (float(getPlotterConfigString("minRange"))/100)*(max(timeBase)-min(timeBase))))
        {
          timeIndexMin = i;
          break;
        }
        else  timeIndexMin = 0;
      }
      for(i=i; i<(timeBase.length-1); i++)  //  Finds the index of the maximum x value
      { 
        if(timeBase[i] >= (min(timeBase) + (float(getPlotterConfigString("maxRange"))/100)*(max(timeBase)-min(timeBase))))
        {
          timeIndexMax = i;
          break;
        }
        else  timeIndexMax = timeBase.length - 1;
      }
      
      if((timeBase[timeIndexMax] - timeBase[timeIndexMin]) > 60) timeDiv = 60;
      if((timeBase[timeIndexMax] - timeBase[timeIndexMin]) > 3600) timeDiv = 3600;
      
                          //  Save these ranges to the config file
      plotterConfigJSON.setString("lgMinX", (timeBase[timeIndexMin]/timeDiv)+ "");
      plotterConfigJSON.setString("lgMaxX", (timeBase[timeIndexMax]/timeDiv)+ "");
    }
    
    if((max(timeBase)/timeDiv) > 1000) timeRes = 15;
    if((max(timeBase)/timeDiv) > 10000) timeRes = 10;
    if((max(timeBase)/timeDiv) > 100000) timeRes = 5;
    plotterConfigJSON.setString("lgDivX", timeRes + "");
    
    
    saveJSONObject(plotterConfigJSON, topSketchPath+"/datalog_config.json");
    setChartSettings();   //  The x axis is thus updated by referencing the saved value.
    
                          //  Given the range, checks whether graph has sufficient
                          //  resolution
    int yResolution = yTimeBase + fieldHeight;
    if(timeBase[timeIndexMax] <= timeBase[timeIndexMin])
    {                                    //  Displays red indicator for error
      fill(255, 0, 0);                       
      stroke(255);
      rect(xErrorLED, yResolution, errorLEDWidth, errorLEDHeight);                  
    }
    else
    {                                    //  Else, displays green
      fill(0, 255, 0);
      stroke(255);
      rect(xErrorLED, yResolution, errorLEDWidth, errorLEDHeight); 
    }
    
    //:::::::::::::::::::::::::::::draw the line graphs::::::::::::::::::::::::::::::
    LineGraph.DrawAxis();
    float[] currentDataSet;
    for (int i=0;i<sigNum; i++) 
    {
                          //  Puts each data set from list into an array temporarily
      currentDataSet = lineGraphDataList[i].array();
      
      if(configReceived)
      {                    //  Update stat displays to reflect their respective value.
        if(i == speedArrayRef)  //  The array references are updated after a config 
        {                       //  string is recieved, and depends on the data set names.
          
          vehicleStats[0].setText(nf(currentDataSet[currentDataSet.length-1], 0, 0) + "km/h");
          vehicleStats[1].setText(nf(max(currentDataSet), 0, 0) + "km/h");
        }
        if(i == batteryArrayRef)
          vehicleStats[2].setText(nf(currentDataSet[currentDataSet.length-1], 2, 2) + "%");
        if(i == tempArrayRef)
          vehicleStats[3].setText(nf(currentDataSet[currentDataSet.length-1], 2 ,2) + "°C");
      }
      
      LineGraph.GraphColor = graphColors[i]; //  Sets the color for each data set
      try  {
        if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
        { 
                          //  Plots a subset of the each array depending on the index 
                          //  limits determined.
           if(timeBase[timeBase.length-1] < 60)
           {
             LineGraph.LineGraph(subset(timeBase, timeIndexMin, (timeIndexMax - timeIndexMin)),
                           subset(currentDataSet, timeIndexMin, (timeIndexMax - timeIndexMin)));
           }
           else
           {
             float[]  timeBaseDiv = new float[timeBase.length];
             for(int d=0; d<timeBaseDiv[timeBaseDiv.length-1]; d++)  timeBaseDiv[d] = timeBase[d]/60;
             LineGraph.LineGraph(subset(timeBase, timeIndexMin, (timeIndexMax - timeIndexMin)),
                           subset(currentDataSet, timeIndexMin, (timeIndexMax - timeIndexMin)));
           }  
      }
      }
      catch (ArrayIndexOutOfBoundsException e)  {
                         //  This adds error checking if an invalid index position is specified 
                         //  by the variables above. This can occur as a result of an array
                         //  length mismatch, where one array has become shorter or longer than others.
                         
                         //  The routine  resets the index markers, and removes additional entries
                         //  from each data set, so that they match for future reference.
        println("Error: During plotting a mismatch in array sizes was detected");
        terminal[0].append("Error: During plotting a mismatch in array sizes was detected\n");
        println("Resetting time index variables");
        terminal[0].append("Resetting time index variables\n");
        timeIndexMax = currentDataSet.length-1;
        timeIndexMin = 0;
        println("Removing additional samples to match data set dimensions");
        terminal[0].append("Removing additional samples to match data set dimensions\n");
        int r=0;
        int lengthMin = 0;
        for(r=0; r<sigNum; r++)
        {
          if(r==0)  lengthMin = r;
          if(r>0 && (lineGraphDataList[r].size() < lineGraphDataList[r-1].size())) lengthMin = r;
        }
        for(r=0; r<sigNum; r++)
        {
          while(lineGraphDataList[r].size() > lineGraphDataList[lengthMin].size())
            lineGraphDataList[r].remove(lineGraphDataList[r].size()-1);
        }
      }    
    }    
  }
}






//==============Function to update graph ranges and parameters from file===============
void setChartSettings() {


  LineGraph.xLabel=" Time ";               //  Set scale for time base  
  LineGraph.yLabel="Value";
  LineGraph.Title="";  
  LineGraph.xDiv=int(getPlotterConfigString("lgDivX"));  
  LineGraph.xMax=float(getPlotterConfigString("lgMaxX")); 
  LineGraph.xMin=float(getPlotterConfigString("lgMinX"));  
  LineGraph.yMax=float(getPlotterConfigString("lgMaxY")); 
  LineGraph.yMin=float(getPlotterConfigString("lgMinY"));
}




//===========================Function to set Legend Labels============================
boolean configReceived = false;
void setLegendSettings()
{
  int startIndex = myString.indexOf("?") + 2;    //  Removes ? indicator character
  myString = myString.substring(startIndex, myString.length()-1);
  String[] legendLabels = split(myString, ' ');  //  Splits entries into an array
  
  for(int i=0; i<(legendLabels.length-1); i++)       //  Loops through the array setting
  {                                              //  corresponding text labels.
    Textlabel dataLabel = ((Textlabel)cp5.getController("Data Label " + (i+1)));
    dataLabel.setText(legendLabels[i].replace('_', ' '));
    if(legendLabels[i].equals("Speed")) speedArrayRef = i;
    if(legendLabels[i].equals("Level")) batteryArrayRef = i;
    if(legendLabels[i].equals("Engine_Temperature")) tempArrayRef = i;
  }
  configReceived = true;
  return;
}





void refreshDataSets()
{
  boolean indexFound = false;
  String[] nums;                           // - Array to hold the individual values of each
                                           // data set. 
  int indexPos = 0;
  int entryShift = 0;
  nums = split(myString, ' ');
  for(int w=0; w<(lineGraphDataList[0].size()-1); w++)
  {
    if(indexFound)              //  If index position has been found, begin reorganizing 
    {                           //  subsequent entries. 
      if(indexPos == (w-1))                      //  Firstly, appends previous last entry to end
      {                                          //  of table
        for(int l=0; l<(lineGraphDataList.length); l++)
          lineGraphDataList[l].append(lineGraphDataList[l].get(lineGraphDataList[l].size()-1));
      }
      else
      {                                          //  Shift each entry one place to the right
        for(int l=0; l<(lineGraphDataList.length); l++)
          lineGraphDataList[l].set((lineGraphDataList[l].size()-1)-entryShift, lineGraphDataList[l].get((lineGraphDataList[l].size()-1)-entryShift-1));
                                                 //  Once at the specified index, insert the new sample
        if(indexPos == ((lineGraphDataList[0].size()-1) - entryShift - 1))
        {
          for(int l=0; l<(lineGraphDataList.length); l++)
            lineGraphDataList[l].set((lineGraphDataList[l].size()-1)-entryShift-1, float(nums[l]));
          break;
        }
      }
      entryShift++;
    }
    else if(lineGraphDataList[0].get(w) == float(nums[0]))
    {
      println("Sample already received");
      break;
    }
    else if(lineGraphDataList[0].get(0) > float(nums[0]))
    {
      println("Index position found: 0");
      indexPos = 0;
      indexFound = true;
    }
    else if((lineGraphDataList[0].get(w) < float(nums[0])) && (lineGraphDataList[0].get(w+1) > float(nums[0])))
    {
      print("Index position found: ");
      indexPos = w+1;
      println(indexPos);
      indexFound = true;
    }
    else if(lineGraphDataList[0].get(lineGraphDataList[0].size()-1) < float(nums[0]))
    {
      println("Appending to existing data");
      for(int l=0; l<(lineGraphDataList.length); l++)
          lineGraphDataList[l].append(float(nums[l]));
      break;
    }
  }
  plotTrigger = true;
  return;
}





void appendDataSets()
{
  String[] nums;                           // - Array to hold the individual values of each
                                           // data set. 
  String todlog = "";
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~Prepare data strings~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  myString = myString + "\r";
  todlog = myString;
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~print to file/log~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  output.println(todlog.replace(" ",",").replace("\r",""));

  //~~~~~~~~~~~~~~~~~~~~~~~~split string at delimiter (space)~~~~~~~~~~~~~~~~~~~~~~~~~
  nums = split(myString, ' ');
  
  //:::::::::::Builds an array list that expands as more data is read in::::::::::::
                            //  Using a list rather than a multi dimensional array makes 
                            //  it simpler to expand dynamically as more data accumulates.
  for (int i=0; i<nums.length; i++) 
  {
    try {                                  // - Append sample values to the existing array.                                
      lineGraphDataList[i].append(float(nums[i])*float(getPlotterConfigString("lgMultiplier"+(i+1))));
    }
    catch (Exception e) {
      println("Error: Exception while appending new variables.");
    }
  }
  plotTrigger = true;
  return;
}





void downloadFilePrompt()
{
  plotterConfigJSON.setString("Terminal Command", "");
  saveJSONObject(plotterConfigJSON, topSketchPath+"/datalog_config.json");
  
  println("Choose SD file No. to download. Existing files are:");
  terminal[0].append("Choose SD file No. to download. Existing files are:\n");
  
  int c=1;
  while(myString.charAt(c) != '\r')
  {
    terminal[0].append("data"+ myString.charAt(c) + ".txt\n");
    c++;
  }
  terminal[0].append("\nEnter only the number specified in the desired file name\n");
  while(getPlotterConfigString("Terminal Command") == "");
  String userFile = getPlotterConfigString("Terminal Command");
  
  if(myString.indexOf(userFile) < 0)
  {
    terminal[0].append("Invalid selection. \n\n");
    downloadFilePrompt();
  }
  else
  {
    terminal[0].append("data"+ userFile + ".txt selected\n\n");
    String filesStored = new String(trim(myString).substring(1, trim(myString).length()));
    int[] fileNums = new int[filesStored.length()];
    for(int i=0; i<filesStored.length(); i++)
      fileNums[i] = int(str(filesStored.charAt(i)));
    

    if((myString.indexOf(userFile)-1) != max(fileNums))
    {

       for(int i=0; i<lineGraphDataList.length; i++)
       {
         lineGraphDataList[i].clear();                    //  Clears each data set
         //lineGraphDataList[i].append(0);                  //  Appends a 0 for the first element.   
       } 
       timeIndexMin = 0;                                //  Resets index min and max to 0
       timeIndexMax = 0;  
    }
    serialPort.write("%%" + userFile); 
    
    println("Closing CSV File");
    terminal[0].append("Closing CSV File\n");
    output.flush();                                    //  Flushes the output variable
    output.close();                                    //  Closes the output
    
    terminal[0].append("Opening new CSV log file.\n");
    String downloadName = new SimpleDateFormat("yyyy-MM-dd'_T['HH''mm''ss'][backup].csv'").format(new Date());
    output = createWriter(dataFolder + downloadName);
  }
  
  return;
}

//==========================Handler for reading serial data=========================
byte[] inBuffer = new byte[500];                  //  Buffer to hold serial message
void serialEvent(Serial p)
{
  plotTrigger = false;
  int endIndex = 0;                               // - Identifies the index position
                                                  // of the end of the data set.
  if(xbeeConfigFlag)   return;
  
  for(int i=0; i<499; i++) inBuffer[i] = 0;           // Flushes the buffer of old data.
  
  serialPort.readBytesUntil('\r', inBuffer);      //  Read serial data into buffer
                                              
  for(int i=0; i<499; i++)        //  Checks for invalid characters in buffer. If any are
  {                          //  found, handler returns, and data discarded.
    if(((inBuffer[i] < 48) || (inBuffer[i] > 57)) && inBuffer[i] != 32 && inBuffer[i] != 13 && inBuffer[i] != 0 && inBuffer[i] != 46 && inBuffer[i] != 45)
    {
      if(inBuffer[i] == 63)
      {
        try
        {
          myString = new String(inBuffer);
          setLegendSettings();
        }
        catch (Exception e) 
        {
          println("Error: Null found in config string.");
          terminal[0].append("Error: Null found in config string.\n");
        }
      }
      if(inBuffer[i] == 35)
      {
        myString = new String(inBuffer);
        println(myString);
        println("Download completed, acknowledgement recieved.");
        terminal[0].append("Download completed, acknowledgement received.\n");
        println("Closing CSV File");
        terminal[0].append("Closing CSV File\n");
        output.flush();                                    //  Flushes the output variable
        output.close();                                    //  Closes the output
        downloadFlag = false;
      } 
      if(inBuffer[i] == 37)
      {
        myString = new String(inBuffer);
        downloadFilePrompt();
      }
      if(inBuffer[i] == 36)  
      {
        resetFlag = false;
        serialPort.write("!$");
        println("Reset acknowledgement received");
      }
      return;
    }
  }
  
  if(resetFlag) return;
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~Assemble string of recieved data~~~~~~~~~~~~~~~~~~~~~~~~
  myString = new String(inBuffer);                              //  Remove carriage
  myString = myString.substring(0, myString.indexOf("\r", 0));  //  return for now. 
  
  if(downloadFlag) println(myString);                                                  
                             //  Removes additional spaces on the string
  while(myString.charAt(myString.length()-1) == ' ')  myString = trim(myString);

  //~~~~~~~~Determine the number of variables, and the index of the final value~~~~~~
  int i = 0;
  endIndex = 0;
  while(myString.indexOf(" ", endIndex) >= 0)     //  Loop while spaces can be found
  {
    endIndex = myString.indexOf(" ", endIndex);   //  Finds index of a space
    endIndex++;                                   //  Increments past the space
    i++;                     //  Increments the count of how many spaces have been found
  }
  
  if(i == (sigNum-1))                             //  There should always be one less space
  {
    if(downloadFlag)
    {
      if((lineGraphDataList[0].size()-1) <= 1)  appendData = true;
      if(appendData) appendDataSets();
      else refreshDataSets();
    }
    else if(startFlag && !resetFlag) appendDataSets();
    
  }
  else                                            //  than the number of signals. Thus, a 
  {                                               //  valid string is identified by sigNum-1.
    print("Read Error, String was: ");
    terminal[0].append("Read Error, String was: ");
    println(myString);                            //  Otherwise, print the invalid data
    terminal[0].append(myString);                 //  and reset string.
    terminal[0].append("\n");
    myString = "";                                
    readError = true;                             //  Also, indicate a read error for the
  }                                               //  GUI indicator. 
}





//================================GUI actions handler==================================
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isAssignableFrom(Textfield.class)  || 
      theEvent.isAssignableFrom(Toggle.class)     || 
      theEvent.isAssignableFrom(Button.class)     || 
      theEvent.isAssignableFrom(Slider.class)     || 
      theEvent.isAssignableFrom(Range.class)) 
  {
    String parameter = theEvent.getName();
    String value = "";
                              //  If triggered by one of the text fields
    if (theEvent.isAssignableFrom(Textfield.class))
    {
      value = theEvent.getStringValue();              //  Gets the value of the field
      plotterConfigJSON.setString(parameter, value);  //  Saves value to config file
    }  
                              //  If triggered by the range slider
    else if (theEvent.isAssignableFrom(Range.class))
    {
      value = str(theEvent.getArrayValue(0));          //  Gets the slider's min value
      plotterConfigJSON.setString("minRange", value);  //  Saves this to config file
      
      value = str(theEvent.getArrayValue(1));          //  Gets the slider's max value
      plotterConfigJSON.setString("maxRange", value);  //  Save this to config file
      
                              //  Checks whether the range is set to less than 100%
      if((theEvent.getArrayValue(0) != 0) || (theEvent.getArrayValue(1) != 100))
        rangeFlag = true;     //  If so, then triggers a flag which is referenced when 
      else                    //  plotting.
        rangeFlag = false;    //  If not, resets the flag to false.
    }
                              //  If triggered by dat set on/off toggles
    else if (theEvent.isAssignableFrom(Toggle.class))
    {
      value = theEvent.getValue()+"";     
      plotterConfigJSON.setString(parameter, value);
      
    }
                              //  If triggered by the "Begin Send" button
    else if(theEvent.isAssignableFrom(Button.class) && parameter == "Start/Stop Transmission")
    {                         //  Checks whether transmission has already been triggered
      if(getPlotterConfigString("Transmit Stat").equals("0"))
      {
        serialPort.write("!!!");                       //  If not, sends !!! to serial 
        value = 1 + "";                                //  and sets the config condition
        startFlag = true;
      }
      else
      {
        serialPort.write("~~~");                       //  If so, sends ~~~ to serial
        value = 0 + "";                                //  and resets the config condition
        startFlag = false;
      }
      plotterConfigJSON.setString("Transmit Stat", value);
    }
                              //  If triggered by the "Plot Pause" button
    else if (theEvent.isAssignableFrom(Button.class) && parameter == "Plot Pause")
    {                         //  Checks whether plot is currently paused, and toggles
                              //  to the opposite condition.
      if(getPlotterConfigString("Plot Pause") == "0")  value = 1 + "";
      else                                             value = 0 + "";
      
      plotterConfigJSON.setString(parameter, value);
    }
                              //  If triggered by the "Reset Plot" button
    else if (theEvent.isAssignableFrom(Button.class) && parameter == "Reset Plot")
    {
      for(int i=0; i<lineGraphDataList.length; i++)
      {
        lineGraphDataList[i].clear();                    //  Clears each data set

        timeIndexMin = 0;                                //  Resets index min and max to 0
        timeIndexMax = 0;
      }
    }
                              //  If triggered by the "Download" button
    else if (theEvent.isAssignableFrom(Button.class) && parameter == "Download")
    {
      serialPort.write("===");                           //  Send download initiation
      downloadFlag = true;
      println("Download Routine:");
      terminal[0].append("Download Routine:\n");
      
    }
                              //  If triggered by the "Save & Quit" button
    else if (theEvent.isAssignableFrom(Button.class) && parameter == "Save & Quit")
    {
      serialPort.write("~~~");                           //  Stop transmission before closing
      println("Save & Quit Triggered:");
      println("Closing CSV File");
      output.flush();                                    //  Flushes the output variable
      output.close();                                    //  Closes the output
      exit();                                            //  Closes the program
    }
    
    else if (theEvent.isAssignableFrom(Button.class) && parameter == "Reset Timer")
    {
      println("Reset Timer Triggered:");
      println("Closing CSV File");
      terminal[0].append("Reset Timer Triggered:\n");
      terminal[0].append("Closing CSV File\n");
      
      output.flush();                                    //  Flushes the output variable
      output.close();                                    //  Closes the output
      println("Creating new CSV log File");
      terminal[0].append("Creating new CSV log File\n");
      String downloadName = new SimpleDateFormat("yyyy-MM-dd'_T['HH''mm''ss'].csv'").format(new Date());
      output = createWriter(dataFolder + downloadName);
      
      
      String fileName = new SimpleDateFormat("yyyy-MM-dd'_T['HH''mm''ss'].csv'").format(new Date());
      output = createWriter(dataFolder + fileName);
      
      int transStat = int(getPlotterConfigString("Transmit Stat"));
      serialPort.write("---");
      
      for(int i=0; i<lineGraphDataList.length; i++)
        lineGraphDataList[i].clear();                    //  Clears each data set

      timeIndexMin = 0;                                //  Resets index min and max to 0
      timeIndexMax = 0;  
      resetFlag = true;      //  Sets the reset flag to true, which will disable any attempts
                             //  to plot data until the reset is recognised in the values
                             //  being read from the serial port.
    }

    saveJSONObject(plotterConfigJSON, topSketchPath+"/datalog_config.json");
  }

  setChartSettings();
}

// get GUI settings from settings from JSON file
String getPlotterConfigString(String id) {
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}
