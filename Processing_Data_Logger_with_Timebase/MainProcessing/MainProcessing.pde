/*                                                                         12th JULY 2014
=========================================================================================
======================== Engineering Design 3A - FSAE TEAM 52 ===========================
=========================================================================================
==================   This program plots and logs serial data to a     ===================
==================   .CSV file. The plotter can either plot each      ===================
==================   set of samples consecutively, or can plot        ===================
==================   them in reference to each sample's timestamp.    ===================
==================                                                    ===================
==================   The 'serialPortName' variable assigns the        ===================
==================   serial port that should be monitored, as does    ===================
==================   the 'Baudrate' variable define baud rate.        ===================
==================                                                    ===================
==================   It also contains a mockup program, that can      ===================
==================   generate simulation data for testing. These      ===================
==================   variables are controlled by the status of:       ===================
==================     - 'mockupSerial'  and                          ===================
==================     - 'serialTimebase'                             ===================
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
String serialPortName = "COM9";          //  Select Serial port to connect to.
int Baudrate = 115200;                     //  set data rate

int sigNum = 10;                         //  Allows for varied number of signals, for testing
                                         //  purposes
                                         
boolean mockupSerial = false;            //  If you want to debug the plotter without 
                                         //  using a real serial port set this to true.
                                         
boolean serialTimebase = true;           //  Additionally, set this to true to plot data 
                                         //  against the timebase in data set 1.

//================================Setup Global Variables=================================
Serial serialPort;                       //  Create Serial port object
ControlP5 cp5;                           //  Define GUI variable
JSONObject plotterConfigJSON;            //  Set configuration file, to save plotter 
                                         //  settings

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Plotting Variables~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Graph LineGraph = new Graph(225, 70, 600, 480, color (20, 20, 200)); 

float[][] lineGraphValues = new float[sigNum][100];      //  Data arrays when operating in  
float[] lineGraphSampleNumbers = new float[100];    //  sample mode.

FloatList[] lineGraphDataList = new FloatList[sigNum];   //  Arrays for operating in time
float[] currentDataSet;                             //  base mode. Using a list to store
float[] timeBase;                                   //  data makes dynamic expansion 
                                                    //  simpler as this can be difficult
                                                    //  with multidimensional data.

color[] graphColors = new color[10];                 //  Define graph colour objects
color[] fontColors = new color[3];                  //  Define font colours
PFont[] textFonts = new PFont[3];                   //  Define fonts
Textlabel[] vehicleStats = new Textlabel[5];

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Create event flags~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
boolean sliderFlag = false;                         //  Flag to monitor status of slider
boolean rangeFlag = false;                          //  while in time base mode.
boolean resetFlag = false;                          //  Flag to signal a reset occuring
boolean startFlag = false;                          //  Flag to signal transmissions start

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Data Logging Information~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
String topSketchPath = "";                          //  helper for saving the executing 
                                                    //  path.

String dataFolder;                                  //  Setup datalog output
PrintWriter output;                                 //  Output variable for logging data


//==================================Program Setup=======================================
void setup() {
  frame.setTitle("RMIT T52FSAE Realtime Serial Data Plotter");    //  Add a window title
  size(1020, 620);                                                 //  Define window size

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
  fontColors[0] = color(0, 0, 0);                  //  Black font
  fontColors[1] = color(255, 0, 0);                //  Red font
  fontColors[2] = color(0, 255, 0);                //  Green font
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Set Fonts~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  textFonts[0] = createFont("arial", 12);
  textFonts[1] = createFont("arial", 10);
  textFonts[2] = createFont("courier Bold", 18);
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~graph settings save file~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  topSketchPath = sketchPath;
  plotterConfigJSON = loadJSONObject(topSketchPath+"/datalog_config.json");
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~create GUI  object~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  cp5 = new ControlP5(this);
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~start serial communication~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (!mockupSerial)  
  {
    serialPort = new Serial(this, serialPortName, Baudrate);
    serialPort.write("~~~");                      //  Stop current transmission
    while(serialPort.available() > 0) serialPort.readBytesUntil('\r', inBuffer);
    serialPort.clear();
    int carriageRet = 13;
    serialPort.bufferUntil(carriageRet);
  }
  else                serialPort = null;
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~set datalog name and location~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  {
    dataFolder = "Datalog/";                       //  set top level save folder
    //String fileName = new SimpleDateFormat("yyyyMMddhhmm'.txt'").format(new Date());
    String fileName = new SimpleDateFormat("yyyy-MM-dd'_T['HH''mm''ss'].csv'").format(new Date());
    output = createWriter(dataFolder + fileName);
  }
  
  //~~~~~~~~~~~Setup the plotter to display in reference to samples or timebase~~~~~~~~~
  if(serialTimebase == false)                     //  Setup for plotting sample
  {
    //~~~~~~~~~~~~~~~save some default plotter configuration settings~~~~~~~~~~~~~~~~~~~
    plotterConfigJSON.setString("lgMinX", "-100");             //  Set X-axis minimum
    plotterConfigJSON.setString("lgMaxX", "0");                //  Set X-axis maximum
    saveJSONObject(plotterConfigJSON, topSketchPath+"/datalog_config.json");
    
    //~~~~~~~~~~~~~~~~~~~~build x axis values for the line graph~~~~~~~~~~~~~~~~~~~~~~~~
    for (int i=0; i<lineGraphValues.length; i++) {            //  Loops through data 
      for (int k=0; k<lineGraphValues[0].length; k++) {       //  array, initialising
        lineGraphValues[i][k] = 0;                            //  values to 0.
        
        if (i==0)                                 //    
          lineGraphSampleNumbers[k] = k;
      }
    }
  }
  else
  {
    //~~~~~~~~~~~~~~~save some default plotter configuration settings~~~~~~~~~~~~~~~~~~~
    plotterConfigJSON.setString("lgMinX", "0");              //  Set X-axis minimum
    plotterConfigJSON.setString("lgMaxX", "0");              //  Set X-axis maximum
    plotterConfigJSON.setString("Plot Pause", "0");          //  Unpause by default
     plotterConfigJSON.setString("Transmit Stat", "0");      //  Not transmitting by default
    saveJSONObject(plotterConfigJSON, topSketchPath+"/datalog_config.json");
    
    //~~~~~~~Setup array of lists used to plot a continually expanding data set~~~~~~~~~
    for(i=0; i<sigNum; i++)
    {
       lineGraphDataList[i] = new FloatList();
       lineGraphDataList[i].append(0);                      //  Set first value to 0.
    }
  } 
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Build the GUI~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  int x = 170;
  int y = 60;
  
  int lbx = 6;
  int lby = 205;
  
  //:::::::::::::::::::::Adds fields to set the range of the Y-axis:::::::::::::::::::::
  cp5.addTextfield("lgMaxY").setPosition(x, y=y).setText(getPlotterConfigString("lgMaxY")).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMinY").setPosition(x, y=y+477).setText(getPlotterConfigString("lgMinY")).setWidth(40).setAutoClear(false);
  
  //:::::::::::::::::::::::::::::::Main GUI button labels:::::::::::::::::::::::::::::::
  cp5.addTextlabel("on/off").setText("on/off").setPosition(x=13, y=200).setColor(fontColors[0]);
  cp5.addTextlabel("multipliers").setText("multipliers").setPosition(x=55, y).setColor(fontColors[0]);
  
  //::::::::::::::::::::::::::::::multipliers for data sets:::::::::::::::::::::::::::::
  x=60;
  y=180;
  for(int i=1; i<=sigNum; i++)
  {
    cp5.addTextfield("lgMultiplier"+i).setPosition(x, y=y+40).setText(getPlotterConfigString("lgMultiplier"+i)).setWidth(40).setAutoClear(false);
  }
  
  //::::::::::::::::::::::::::::toggle switches for data sets:::::::::::::::::::::::::::
  x=10;
  y=180;
  for(int i=1; i<=sigNum; i++)
  {
    cp5.addToggle("lgVisible"+i).setPosition(x, y=y+40).setValue(int(getPlotterConfigString("lgVisible"+i))).setMode(ControlP5.SWITCH).setColorActive(graphColors[i-1]);
  }
  
  //::::::::::::::::::::::::::::::::labels for data sets::::::::::::::::::::::::::::::::
  for(int i=1; i<=sigNum; i++)
  {
    cp5.addTextlabel("Data Set "+i).setText("Data Set "+i).setPosition(lbx, lby=lby+40).setColor(fontColors[0]).setColorBackground(graphColors[0]); //Change as needed
  }
  
  //::::::::::::::::::::::::::::::::::Button controls:::::::::::::::::::::::::::::::::::
  x=35;
  y=15;
                                   //  Add Transmission Start Button
  cp5.addButton("Start/Stop Transmission").setPosition(x-27,y).setWidth(112);
  
  if(serialTimebase == true)
  {
                                   //  Add Plot Pause Button
    cp5.addButton("Plot Pause").setPosition(x,y=y+30).setWidth(53);
    
                                   //  Add Reset Plot Button
    cp5.addButton("Reset Plot").setPosition(x, y=y+20).setWidth(53);
  }                                 
                                   //  Add Save & Quit Button
                                   //  This is required to ensure .csv stores correctly
  cp5.addButton("Save & Quit").setPosition(x,y=y+20).setWidth(53);
  
  //::::::::::::::::::::::::::::::::Add Indicator Labels::::::::::::::::::::::::::::::::
                                   //  Read error Indicator label
  cp5.addTextlabel("Read Error Detected").setText("Read Error Detected").setPosition(x=6, y=125).setColor(fontColors[0]);
  
  if(serialTimebase == true)
  { 
                                  //  Timebase error Indicator label
    cp5.addTextlabel("Time Base Error").setText("Time Base Error").setPosition(x=6, y=y+20).setColor(fontColors[0]);
                                  //  Resolution exceeded Indicator label
    cp5.addTextlabel("Resolution Exceeded").setText("Resolution Exceeded").setPosition(x=6, y=y+20).setColor(fontColors[0]);
   
    //::::::::::::::::::::::::::slider for time/sample range::::::::::::::::::::::::::::
    cp5.addRange("scaleRangeControl", 0, 100, 0, 100, 225, 50, 605, 10);
    //:::::::::::::::::::::::::::::::Reset error message::::::::::::::::::::::::::::::::
    cp5.addTextlabel("Reset Message").setPosition(260, 300).setVisible(false).setColor(fontColors[1]).setText("An error has occurred in the timebase received. This could be due to a hardware reset. Please press Plot Reset to resume plotting.");    
    
    //:::::::::::::::::::::::::::::::::Reset Timer Button:::::::::::::::::::::::::::::::
    cp5.addButton("Reset Timer").setPosition(900, 500).setWidth(58);
    
  }
  //::::::::::::::::::::::::::::::::Add Data Set Legend:::::::::::::::::::::::::::::::::
  cp5.addTextlabel("Data Legend:").setText("Data Legend:").setColor(fontColors[0]).setPosition(x=750, y=70).setFont(textFonts[0]);
  for(int i=1; i<=sigNum; i++)
  {
    cp5.addTextlabel("Data Label " + i).setText("Data Set " + i).setColor(graphColors[i-1]).setPosition(x=760, y=y+20);
  }

  //::::::::::::::::::::::::::::::Add Vehicle Stat Displays:::::::::::::::::::::::::::::
  cp5.addTextlabel("Current Vehicle Stats").setPosition(x=880, y=15).setColor(fontColors[0]).setText("Current Vehicle Stats").setFont(textFonts[0]);
  cp5.addTextlabel("Current Speed Label").setPosition(x, y=y+20).setColor(fontColors[0]).setText("Current Speed:").setFont(textFonts[1]);
  cp5.addTextlabel("Maximum Speed Label").setPosition(x, y=y+100).setColor(fontColors[0]).setText("Max Speed:").setFont(textFonts[1]);
  cp5.addTextlabel("Battery Remaining Label").setPosition(x, y=y+100).setColor(fontColors[0]).setText("Battery Remaining:").setFont(textFonts[1]);
  cp5.addTextlabel("Current Temperature Label").setPosition(x, y=y+100).setColor(fontColors[0]).setText("Current Temperature:").setFont(textFonts[1]);
  cp5.addTextlabel("Timer Label").setPosition(x, y=y+200).setColor(fontColors[0]).setText("Current Time").setFont(textFonts[1]);
  
  vehicleStats[0] = cp5.addTextlabel("Current Speed").setPosition(x, y=65).setColor(fontColors[2]).setText("0.00").setFont(textFonts[2]);
  vehicleStats[1] = cp5.addTextlabel("Maximum Speed").setPosition(x, y=y+100).setColor(fontColors[2]).setText("0.00").setFont(textFonts[2]);
  vehicleStats[2] = cp5.addTextlabel("Battery Remaining").setPosition(x, y=y+100).setColor(fontColors[2]).setText("100%").setFont(textFonts[2]);
  vehicleStats[3] = cp5.addTextlabel("Current Temperature").setPosition(x, y=y+100).setColor(fontColors[2]).setText("0.00").setFont(textFonts[2]);
  vehicleStats[4] = cp5.addTextlabel("Timer").setPosition(x, y=y+200).setColor(fontColors[2]).setFont(textFonts[2]);
 
  //:::::::::::::::::::::Add Displays for current Vehicle Stats::::::::::::::::::::
  int x_stats = 880;
  int y_stats = 60;
  fill(0,0,0);
  stroke(255, 255, 255);
  rect(x_stats, y_stats, 100, 32);
  
  fill(0,0,0);
  stroke(255, 255, 255);
  rect(x_stats, y_stats=y_stats+100, 100, 32);
  
  fill(0,0,0);
  stroke(255, 255, 255);
  rect(x_stats, y_stats=y_stats+100, 100, 32);
  
  fill(0,0,0);
  stroke(255, 255, 255);
  rect(x_stats, y_stats=y_stats+100, 100, 32);
  
  fill(0,0,0);
  stroke(255,255,255);
  rect(x_stats, y_stats=y_stats+200, 100, 32);
      
}






//===================================Main Program Loop==================================
String myString = "";
boolean serialEventTriggered = false;
boolean readError = false;
int endIndex = 0;
int i = 0;                                        //  loop variable
int n = 0;                         //  Variable to count executions of draw function.
                                   //  This is useful for detectiong the first execution

int timeIndexMin = 0;                    //  Create a reference for the section 
int timeIndexMax = 0;                    //  of the data array to be plotted.  

int speedArrayRef = 0;
int batteryArrayRef = 0;
int tempArrayRef = 0;

void draw() {
  //~~~~~~~~~~~~~~~~~~~Read in serial stream and if data is available~~~~~~~~~~~~~~~~~~~
  int x = 100;                                 //  X and Y coordinate variables
  int y = 125;
  
  if ((mockupSerial || serialEventTriggered)  && startFlag) {
    String todlog = "";
    float maxTimeBase = 0;   
    background(255);                             //  Set Main background colour
    
    serialEventTriggered = false;
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Check for read errors~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
    if(!readError) 
    {   
      fill(0, 255, 0);                     //  Display green (no errors)        
      stroke(255);                         
      rect(x, y, 20, 10);                  
    }
    else
    {
      fill(255, 0, 0);                     //  Display red (read errors detected)
      stroke(255);
      rect(x, y, 20, 10);                      
    }
    //~~~~~~~~~~~~~~~~~Read data from mock data program if applicable~~~~~~~~~~~~~~~~~~~

    if(mockupSerial)                            //  Read mock data 
    {                                           //  Call the appropriate function depending 
      if(!serialTimebase)                       //  on whether a timebase is needed
        myString = mockupSerialFunction();      
      else
        myString = mockupSerialTimebaseFunction();
    }
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~Prepare data strings~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    myString = myString + "\r";
    todlog = myString;
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~print to file/log~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    output.println(todlog.replace(" ",",").replace("\r",""));

    //~~~~~~~~~~~~~~~~~~~~~~~~split string at delimiter (space)~~~~~~~~~~~~~~~~~~~~~~~~~
    String[] nums = split(myString, ' ');

    if(resetFlag)                               //  Checks whether a reset signal has 
    {                                           //  been sent. If so, there is a chance
      resetFlag = false;                        //  that nums holds a previous time sample,
      return;                                   //  and should therefore, be discarded.
    }
    //~~~~~~~~~~~~~~~~count number of line graphs to hide [linked to GUI]~~~~~~~~~~~~~~~
    int numberOfInvisibleLineGraphs = 0;
    for (i=0; i<sigNum; i++) {
      if (int(getPlotterConfigString("lgVisible"+(i+1))) == 0) {
        numberOfInvisibleLineGraphs++;
      }
    }
    
    //~~~~~~~~~~~~~~~Assemble and plot data for samples or timebase scale~~~~~~~~~~~~~~~~
    if(!serialTimebase)
    {
      for (i=0; i<nums.length; i++) {           //  Builds the array for the previous 
                                                //  100 samples
        try {
          if (i<lineGraphValues.length) {
            for (int k=0; k<lineGraphValues[i].length-1; k++) {
              lineGraphValues[i][k] = lineGraphValues[i][k+1];  //  Shift each previous
            }                                                   //  entry along array
            
                                                //  Insert the new sample to the array
            lineGraphValues[i][lineGraphValues[i].length-1] = float(nums[i])*float(getPlotterConfigString("lgMultiplier"+(i+1)));
          }
        }
        catch (Exception e) {
        }
      }
      
      //::::::::::::::::::::::::::::draw the line graphs::::::::::::::::::::::::::::::::
      LineGraph.DrawAxis();
      for (int i=0;i<lineGraphValues.length; i++) 
      {
        LineGraph.GraphColor = graphColors[i];
        if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
        {
                                               //  Assigns sample array as x axis, and 
                                               //  sample data in reference to y axis.       
           LineGraph.LineGraph(lineGraphSampleNumbers, lineGraphValues[i]);
        }
      }
    }
    else
    { 
      //:::::::::::Builds an array list that expands as more data is read in::::::::::::
                            //  Using a list rather than a multi dimensional array makes 
                            //  it simpler to expand dynamically as more data accumulates.
      for (i=0; i<nums.length; i++) 
      {
        try 
        {                                      //  For the first 'draw' iteration, sets
          if(n == 0)                           //  the first value of each data set.
            lineGraphDataList[i].set(n, float(nums[i])*float(getPlotterConfigString("lgMultiplier"+(i+1))));
          else                                 //  Appends all further samples to the
                                               //  existing list.
            lineGraphDataList[i].append(float(nums[i])*float(getPlotterConfigString("lgMultiplier"+(i+1))));
        }  
        catch (Exception e) {
        }
      }

      //:::::::::::::::::Isolate time base data set into its own array:::::::::::::::::
      timeBase = lineGraphDataList[0].array();
                                               //  Check that timebase is continually 
      y = y+20;                                //  ascending, if not, then a reset may
      if((timeBase[0] != min(timeBase)) ||     //  have occurred on the sending module. 
         (timeBase[timeBase.length-1] != max(timeBase)))         
      {                                         
        fill(255, 0, 0);                       
        stroke(255);
        rect(x, y, 20, 10);                    //  If not, an error indicator turns red.
        
        Textlabel resetMessage = ((Textlabel)cp5.getController("Reset Message"));
        resetMessage.setVisible(true);
        return;
      }
      else
      {
        fill(0, 255, 0);
        stroke(255);
        rect(x, y, 20, 10);                    //  Else, it remains green.
        
        Textlabel resetMessage = ((Textlabel)cp5.getController("Reset Message"));
        resetMessage.setVisible(false);
      }
      
      //::::::::::::::::::::::Timer to display most recent sample::::::::::::::::::::::
      vehicleStats[4].setText(str(timeBase[timeBase.length-1]));

      //:::::::::::::::::::::Add Displays for current Vehicle Stats::::::::::::::::::::
      int x_stats = 880;
      int y_stats = 60;
      fill(0,0,0);
      stroke(255, 255, 255);
      rect(x_stats, y_stats, 100, 32);
      
      fill(0,0,0);
      stroke(255, 255, 255);
      rect(x_stats, y_stats=y_stats+100, 100, 32);
      
      fill(0,0,0);
      stroke(255, 255, 255);
      rect(x_stats, y_stats=y_stats+100, 100, 32);
      
      fill(0,0,0);
      stroke(255, 255, 255);
      rect(x_stats, y_stats=y_stats+100, 100, 32);
      
      fill(0,0,0);
      stroke(255,255,255);
      rect(x_stats, y_stats=y_stats+200, 100, 32);
      
      //::::::::::::::::::::::::::Save range settings to file::::::::::::::::::::::::::   
      
      if(getPlotterConfigString("Plot Pause") == "1"); //  If pause has been pressed,
                                                       //  leave indexes unchanged.
                                                       
      else if(rangeFlag == false)              //  If range slider has not been moved
      {                                        //  or is at full range, set limits
                                               //  to array boundaries.

        plotterConfigJSON.setString("lgMinX", min(timeBase)+ "");
        plotterConfigJSON.setString("lgMaxX", max(timeBase)+ "");
        timeIndexMax = timeBase.length - 1;    //  Set the maximum index to the length
        timeIndexMin = 0;                      //  of the array.
      }
       
      else                    //  Determine the appropriate range to plot depending on the 
      {                       //  range value set.
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
                            //  Save these ranges to the config file
        plotterConfigJSON.setString("lgMinX", timeBase[timeIndexMin]+ "");
        plotterConfigJSON.setString("lgMaxX", timeBase[timeIndexMax]+ "");
      }
      
      saveJSONObject(plotterConfigJSON, topSketchPath+"/datalog_config.json");
      setChartSettings();   //  The x axis is thus updated by referencing the saved value.
      
                            //  Given the range, checks whether graph has sufficient
                            //  resolution
      y = y+20;
      if(timeBase[timeIndexMax] <= timeBase[timeIndexMin])
      {
        fill(255, 0, 0);                       
        stroke(255);
        rect(x, y, 20, 10);                  //  Displays red indicator for error
      }
      else
      {
        fill(0, 255, 0);
        stroke(255);
        rect(x, y, 20, 10);                 //  Else, displays green
      }
      
      //:::::::::::::::::::::::::::::draw the line graphs::::::::::::::::::::::::::::::
      LineGraph.DrawAxis();
      for (int i=0;i<sigNum; i++) 
      {
                            //  Puts each data set from list into an array temporarily
        currentDataSet = lineGraphDataList[i].array();
        
        if(configReceived)
        {                    //  Update stat displays to reflect their respective value.
          if(i == speedArrayRef)  //  The array references are updated after a config 
          {                       //  string is recieved, and depends on the data set names.
            
            vehicleStats[0].setText(str(currentDataSet[currentDataSet.length-1]) + "km/h");
            vehicleStats[1].setText(str(max(currentDataSet)) + "km/h");
          }
          if(i == batteryArrayRef)
            vehicleStats[2].setText(str(currentDataSet[currentDataSet.length-1]) + "%");
          if(i == tempArrayRef)
            vehicleStats[3].setText(str(currentDataSet[currentDataSet.length-1]) + "°C");
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
        catch (Exception e)  {
          println("ERROR");
        }
      }    
    }
    n++;                      //  Increments 'draw' execution count 
    
  }
}






//==============Function to update graph ranges and parameters from file===============
void setChartSettings() {

  if(!serialTimebase)
    LineGraph.xLabel=" Samples ";            //  Set scale for samples
  else
    LineGraph.xLabel=" Time ";               //  Set scale for time base
    
  LineGraph.yLabel="Value";
  LineGraph.Title="";  
  LineGraph.xDiv=20;  
  LineGraph.xMax=int(getPlotterConfigString("lgMaxX")); 
  LineGraph.xMin=int(getPlotterConfigString("lgMinX"));  
  LineGraph.yMax=int(getPlotterConfigString("lgMaxY")); 
  LineGraph.yMin=int(getPlotterConfigString("lgMinY"));
}




//===========================Function to set Legend Labels============================
boolean configReceived = false;
void setLegendSettings()
{
  int startIndex = myString.indexOf("?") + 2;    //  Removes ? indicator character
  myString = myString.substring(startIndex, myString.length()-1);
  String[] legendLabels = split(myString, ' ');  //  Splits entries into an array
  
  for(i=0; i<(legendLabels.length-1); i++)       //  Loops through the array setting
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





//==========================Handler for reading serial data=========================
byte[] inBuffer = new byte[500];                  //  Buffer to hold serial message
void serialEvent(Serial p)
{
  for(i=0; i<499; i++) inBuffer[i] = 0;            // Flushes the buffer of old data.
  
  serialPort.readBytesUntil('\r', inBuffer);    //  Read serial data into buffer

  for(i=0; i<499; i++)        //  Checks for invalid characters in buffer. If any are
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
        }
      }
      return;
    }
  }
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~Assemble string of recieved data~~~~~~~~~~~~~~~~~~~~~~~~
  myString = new String(inBuffer);                              //  Remove carriage
  myString = myString.substring(0, myString.indexOf("\r", 0));  //  return for now. 
                                                              
                             //  Removes additional spaces on the string
  while(myString.charAt(myString.length()-1) == ' ')  myString = trim(myString);

  //~~~~~~~~Determine the number of variables, and the index of the final value~~~~~~
  i = 0;
  endIndex = 0;
  while(myString.indexOf(" ", endIndex) >= 0)     //  Loop while spaces can be found
  {
    endIndex = myString.indexOf(" ", endIndex);   //  Finds index of a space
    endIndex++;                                   //  Increments past the space
    i++;                     //  Increments the count of how many spaces have been found
  }
  
  if(i == (sigNum-1)) serialEventTriggered = true;//  There should always be one less space
  else                                            //  than the number of signals. Thus, a 
  {                                               //  valid string is identified by sigNum-1.
    print("Read Error, String was: ");
    println(myString);                            //  Otherwise, print the invalid data
    myString = "";                                //  and reset string.
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
      for(i=0; i<lineGraphDataList.length; i++)
      {
        lineGraphDataList[i].clear();                    //  Clears each data set
        lineGraphDataList[i].append(0);                  //  Appends a 0 for the first element.
        n = 0;                                           //  Resets 'draw' execution count
        timeIndexMin = 0;                                //  Resets index min and max to 0
        timeIndexMax = 0;
      }
    }
                              //  If triggered by the "Save & Quit" button
    else if (theEvent.isAssignableFrom(Button.class) && parameter == "Save & Quit")
    {
      output.flush();                                    //  Flushes the output variable
      output.close();                                    //  Closes the output
      exit();                                            //  Closes the program
    }
    
    else if (theEvent.isAssignableFrom(Button.class) && parameter == "Reset Timer")
    {
      serialPort.write("---");
      for(i=0; i<lineGraphDataList.length; i++)
      {
        lineGraphDataList[i].clear();                    //  Clears each data set
        lineGraphDataList[i].append(0);                  //  Appends a 0 for the first element.
        n = 0;                                           //  Resets 'draw' execution count
        timeIndexMin = 0;                                //  Resets index min and max to 0
        timeIndexMax = 0;   
      } 
      resetFlag = true;
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
