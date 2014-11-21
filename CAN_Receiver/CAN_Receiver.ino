//============================ CAN Receiver Module ============================

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
  uint8_t rx_Message[8] = {0, 0, 0, 0, 0, 0, 0, 0};
  //---------------------------Setup Receive Mailboxes----------------------------
  tCANMsgObject sMsgObjectRx;
  sMsgObjectRx.ui32MsgID = 0x400;
  //sMsgObjectRx.ui32MsgIDMask = 0x7f8;

  //--------------------------------Wait for Data---------------------------------
  Serial.println("Waiting for data...");
  Serial.println(CANStatusGet(CAN0_BASE, CAN_STS_NEWDAT));
  while((CANStatusGet(CAN0_BASE, CAN_STS_NEWDAT) & 1)  == 0);
  CANMessageGet(CAN0_BASE, 1, &sMsgObjectRx, MSG_OBJ_TYPE_RX);
  Serial.println("Data received");
  //-------------------------------Print out Data---------------------------------
  rx_Message[0] = *sMsgObjectRx.pui8MsgData;
  
  Serial.print("First Byte: "); Serial.print(rx_Message[0]); 
}
