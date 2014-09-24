

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

void draw() {
  // Expand array size to the number of bytes you expect
  byte[] tStor = new byte[10];
/*
  while (myPort.available() > 0) {
    tStor = Xbee.readBytes();
    Xbee.readBytes(tStor);
    if (tStor != null) {
      String myString = new String(tStor);
      println(myString);
    }
  }
*/

  int okstate = 0;
 
  while(okstate <= 4){
    if(okstate == 0){
      Xbee.write("+++");
      println("Printed: +++");
      while(Xbee.available() > 0) Xbee.readBytesUntil('\r', tStor);

      if(tStor[0]==79 && tStor[1]==75 && tStor[2]==13 && tStor[3]==0 && tStor[4]==0){ // if tStor=="OK\r"
        Xbee.clear();//CLEAR SERIAL BUFFER
        tStor =  new byte[10]; //CLEAR STOR BUFFER
        okstate++; //INCREMENT STATE
        print("OK found, State:");
        println(okstate);
      }
      else{
        println("No OK received. Serial read was: ");
        println(tStor);
      }


    }
    else if(okstate == 1){
      Xbee.write("atap 0");
      println("Printed: atap 0");
      while(Xbee.available() > 0) Xbee.readBytesUntil('\r', tStor);

      if(tStor[0]==79 && tStor[1]==75 && tStor[2]==13 && tStor[3]==0 && tStor[4]==0){ // if tStor=="OK\r"
        Xbee.clear();//CLEAR SERIAL BUFFER
        tStor =  new byte[10]; //CLEAR STOR BUFFER
        okstate++; //INCREMENT STATE
        print("OK found, State:");
        println(okstate);
      }
      else{
        println("No OK received. Serial read was: ");
        println(tStor);
      }

    }     
    else if(okstate == 2){
      Xbee.write("atwr");
      println("Printed: atwr");
      println("Serial read was pre: ");
      println(tStor);
      while(Xbee.available() > 0) Xbee.readBytesUntil('\r', tStor);
      println("Serial read was aft read: ");
      println(tStor);

      if(tStor[0]==79 && tStor[1]==75 && tStor[2]==13 && tStor[3]==0 && tStor[4]==0){ // if tStor=="OK\r"
        Xbee.clear();//CLEAR SERIAL BUFFER
        tStor =  new byte[10]; //CLEAR STOR BUFFER
        okstate++; //INCREMENT STATE
        print("OK found, State:");
        println(okstate);
      }
      else{
        println("No OK received. Serial read was: ");
        println(tStor);
      }

    }
    else if(okstate == 3){
      Xbee.write("atcn");
      println("Printed: atcn");
      while(Xbee.available() > 0) Xbee.readBytesUntil('\r', tStor);

      if(tStor[0]==79 && tStor[1]==75 && tStor[2]==13 && tStor[3]==0 && tStor[4]==0){ // if tStor=="OK\r"
        Xbee.clear();//CLEAR SERIAL BUFFER
        tStor =  new byte[10]; //CLEAR STOR BUFFER
        okstate++; //INCREMENT STATE
        print("OK found, State:");
        println(okstate);
      }
      else{
        println("No OK received. Serial read was: ");
        println(tStor);
      }

    }
    else{
      println("Xbee Config Error");
      break;
    }
    delay(1000);//1 Second Delay in loop
    println("loop");
    
  }
  Xbee.clear();
  Xbee.write("asfaskdjflkasjdlfkjaslkdjflaksdjflkasjdlfkjaslkdjflaksdjflkajsdlkfjalksdjflkajsdlkfjaslkdjflkasdjflkjsdfjaslkdfjlasjdflkajsdlfkjasldkfjlaksdjfalk");
  println("OK received. Configuration complete");
  exit();
    
}

