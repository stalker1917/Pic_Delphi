unit usercode;
interface
uses piclibrary;
type
ComPortRec = record
  Head1 : byte; //0
  Head2 : byte;  //1
  Number : byte;  //2
  Timestamp : longint; //3
  Hpack1 : array[0..8] of byte; //7
  Hpack2 : array[0..8] of byte; //16
  CRC8 : byte; //25
end;
OutPutRec = record
  Head1 : byte; //0
  Head2 : byte; //1
  Timestamp : longint; //2
  Hpack1 : array[0..15] of byte; //6
  Hpack2 : array[0..15] of byte; //22
  CRC : byte; //38
end;

const 
LED_RED = RB + 9;
LED_GRN = RB + 4;
TIME_COUNT = 150;  //1,5c
BRSETUP = 9600;
BRSETUP3 = 115200;
BRWORK = 115200;
OUTBUFHIGH = 38;
DIRECTMODE = 1;

var 
  RedState   : byte;
  GreenState : byte;
  Command1   : byte;
  Command2   : byte;
  Stage      : byte;
  i          : byte;   //i,j for parallel
  it         : byte;
  id         : byte;
  j          : byte;
  k          : byte;
  ComportPos : byte;
  ComportLast : byte;
  TimeCount  : integer;
  TryFailed  : integer;
  CRC        : byte;
  AT         : string[3]='AT';
  C_String   : string[2]='C';
  T_String   : string[2]='0';
  HC06_115200 : string='AT+BAUD8';
  ComportBuffer : array [0..99] of byte;
  Inbuf_common : record    //Не обрабатывает структуры больше 1 позиции.
    case byte of
      0: (B : array[0..25] of byte);
      1: (R : ComPortRec;)
    end;
  OutBuf  : record
    case byte of
      0: (B : array[0..OUTBUFHIGH] of byte);
      1: (R : OutPutRec;)
    end;
  NL,NL2     : record
    case byte of
      0: (B : array[0..3] of byte);
      1: (DW : longint);
    end;
  NI,NI2     : record
    case byte of
      0: (B : array[0..1] of byte);
      1: (W : word);
    end;
  Inbuf : array [0..3,0..4,0..26] of byte;   //Нужна обработка двухмерных массивов;
  LastBuf : array [0..3] of byte;
  ChangeFlag : array [0..3] of byte;
  Page : byte;
  EnablePort : array [0..4] of byte;
  CurrPage : byte;
  Last : byte;
  Index  : byte;
  Register_ : byte;
  TotalEnable : byte;
  TimerPage : byte;
  Ready,Send : boolean;
  StartData  : boolean;

procedure Start;
procedure MainLoop;
procedure OnTimer1;
procedure OnTimer2;
procedure OnRxChar0;
procedure OnRxChar1;
procedure OnRxChar2;
procedure OnRxChar4;
procedure ToWork(Test1 : Integer;Test2 : Integer);
procedure DecodeIn;
procedure DecodeEvenOdd;
procedure SendPack;

implementation
procedure Start;
begin
  RedState   := 0;
  GreenState := 0;
  Command1   := 0;
  Command2   := 0;
  TimeCount  := 0;
  TryFailed  := 0;
  Stage      := 3;
  ComportPos := 0;
  ComportLast := 0;
  //Timestamp := 0;
  TotalEnable := 0;
  SetBit(LED_RED,0);
  SetBit(LED_GRN,0);
  ChangePort(0);
  Page := 0;
  Ready := false;
  Send := false;
  StartData := false;
  OutBuf.R.Timestamp := 0;

  //FastTx(1,'D');
  //FastTx(2,'D');
  //FastTx(4,'D');
  for i := 0 to 3 do
    begin
      ChangeFlag[i]:=0;
      //Page[i] := 0;
      EnablePort[i] := 0;
    end;
end;

procedure MainLoop;
begin
  //FastRx(0,Command1);
  //Inbuf[0,0,0] := 0;
  Command1 := ComportBuffer[ComportPos];
  if Stage=2 then
     case Command1 of
       $53:
       if ComportPos<=ComportLast-2 then
         begin
           for i := 0 to 3 do
             if ComportBuffer[ComportPos+1] mod 2=1  then
               begin
                 ChangePort(i);
                 FastTx(255,Command1);
                 FastTx(255,ComportBuffer[ComportPos+2]);
                 ComportBuffer[ComportPos+1] := ComportBuffer[ComportPos+1]  shr 1;
               end;
           ComportPos := ComportPos+3;
         end;
       $54:
       if ComportPos<=ComportLast-1 then
         begin
           for i := 0 to 3 do
               begin
                 ChangePort(i);
                 FastTx(255,Command1);
                 FastTx(255,ComportBuffer[ComportPos+1]);
                 TransferStr(T_String);
               end;
           ComportPos := ComportPos+2;
         end;
       $55:
       if ComportPos<=ComportLast-1 then   //Зажечь диоды
         begin
           if DIRECTMODE>0 then PORTE := ComportBuffer[ComportPos+1]
           else
           for i := 0 to 4 do
             begin
               ChangePort(i);
               FastTx(255,Command1);
               FastTx(255,ComportBuffer[ComportPos+1]);
               ComportBuffer[ComportPos+1] := ComportBuffer[ComportPos+1]  shr 2;
             end;
           ComportPos := ComportPos+2;
         end;
       else
         inc(ComportPos);
     end
   else
   inc(ComportPos);
  if ComportPos>ComportLast then
    begin
      ComportPos := 0;
      ComportLast := 0;
    end;

  if (Command1=$4B) and (Command2=$4F) then  //OK   Command1=K(75)    Command2=O(79)
    begin
      if Stage<2 then
        inc(Stage);
      Command1 := 0 ;
      case Stage of
        1:
          begin
            //SetBit(LED_GRN,1);
            TryFailed := 0;
          end;
        2: ToWork(1,1); //ToWork->ToWork()
        3:
         begin
          Stage := 2;
          ToWork(1,1);
         end;
      end;
    end;
  if Stage=2 then
  case Command1 of
    $43:
      begin
        StartData := true;
        SetBit(LED_GRN,1);
        SetBit(LED_RED,0);
      end;
    $44:
      begin
        StartData := false;
        SetBit(LED_GRN,0);
        SetBit(LED_RED,1);
      end;

  end;
  // Включать диоды порт E

  Command2 := Command1;
  if (Stage=0) or (Stage=3) then    // and ->&&  This string is test of comments.
    if TimeCount>(TIME_COUNT-1) then     //>= not working
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
   if (Stage=2) and (TotalEnable=0) and (TimeCount>TIME_COUNT) then  //Start slave devices
     begin
       TimeCount := 0;
       for i := 0 to 2 do
         if EnablePort[i]=0 then
           begin
             if i<2 then ChangePort(i+1)
             else ChangePort(i+2);
             TransferStr(C_String);
           end;
       //TotalEnable := 1;
       for i := 0 to 2 do
         if EnablePort[i]=1 then TotalEnable := 2;
       //if TotalEnable>0 then TotalEnable := 2; //Иначе периодически срабатывает ,когда 1.
     end;
   if Ready and StartData then
     begin
       Ready := false;
       Send := true;
       for i := 0 to OUTBUFHIGH do
         begin
           FastTx(0,OutBuf.B[i]);
         end;
       if Ready  then SendPack();
       Send := false;
     end;

