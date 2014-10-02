import processing.serial.*;

Serial Xbee;  // The serial port

void setup() {
  // Open the port you are using at the rate you want:
  Xbee = new Serial(this, "COM10", 115200);
}

void delay(int delay)
{
  int time = millis();
  while(millis() - time <= delay);
}

void Flush_buffer(){
  byte[] error_buf = new byte[1];//cleanbuff
  print("FL pre Buffer available = ");
  println(Xbee.available());
  
  while(Xbee.available() > 0){
     print(".");
     error_buf = Xbee.readBytes();
     Xbee.readBytes(error_buf);
  }
  println("Buffer Flushed.");
  print("FL aft Buffer available = ");
  println(Xbee.available());
}

class Xbee_setup {
//  public:
    String writecommand = "";
    byte[] tStor = new byte[3];
    String tString = "";
    int currstate;
    
    void Sendcommand(){
      Xbee.write(writecommand);
      print("Printed: ");
      println(writecommand);
    }
    
    
    void Readcommand(){
      if(Xbee.available() > 3){
        Flush_buffer();
      }

      while(Xbee.available() == 3){
        Xbee.readBytesUntil('\r', tStor);
      }
      tString = new String(tStor);


      if(tString.equals("OK\r")){
        
        currstate++;//INCREMENT STATE
        print("OK found, Incrementing State to:");
        println(currstate);
        
        Xbee.clear();//CLEAR SERIAL BUFFER
        Flush_buffer();
        tStor =  new byte[3]; //CLEAR STOR BUFFER

      }
      else{
        println("No OK received. Serial read was: ");
        println(tStor);
        print("Buffer available = ");
        println(Xbee.available());
      }
    }
};

void draw() {

  Xbee_setup XSS;
  XSS = new Xbee_setup();
  Flush_buffer();
  Flush_buffer();
  
  int okstate = 0;
  int loopcounter = 0;
  println("Starting Configuration...\n");
 
  while(okstate <= 4){ //state machine.
    
    if(okstate == 0){
      XSS.writecommand = "+++";
      XSS.currstate = okstate;
      XSS.Sendcommand();
      delay(1000);//1 sec delay
      XSS.Readcommand();
      okstate = XSS.currstate;
    }
    else if(okstate == 1){
      XSS.writecommand = "atap 0\r\n";
      XSS.currstate = okstate;
      XSS.Sendcommand();
      delay(1000);//1 sec delay
      XSS.Readcommand();
      okstate = XSS.currstate;
    }
    else if(okstate == 2){
      XSS.writecommand = "atwr\r\n";
      XSS.currstate = okstate;
      XSS.Sendcommand();
      delay(1000);//1 sec delay
      XSS.Readcommand();
      okstate = XSS.currstate;
    }
    else if(okstate == 3){
      XSS.writecommand = "atcn\r\n";
      XSS.currstate = okstate;
      XSS.Sendcommand();
      delay(1000);//1 sec delay
      XSS.Readcommand();
      okstate = XSS.currstate;
    }
    else if(okstate == 4){
      println("OK received. Configuration complete\n");
      break;
    }
    else{
      println("Xbee Config Error");
      println(okstate);
      //break;
      
    }
    //delay(2000);//2 Second Delay in loop
    loopcounter++;
    print("loop: ");
    println(loopcounter);
    

  }
  
  //congrats if you got this far...
  Xbee.clear(); //Clean yourself up...
  Flush_buffer();
  
  //Xbee.write("asfaskdjflkasjdlfkjaslkdjflaksdjflkasjdlfkjaslkdjflaksdjflkajsdlkfjalksdjflkajsdlkfjaslkdjflkasdjflkjsdfjaslkdfjlasjdflkajsdlfkjasldkfjlaksdjfalk");
  println("outside loop");
  exit();
    
}

