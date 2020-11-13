/* 
 * File:   init.c
 * Author: PascalPicCreator v. Alpha
 */


#include <stdio.h>
#include <stdlib.h>
#include <p32xxxx.h> 
#include "init.h"

void Init(void);
void InitCPU(void);
void InitTimers(void);
void InitUART(char NPort,long int BaudRate);


void InitCPU(void)
{
// UART I/O setting

INTCONbits.MVEC = 0; //One Vector
__builtin_enable_interrupts(); 


TRISB = 0; 
ANSELB = 0; 

TRISC = 0; 
 
TRISD = 0; 

TRISE = 0; 
ANSELE = 0;

TRISF = 0; 
  

TRISDbits.TRISD1 = 1; //U4RX
TRISDbits.TRISD9 = 1; //U2RX
TRISDbits.TRISD10 = 1; //U5RX
TRISFbits.TRISF4 = 1; //U1RX
TRISFbits.TRISF5 = 1; //U3RX

TRISDbits.TRISD0 = 0; //U2TX
TRISDbits.TRISD4 = 0; //U4TX
TRISDbits.TRISD11 = 0; //U1TX
TRISCbits.TRISC13 = 0; //U5TX
TRISCbits.TRISC14 = 0; //U3TX

// UART Mapping I/O setting
U1RXR = 0b0010;
U2RXR = 0b0000;
U3RXR = 0b0010;
U4RXR = 0b0000;
U5RXR = 0b0011;

RPD0R = 0b0010; //U2TX
RPD4R = 0b0010; //U4RX
RPD11R = 0b0001; //U1TX
RPC13R = 0b0011; //U5TX
RPC14R = 0b0001; //U3TX


// Initialization of ports
}

void InitTimers(void)
{
//INTCONbits.GIEH = 1;
//Init Timer1
T1CONbits.ON = 0;
IPC1bits.T1IP = 1;
IFS0bits.T1IF = 0;
IEC0bits.T1IE = 1;

//Init Timer2
T2CONbits.ON = 0;
IPC2bits.T2IP = 1;
IFS0bits.T2IF = 0;
IEC0bits.T2IE = 1;

//Init Timer3
T3CONbits.ON = 0;
IPC3bits.T3IP = 1;
IFS0bits.T3IF = 0;
IEC0bits.T3IE = 1;

//Init Timer4
T4CONbits.ON = 0;
IPC4bits.T4IP = 1;
IFS0bits.T4IF = 0;
IEC0bits.T4IE = 1;

//Init Timer5
T5CONbits.ON = 0;
//IPC5bits.T5IP = 1;
IFS0bits.T5IF = 0;
IEC0bits.T5IE = 1;

//Init Timer6
T6CONbits.ON = 0;
//IPC6bits.T6IP = 1;
IFS0bits.T6IF = 0;
IEC0bits.T6IE = 1;

//Init Timer7
T7CONbits.ON = 0;
//IPC7bits.T7IP = 1;
IFS1bits.T7IF = 0;
IEC1bits.T7IE = 1;

//Init Timer8
T8CONbits.ON = 0;
//IPC8bits.T8IP = 1;
IFS1bits.T8IF = 0;
IEC1bits.T8IE = 1;

//Init Timer9
T9CONbits.ON = 0;
//IPC9bits.T9IP = 1;
IFS1bits.T9IF = 0;
IEC1bits.T9IE = 1;

//User-mode Init
T2CONbits.T32 = 0;
T2CONbits.TCKPS =4;
T2CONbits.ON = 1;

T3CONbits.TCKPS =6;
T3CONbits.ON = 1;

}
#define Clock 198000000

void InitUART(char NPort,long int BaudRate)
{
   __U1STAbits_t * STABits;
   __U1MODEbits_t * MODEBits;
   unsigned int * UxBRG;
   switch (NPort)
   {
       case 0:
           STABits = &U1STAbits;
           MODEBits = &U1MODEbits;
           UxBRG = &U1BRG;
           break;
       case 1:
           STABits = &U2STAbits;
           MODEBits = &U2MODEbits;
           UxBRG = &U2BRG;
           break; 
       case 2:
           STABits = &U3STAbits;
           MODEBits = &U3MODEbits;
           UxBRG = &U3BRG;
           break;
       case 3:
           STABits = &U4STAbits;
           MODEBits = &U4MODEbits;
           UxBRG = &U4BRG;
           break;
       case 4:
           STABits = &U5STAbits; 
           MODEBits = &U5MODEbits;
           UxBRG = &U5BRG;
           break;
       case 5:
           STABits = &U6STAbits;
           MODEBits = &U6MODEbits;
           UxBRG = &U6BRG;
           break;    
   }
   MODEBits->ON = 0; 
   STABits->URXEN = 0;
   STABits->UTXEN = 0;
   *UxBRG= ((Clock / BaudRate) / 8) - 1; 
   MODEBits->PDSEL = 0;
   MODEBits->STSEL = 0;
   MODEBits->BRGH = 1;
   MODEBits->UEN = 0;
   STABits->URXEN = 1;
   STABits->UTXEN = 1;
   MODEBits->ON = 1;

}

void Init(void)
{
  InitCPU();
  InitTimers();
  InitUART(0,115200);
}