end;

procedure DecodeEvenOdd;
begin
  CRC := $96;
  //for i:=0 to 6 do Inbuf_common.B[0] := Inbuf[Index,0,i];
  //CurrPage := Page*2+1+Inbuf_common.R.Timestamp mod 2; //Protect from change page OnTimer;
  CurrPage := Page*2+1+Inbuf[Index,0,6] mod 2;
  for id:=0 to 24 do CRC:=CRC+Inbuf[Index,0,id];
  if CRC=Inbuf[Index,0,25] then
  for id:=0 to 25 do Inbuf[Index,CurrPage,id] := Inbuf[Index,0,id];
end;

procedure DecodeIn;  //С подменой.
begin
  EnablePort[Index] := 1;
  Last := LastBuf[Index];
  if Register_ =$C0 then
    begin
      Last :=0;
      DecodeEvenOdd();
    end;
  if ChangeFlag[Index]=1  then
    begin
      case Register_  of
        $DC:  Inbuf[Index,0,Last] := $C0;
        $DD:  Inbuf[Index,0,Last] := $DB;
      end;
      ChangeFlag[Index]:=0;
    end
  else
    begin
      if Register_=$DB then ChangeFlag[Index]:=1
      else Inbuf[Index,0,Last] := Register_;
    end;
  if (Last<26) and (ChangeFlag[Index]=0) then  //not work inc(i)-->i++
  inc(Last);
  LastBuf[Index] := Last;
end;

procedure SendPack;
begin
  TimerPage := (Page+1) mod 2;
  TimerPage := TimerPage*2 + (OutBuf.R.Timestamp mod 2)+1;
  NL.B[3] := 0;
  NL2.B[3] := 0;
  OutBuf.R.Head1 := $C1;
  //Optron on -->Z>127
  if Inbuf[0,TimerPage,16]<128 then OutBuf.R.Head2 := $04
                               else OutBuf.R.Head2 := $05;
  for it := 0 to 2 do
    begin
      for j := 0 to 1 do
        begin
          for k := 0 to 2 do
            begin
              NL.B[k] := Inbuf[it,TimerPage,9+j*3-k];  //X1..Y1  to  Big Endian
              NL2.B[k] := Inbuf[it,TimerPage,18+j*3-k]; //X2..Y2
            end;
          NI.W := NL.DW div 8;
          NI2.W := NL2.DW div 8;
          for k := 0 to 1 do
            begin
              OutBuf.R.Hpack1[it*4+j*2+k] := NI.B[k];
              OutBuf.R.Hpack2[it*4+j*2+k] := NI2.B[k];
            end;
        end;
    end;
   if (OutBuf.R.Timestamp mod 2 =0 ) then Page := (Page+1) mod 2;   //Сhange every 2 tick
   Ready := true;
end;

procedure OnTimer1;
begin
  inc(TimeCount);
  if TotalEnable>1 then
    begin
      inc(OutBuf.R.Timestamp);
      if Send=false then SendPack()
      else Ready:=true;
    end;
end;
procedure OnTimer2;
begin
  //SetBit(LED_GRN,GreenState);
  GreenState := GreenState xor 1;
end;

procedure OnRxChar0;
begin
   FastRx(0,ComportBuffer[ComportLast]);
   inc(ComportLast);
end;

procedure OnRxChar1;
begin
   FastRx(1,Register_);
   Index := 0;
   DecodeIn(); 
end;

procedure OnRxChar2;
begin
   FastRx(2,Register_);
   Index := 1;
   DecodeIn();
end;

procedure OnRxChar4;
begin
   FastRx(4,Register_);
   Index := 2;
   DecodeIn();
end;

procedure ToWork;
const
  Const1 = 1;
var
  Var1 : integer;
begin
  SetBit(LED_RED,1);
  InitUART(0,BRWORK);
end;

begin
  
end.