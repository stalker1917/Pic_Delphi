/* 
 * File:   init.c
 * Author: PascalPicCreator v. Alpha
 */


#include <stdio.h>
#include <stdlib.h>
#include <htc.h>
#include "init.h"

void Init(void);
void InitCPU(void);
void InitTimers(void);
void InitUART(void);


void Init(void)
{
InitCPU();
InitTimers();
InitUART();
}

void InitCPU(void)
{
  INTCON = 0;         // Interruprs Disabled
  INTCON2 = 0x84;     // TMR0 = High priority
                        // All PORTB pull-ups are disabled
  INTCON3 = 0;
  RCON = 0x80;
  PIE1 = PIE2 = 0;
  PIR1 = PIR2 = 0;
  ADCON0 = 0;
  ADCON1 = 0xF;      // Digital I/O
  ADCON2 = 0;
  CCP1CON = 0;       
  SSPCON1 = 0;        // SSP disabled
  SSPSTAT = 0;
  CMCON = 0x07;
// Initialization of ports
  TRISA = 36;
  LATA = 0;
  TRISB = 0;
  LATB = 0;
  TRISC = 0;
  LATC = 0;
  TRISD = 0;
  LATD = 0;
  TRISE = 0;
  LATE = 0;
}

void InitTimers(void)
{
    INTCONbits.GIEH = 1;
//Init Timer0
    T0CON = 0b01000000;
    INTCONbits.TMR0IF = 0;
    INTCONbits.TMR0IE = 1;
//Init Timer1
    T1CONbits.TMR1ON = 0;
    T1CONbits.RD16 = 1;
    PIR1bits.TMR1IF = 0;
    PIE1bits.TMR1IE = 1;
    IPR1bits.TMR1IP = 1;
//Init Timer2
    T2CONbits.TMR2ON = 0;
    PIR1bits.TMR2IF = 0;
    PIE1bits.TMR2IE = 1;
    IPR1bits.TMR2IP = 1;
//Init Timer3
    T3CONbits.TMR3ON = 0;
    T3CONbits.RD16 = 1;
    PIR2bits.TMR3IF = 0;
    PIE2bits.TMR3IE = 1;
    IPR2bits.TMR3IP = 1;
//User-mode Init
T1CONbits.T1CKPS = 3;
TMR1 = 0xff00;
T1CONbits.TMR1ON = 1;

T2CONbits.T2CKPS = 2;
TMR2 = 0;
T2CONbits.TMR2ON = 1;

}
void InitUART(void)

{
}
