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
void InitUART(char NPort,long int BaudRate);


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
#define Clock 32000000

void InitUART(char NPort,long int BaudRate)
{
     
    TXSTAbits.TXEN = 0; // Transmitter off
    RCSTAbits.CREN = 0; // Receiver off
    TRISCbits.RC6 = 1;   //Need for working of USART
    TRISCbits.RC7 = 1;   //Need for working of USART
      // Настройка USART
    TXSTA = 0x24;       /* 8-битная передача
                           Асинхронный режим
                           Передатчик выключен
                           Высокоскоростной режим включен   */
    RCSTA = 0x80;       /* Сконфигурировать порты как Serial port
                           8-битный прием
                           Приемник отключен */
    BAUDCON = 0x08;     // 16-bit counter
    if (Clock%(4*BaudRate)<2*BaudRate) BaudRate = Clock/(4*BaudRate)-1; 
    else BaudRate = Clock/(4*BaudRate);
    SPBRGH = BaudRate >> 8;         // 56000
    SPBRG = BaudRate%256;//30//256000  //68 -115200;//SPBRG = 142;
    TXSTAbits.TXEN = 1; // Transmitter on
    RCSTAbits.CREN = 1; // Receiver on
}

void Init(void)
{
  InitCPU();
  InitTimers();
  InitUART(0,115200);
}
