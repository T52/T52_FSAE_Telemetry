//============================ CAN Transmitter Module ============================

#include <stdbool.h>
#include <stdint.h>

#include "Energia.h"
#include "driverlib/pin_map.h"
#include "driverlib/gpio.h"
#include "driverlib/sysctl.h"
#include "driverlib/can.h"
#include "inc/hw_memmap.h"

void setup()
{
  Serial.begin(115200);           // - Enable UART1 for debugging information
  
  //-----------------------------CAN0 Configuration-------------------------------
  Serial.println("Setting up CAN peripheral...");
  SysCtlPeripheralEnable(SYSCTL_PERIPH_CAN0);          // - Enable clock for CAN0
  SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOE);         // - Enable clock for GPIOE
  
                                  // - Enable GPIOE Pins 4&5 for CAN
  GPIOPinTypeCAN(GPIO_PORTE_BASE, GPIO_PIN_4 | GPIO_PIN_5);
  GPIOPinConfigure(GPIO_PE4_CAN0RX);
  GPIOPinConfigure(GPIO_PE5_CAN0TX);
  
  CANInit(CAN0_BASE);            // - Initialize & Configure CAN peripheral
  CANBitRateSet(CAN0_BASE, SysCtlClockGet(), 500000);
  CANEnable(CAN0_BASE);
  
  Serial.println("Configuration complete.\n");  
}

int i=0;
void loop()
{
  //---------------------------Assemble CAN Message------------------------------
  uint16_t HV_Voltage = 1;
  uint8_t HV_Amp = random(0, 200);
  uint8_t inv_Faults = random(0, 15);
  uint8_t throttle_Pos = random(0, 100);
  uint8_t brake_Pos = random(0, 100);
  uint8_t car_Faults = random(0, 15);
  uint8_t LV_Battery_Voltage = random(0, 150);
  uint16_t energy_Used = 1;
  
  Serial.print("HV Voltage: ");            Serial.println(HV_Voltage);
  Serial.print("HV Amp: ");                Serial.println(HV_Amp);
  Serial.print("Inverter Faults: ");       Serial.println(inv_Faults);
  Serial.print("Throttle Position: ");     Serial.println(throttle_Pos);
  Serial.print("Brake Position: ");        Serial.println(brake_Pos);
  Serial.print("Car Faults: ");            Serial.println(car_Faults);
  Serial.print("LV Battery Voltage: ");    Serial.println(LV_Battery_Voltage);
  Serial.print("Energy Used: ");           Serial.println(energy_Used);

  uint8_t tx_Message[8];
  tx_Message[0] = (HV_Voltage & 0x01FF) >> 1;
  tx_Message[1] = ((HV_Voltage & 0x01FF) << 7) | ((HV_Amp & 0x00FF) >> 1);
  tx_Message[2] = ((HV_Amp & 0x00FF) << 7) | ((inv_Faults & 0x000F) << 3) | ((throttle_Pos & 0x007F) >> 5);
  tx_Message[3] = ((throttle_Pos & 0x007F) << 4) | ((brake_Pos & 0x007F) >> 3);
  tx_Message[4] = ((brake_Pos & 0x007F) << 5) | ((car_Faults & 0x000F) << 1) | ((LV_Battery_Voltage & 0x00FF) >> 7);
  tx_Message[5] = ((LV_Battery_Voltage & 0x00FF) << 1) | ((energy_Used & 0x1FFF) >> 12);
  tx_Message[6] = ((energy_Used & 0x1FFF) >> 4);
  tx_Message[7] = ((energy_Used & 0x1FFF) << 4);
   
   Serial.println(tx_Message[0]);
   Serial.println(tx_Message[1]);
   Serial.println(tx_Message[2]);
   Serial.println(tx_Message[3]);
   Serial.println(tx_Message[4]);
   Serial.println(tx_Message[5]);
   Serial.println(tx_Message[6]);
   Serial.println(tx_Message[7]);


 //------------------------------Transmit Message---------------------------------
 tCANMsgObject sMsgObjectTx;
 sMsgObjectTx.ui32MsgID = 0x400;
 sMsgObjectTx.ui32Flags = 0; 
 sMsgObjectTx.ui32MsgLen = 8;
 sMsgObjectTx.pui8MsgData = tx_Message;
 CANMessageSet(CAN0_BASE, 1, &sMsgObjectTx, MSG_OBJ_TYPE_TX);
 
 Serial.println("Transmission pending...");
 while(CANStatusGet(CAN0_BASE, CAN_STS_TXREQUEST) == 1);
 Serial.println("Message transmitted");
 
 while(1);
 //delay(500);
 i++; 
}
