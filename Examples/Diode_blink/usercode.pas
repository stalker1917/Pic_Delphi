unit usercode;
interface
uses piclibrary;
const
LED_RED = RB + 9;
LED_GRN = RB + 4;
var
  RedState : byte;
  GreenState : byte;
procedure Start;
procedure OnTimer1;
procedure OnTimer2;
procedure OnRxChar0;
procedure MainLoop;
implementation
procedure Start;
begin
  RedState := 0;
  GreenState := 0;
end;

procedure MainLoop;
begin

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

procedure OnRxChar0;
begin
  FastTx(0,'F');
  SetBit(LED_GRN,1);
end;

begin

end.
