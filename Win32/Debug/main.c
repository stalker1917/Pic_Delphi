/* 
 * File:   main.c
 * Author: PascalPicCreator v. Alpha
 */


#include <stdio.h>
#include <stdlib.h>
#include <htc.h>
#include "init.h"
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
unsigned char RedState ;
unsigned char GreenState ;
int Timer1_maxcount = 19531;
int Timer1_tail = 64;
int Timer1_counter = 0;
int Timer2_maxcount = 5859;
int Timer2_tail = 96;
int Timer2_counter = 0;
int main(int argc, char** argv);
void __interrupt() high_isr(void);
int main(int argc, char** argv)
{
  Init();
  RedState = 0;
  GreenState = 0;
  while (1) {}
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
  LED_RED = RedState;
  RedState = RedState ^ 1;
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
  LED_GRN = GreenState;
  GreenState = GreenState ^ 1;
}
}
}
