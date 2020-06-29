unit usercode;
interface
uses piclibrary;
const 
LED_RED = RC + 0;
LED_GRN = RC + 1;
TIME_COUNT = 1000;  //1c
BRSETUP = 9600;
BRSETUP3 = 115200;
BRWORK = 115200;
var 
  RedState   : byte;
  GreenState : byte;
  Command1   : byte;
  Command2   : byte;
  Stage      : byte;
  i          : byte;
  TimeCount  : integer;
  TryFailed  : integer;
  AT         : string[3]='AT';
  HC06_115200 : string='AT+BAUD8';
procedure Start;
procedure MainLoop;
procedure OnTimer1;
procedure OnTimer2;
procedure OnRxChar0;
procedure ToWork;
implementation
procedure Start;
begin
 for i := 0 to 10 do
    begin
  RedState   := 0;
  GreenState := 0;
  Command1   := 0;
  Command2   := 0;
  TimeCount  := 0;
  TryFailed  := 0;
  Stage      := 3;
  SetBit(LED_RED,1);
    end;
end;

procedure MainLoop;
begin
  FastRx(0,Command1);
  if (Command1=$4B) and (Command2=$4F) then  //OK   Command1=K(75)    Command2=O(79)
    begin
      if Stage<2 then
        inc(Stage);
      Command1 := 0 ;
      case Stage of
        1:
          begin
            SetBit(LED_GRN,1);
            TryFailed := 0;
          end;
        2: ToWork(); //ToWork->ToWork()
        3:
         begin
          Stage := 2;
          ToWork;
         end;
      end;
    end;
  Command2 := Command1;
  if (Stage=0) or (Stage=3) then    // and ->&&  This string is test of comments.
    if TimeCount>TIME_COUNT then
      begin
        TransferStr(AT);
        TimeCount := 0;
        inc(TryFailed);
        if TryFailed>10 then
          begin
            TryFailed := 0;
            if Stage=3 then
              begin
                Stage := 0;
                InitUART(0,BRSETUP);
              end
            else
              begin
               Stage := 3;
               InitUART(0,BRSETUP3);
              end;
          end;
      end;
  if (Stage=1) and (TimeCount>TIME_COUNT) then
    begin
      TransferStr(HC06_115200);  //Раз в 0,05 с.
      TimeCount := 0;
      inc(TryFailed);
      if TryFailed>10 then
        begin
          TryFailed := 0;
          Stage := 3;
          InitUART(0,BRSETUP3);
        end;
    end;
end;

procedure OnTimer1;
begin
  inc(TimeCount);
end;
procedure OnTimer2;
begin
  //SetBit(LED_GRN,GreenState);
  GreenState := GreenState xor 1;
end;

procedure OnRxChar0;
begin
  //FastTx(0,'F');
  //SetBit(LED_GRN,1);
end;

procedure ToWork;
begin
  SetBit(LED_RED,0);
  InitUART(0,BRWORK);
end;

begin
  
end.