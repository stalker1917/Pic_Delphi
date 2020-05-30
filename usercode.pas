unit usercode;
interface
uses piclibrary;
const 
LED_RED = RC + 0;
LED_GRN = RC + 1;
var 
  RedState : byte;
  GreenState : byte;
procedure Start;  
procedure OnTimer1;
procedure OnTimer2;
implementation
procedure Start;
begin
  RedState := 0;
  GreenState := 0;
end;

procedure OnTimer1;
begin
  SetBit(LED_RED,RedState);
  RedState := RedState xor 1;
end;
procedure OnTimer2;
begin
  SetBit(LED_GRN,GreenState); 
  GreenState := GreenState xor 1;
end;

begin
  
end.