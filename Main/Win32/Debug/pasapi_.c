#include <stdio.h>
#include <stdlib.h>
#include <htc.h>
void TransferStr(char* Str);
void TransferStr(char* Str)   
{
  volatile unsigned int j;
  j=0;
  while(Str[j]!=0)    
  {     
      TXREG = Str[j];
      j++;
      while (!TXSTAbits.TRMT);   
  } 
}