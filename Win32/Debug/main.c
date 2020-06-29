/* 
 * File:   main.c
 * Author: PascalPicCreator v. Alpha
 */


#include <stdio.h>
#include <stdlib.h>
#include <htc.h>
#include "init.h"
#include "pasapi.h"
//---------------------------------------------------------------------
// Configuration bits
//---------------------------------------------------------------------
#pragma config PWRT = OFF, LVP = OFF
#pragma config FCMEN = ON
#pragma config BOREN = ON, BORV = 2
#pragma config WDT = OFF, MCLRE = ON
#pragma config PBADEN = OFF, CCP2MX = PORTC
#pragma config IESO = OFF, STVREN = ON
#pragma config CP0 = ON
#pragma config CP1 = ON
#pragma config CP2 = ON
#pragma config CP3 = ON
#pragma config CPB = ON
#pragma config CPD = OFF
#pragma config OSC = HSPLL
#define LED_RED  PORTCbits.RC0
#define LED_GRN  PORTCbits.RC1
#define TIME_COUNT   1000
#define BRSETUP   9600
#define BRSETUP3   115200
#define BRWORK   115200
unsigned char RedState ;
unsigned char GreenState ;
unsigned char Command1 ;
unsigned char Command2 ;
unsigned char Stage ;
unsigned char i ;
int TimeCount ;
int TryFailed ;
char AT [3]="AT";
char HC06_115200 [32]="AT+BAUD8";
int Timer1_maxcount = 3;
int Timer1_tail = 232;
int Timer1_counter = 0;
int Timer2_maxcount = 5859;
int Timer2_tail = 96;
int Timer2_counter = 0;
unsigned char RX_0;
int main(int argc, char** argv);
void __interrupt() high_isr(void);
void ToWork(void);
int main(int argc, char** argv)
{
  Init();
  for (i = 0 ;i <= 10 ;i++)
  {
  RedState   = 0;
  GreenState = 0;
  Command1   = 0;
  Command2   = 0;
  TimeCount  = 0;
  TryFailed  = 0;
  Stage      = 3;
    LED_RED = 1;
  }
  while (1){
  Command1 = RX_0;
  if ( (Command1==0x4B) && (Command2==0x4F) )   //OK   Command1=K(75)    Command2=O(79)
  {
    if ( Stage<2 ) 
    Stage++;
      Command1 = 0 ;
    switch ( Stage ) {
     case  1:
    {
      LED_GRN = 1;
            TryFailed = 0;
    }
    break;
     case  2: ToWork(); //ToWork->ToWork()
    break;
     case  3:
    {
          Stage = 2;
          ToWork();
    }
  }
  }
  Command2 = Command1;
  if ( (Stage==0) || (Stage==3) )     // and ->&&  This string is test of comments.
  if ( TimeCount>TIME_COUNT ) 
  {
        TransferStr(AT);
        TimeCount = 0;
    TryFailed++;
    if ( TryFailed>10 ) 
    {
            TryFailed = 0;
      if ( Stage==3 ) 
      {
                Stage = 0;
                InitUART(0,BRSETUP);
      }
            else
      {
               Stage = 3;
               InitUART(0,BRSETUP3);
      }
    }
  }
  if ( (Stage==1) && (TimeCount>TIME_COUNT) ) 
  {
      TransferStr(HC06_115200);  //Раз в 0,05 с.
      TimeCount = 0;
    TryFailed++;
    if ( TryFailed>10 ) 
    {
          TryFailed = 0;
          Stage = 3;
          InitUART(0,BRSETUP3);
    }
  }
}
  return (EXIT_SUCCESS);
}
void __interrupt() high_isr(void)
{
if ((PIE1bits.TMR1IE) && (PIR1bits.TMR1IF)) {
PIR1bits.TMR1IF = 0;
Timer1_counter++;
if (Timer1_counter <= Timer1_maxcount)
  if (Timer1_counter == Timer1_maxcount) TMR1 = Timer1_tail;
  else TMR1 = 0xff00;
else 
{
Timer1_counter = 0;
TMR1 = 0xff00;
//User code
  TimeCount++;
}
}
if ((PIE1bits.TMR2IE) && (PIR1bits.TMR2IF)) {
PIR1bits.TMR2IF = 0;
Timer2_counter++;
if (Timer2_counter <= Timer2_maxcount)
  if (Timer2_counter == Timer2_maxcount) TMR2 = Timer2_tail;
  else TMR2 = 0;
else 
{
Timer2_counter = 0;
TMR2 = 0;
//User code
  //SetBit(LED_GRN,GreenState);
  GreenState = GreenState ^ 1;
}
}
if ((RCSTAbits.OERR)||(RCSTAbits.FERR)) {
  RCSTAbits.CREN = 0;
  RCSTAbits.CREN = 1;
}
if (PIR1bits.RCIF)
{
RX_0 = RCREG;
//User code
  //FastTx(0,'F');
  //SetBit(LED_GRN,1);
}
}
void ToWork(void)
{
  LED_RED = 0;
  InitUART(0,BRWORK);
}
