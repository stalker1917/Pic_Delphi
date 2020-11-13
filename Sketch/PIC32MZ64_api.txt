#include <stdio.h>
#include <stdlib.h>
#include <p32xxxx.h>  
char MainPort;
void TransferStr(char* Str);
void TransferStr(char* Str)   
{
  
volatile unsigned int j;
unsigned int * TXREG;
__U1STAbits_t * STABits;
switch (MainPort)
   {
       case 0:
           STABits = &U1STAbits;
           TXREG = &U1TXREG;
           break;
       case 1:
           STABits = &U2STAbits;
           TXREG = &U2TXREG;
           break; 
       case 2:
           STABits = &U3STAbits;
           TXREG = &U3TXREG;
           break;
       case 3:
           STABits = &U4STAbits;
           TXREG = &U4TXREG;
           break;
       case 4:
           STABits = &U5STAbits; 
           TXREG = &U5TXREG;
           break;
       case 5:
           STABits = &U6STAbits;
           TXREG = &U6TXREG;
           break;    
   } 

  j=0;
  while(Str[j]!=0)    
  {     
      *TXREG = Str[j];
      j++;
      while (!STABits->TRMT);   
  } 
}

void ChangePort(char P)
{
MainPort = P;
}