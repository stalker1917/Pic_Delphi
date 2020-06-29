unit piclibrary;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,translator,Common,Tokens, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
  TCallBackProc = procedure(var A:Array of byte;Count:Integer);
  TInterrupt = procedure;
TPICCOntroller = record
  Clock : Integer;
  Timers,Uarts :Integer;
end;

TUART = record
  BaudRate    : LongWord;
  TXReg,RxReg : Byte;
  OnRxChar    : TInterrupt;
  OnPCRxChar  : TCallBackProc;
end;

TTimer = record
   Counter : Int64;
   Delay   : Int64;
   Prescale : Byte;
   ProgramScale : Integer;
   Tail : Integer;
   PrescaleCode : Byte;
   //Cycles : Integer;
   IntProc : TInterrupt;
end;


const
 // PIC18F4520_Clock = 40;
  RA = 0;
  RB = 10;
  RC = 20;
  RD = 30;
  RE = 40;
  RF = 50;
  INTERAL = 10000; //INTIO2;
  Millisecond = 1000;

var
  Form1: TForm1;
  Quartz      : Integer; //Mhz
  Clock       : Integer;
  YesCompile  : Boolean = False;
  RealTime    : Boolean = True;
  FMain       : Text;
  FInit       : Text;
  FSketch     : Text;
  InitCPUF    : Boolean = False; //Сработала ли инициализация CPU;
  RunF        : Boolean = False; //Сработала ли инициализация таймеров;
  TRIS        : Array [0..6] of Byte = (0,0,0,0,0,0,0);
  MainCode    : TText;
  UARTs       :  Array of TUART;
  Timers      :  Array of TTimer;
  InitProc    :  procedure;
  PICControllers : TPICCOntroller = (Clock : 40; Timers:4; Uarts:1);
  YesRun      : Boolean=False;
procedure PrepareToMain;
procedure Run; //Применить установленную конфигурацию.
procedure InitCPU; //Инициализация CPU
procedure SetTimer(N:Byte;Delayus:Int64;Interrupt:TInterrupt);//Инициализация USART
//Инициализация таймеров.
procedure SetUart(N:Byte; BaudRate:LongInt; Interrupt:TInterrupt; PcProc : TCallBackProc);
procedure SetAsIn(Port:Byte);
procedure SetBit(Port,Bit:Byte);
procedure FastRx(USART:Byte;var Data:Byte);
procedure FastTx(USART:Byte;Data:AnsiChar);
procedure SetCompile;
procedure TransferStr(S:AnsiString);
procedure InitUART(Port:Byte;BaudRate:Integer);

implementation

{$R *.dfm}

Procedure WriteMemo(S:String);
begin
  Form1.Memo1.Lines.Add(S);
end;


procedure InitCPU;
var S:String;
C:Char;
i:Integer;
  begin
    if initCPUF then
      begin
        WriteMemo('Ошибка: нельзя вызывать функцию InitCPU два раза!');
        exit;
      end;
    initCPUF := True;
    if YesCompile then
       begin
         Assign(FMain,'main.c');
         Rewrite(FMain);
         Assign(FInit,'init.c');
         Rewrite(FInit);
       end;
    case Cpu of
      PIC18F4520:
        begin
           if YesCompile then
             begin
          Assign(FSketch,'../../Sketch/PIC18F4520_main.txt');
          Reset(FSketch);
          while (not Eof(FSketch)) do
            begin
              Readln(FSketch,S);
              WriteLn(FMain,S);
            end;
          close(FSketch);
          Assign(FSketch,'../../Sketch/PIC18F4520_init.txt');
          Reset(FSketch);
          while (not Eof(FSketch)) do
            begin
              Readln(FSketch,S);
              WriteLn(FInit,S);
            end;
          Close(FSketch);
          end;

         // Clock :=  PICControllers.Clock;//PIC18F4520_Clock;
          if Quartz>PICControllers.Clock then
            begin
              WriteMemo('Используем внутренний осцилятор.');
              if YesCompile then
                begin
                WriteLn(FMain,'#pragma config OSC = INTIO2');
                WriteLn(FInit,'  OSCTUNE = 0b01000000; //8Mhz*4');
                Clock := 32;
                end;
            end
          else
            if Quartz>(PICControllers.Clock/4) then
              begin
                Clock := Quartz;
                WriteMemo('Используем внешний осцилятор частотой '+IntToStr(Quartz)+' МГц. Режим HS.');
                if YesCompile then WriteLn(FMain,'#pragma config OSC = HS');
              end
            else
              begin
                Clock := Quartz*4;
                WriteMemo('Используем внешний осцилятор частотой '+IntToStr(Quartz)+' МГц. Режим HSPLL.');
                if YesCompile then WriteLn(FMain,'#pragma config OSC = HSPLL');
              end;
          WriteMemo('Частота контроллера - '+IntToStr(Clock)+' МГц.');
          if YesCompile then
            begin
          c := 'A';
          for i:=0 to 4 do
            begin
              WriteLn(FInit,'  TRIS',C,' = ',TRIS[I],';');
              WriteLn(FInit,'  LAT',C,' = 0;');
              inc(C);
            end;
           end;
        end;
    end;
//Стартовала пользовательская программа.
  if YesCompile then WriteLn(FInit,'}');
  if YesCompile then Flush(FMain);
  if YesCompile then Flush(FInit);
For i := 0 to High(Timers) do  Timers[i].Delay := 0;  //Таймеры выключены.
For i := 0 to High(UARTS)  do  UARTS[i].BaudRate := 0; //Порты выключены


end;

function FlagAnalisis:Boolean;
begin
  result := False;
  if (not InitCpuf) then
    begin
      WriteMemo('Нельзя инициализировать таймеры до инициализации контроллера');
      result := True;
    end;
  if (Runf) then
    begin
      WriteMemo('Нельзя инициализировать таймеры из основной программы после запуска');
      result := True;
    end;
end;

procedure SetTimer(N:Byte;Delayus:Int64;Interrupt:TInterrupt);
var FCycles : Double;
begin
  if FlagAnalisis then exit;


  if N>High(Timers) then WriteMemo('Таймера '+IntToStr(N)+' не существует для данного типа контроллеров')
  else
    begin
      Timers[N].IntProc := Interrupt;
      Timers[N].Delay := Delayus;
      Timers[N].Counter := Delayus;
      case Cpu of
        PIC18F4520:
          begin
            FCycles := (Clock*Delayus)/4;
            Timers[N].Prescalecode := 0;
            Timers[N].Prescale := 1;
            //else
              if N<>2 then
                while (FCycles>255) and (Timers[N].Prescale<8) do
                  begin
                     Timers[N].Prescale := Timers[N].Prescale*2;
                     inc(Timers[N].Prescalecode);
                     FCycles := FCycles/2;
                  end
              else
                while (FCycles>255) and (Timers[N].Prescale<16) do
                   begin
                     Timers[N].Prescale := Timers[N].Prescale*4;
                     inc(Timers[N].Prescalecode);
                     FCycles := FCycles/4;
                   end;
            Timers[N].ProgramScale := Trunc(FCycles/256); //Сколько цикло по 255
            Timers[N].Tail := Round(FCycles) - Timers[N].ProgramScale*256; //Последний цикл обрезанный.
            WriteMemo('Установлено срабатывание таймера №'+IntToStr(N)+' по истечению '+FloatToStr((Round(FCycles)*Timers[N].Prescale*4)/Clock)+' мкс');
            //Prescale 1..8
          end;
      end;
    end;
end;

procedure SetUart;
var  SPBRG,SPBRH : LongWord;
Scale : Word;
Function Division(DivC:Integer):LongWord; //inline;
  begin
    Result := Round(Clock*1000*1000/(Scale*DivC));
  end;

begin
  //if FlagAnalisis then exit;
  if N>High(UARTS) then WriteMemo('Порта '+IntToStr(N)+' не существует для данного типа контроллеров')
  else
    begin
      UARTS[N].BaudRate := BaudRate;
      UARTS[N].OnRxChar := Interrupt;
      UARTS[N].OnPCRxChar := PcProc;
      case Cpu of
        PIC18F4520:
          begin
            //Scale := 256*4;
            Scale := 4;
            SPBRH := Division(BaudRate)-1;
            if SPBRH>65535 then SPBRH:=65535;
            SPBRG := SPBRH mod 256;
            SPBRH := SPBRH div 256;
            WriteMemo('SPBRG= '+InttoStr(SPBRG));
            WriteMemo('SPBRH= '+InttoStr(SPBRH));
            WriteMemo('Установлена скорость '+IntToStr(Division(SPBRG+SPBRH*256+1)));
          end;
      end;

    end;
end;

{
function BitToByte(B:Byte):Byte;
begin
  result shl(
end;
}

procedure SetAsIn(Port:Byte);
var c:Char; i:Integer;
begin
  if initCPUF then WriteMemo('Ошибка: нельзя задавать порт на вход после выполнения InitCPU!')
  else
    begin
      case Cpu of
        PIC18F4520:
          if Port>42 then
             begin
               WriteMemo('Ошибка: нет такого порта!');
               exit;
             end;
      end;
      C := 'A';
      For i:=0 to (Port div 10)-1 do inc(C);
      WriteMemo('Порт R'+C+Chr($30+Port mod 10)+' успешно задан на вход');
      TRIS[Port div 10]:= TRIS[Port div 10] or (1 shl (Port mod 10));
    end;
end;

Function TimerReset(i:Integer;ForceTail:Boolean):String;
var j:Integer;
begin
       if (Timers[i].ProgramScale>0) and (not ForceTail) then
           if (i mod 2)=0 then Result := 'TMR'+IntToStr(i)+' = 0;'
                          else Result := 'TMR'+IntToStr(i)+' = 0xff00;'
        else
          begin
           if (i mod 2)=0 then j:=256-Timers[i].Tail
                          else j:=66526-Timers[i].Tail;
           if ForceTail then  Result := 'TMR'+IntToStr(i)+' = Timer'+IntToStr(i)+'_tail'+';'
                        else Result := 'TMR'+IntToStr(i)+' = '+IntToStr(j)+';';
          end;
end;

procedure CompileInitTimers;
var S:String;
i,j:Integer;
begin
   case Cpu of
      PIC18F4520:
           Assign(FSketch,'../../Sketch/PIC18F4520_timers.txt');
   end;
  Reset(FSketch);
  while (not Eof(FSketch)) do
    begin
      Readln(FSketch,S);
      WriteLn(FInit,S);
    end;
  CloseFile(FSketch);
  For i := 0 to High(Timers) do
    if Timers[i].Delay>0 then
      begin
        if i=0 then WriteLn(FInit,'T',i,'CONbits.T',i,'PS = ',Timers[i].PrescaleCode,';')
               else WriteLn(FInit,'T',i,'CONbits.T',i,'CKPS = ',Timers[i].PrescaleCode, ';');
        WriteLn(FInit,TimerReset(I,False));
        WriteLn(FInit,'T',i,'CONbits.TMR',i,'ON = 1;');
        WriteLn(FInit,'');
      end;
  WriteLn(FInit,'}');
  //WriteLn(FInit,'void InitUART(void)');
  // WriteLn(FInit,'');
  //WriteLn(FInit,'{');
  //WriteLn(FInit,'}');
  Flush(FInit);
end;

procedure CompileInitUART;
var
S:String;
i,j:Integer;
begin
   WriteLn(FInit,'#define Clock ',Clock*1000*1000);
   case Cpu of
      PIC18F4520:
           Assign(FSketch,'../../Sketch/pic18f4520_uart.txt');
   end;
  Reset(FSketch);
  while (not Eof(FSketch)) do
    begin
      Readln(FSketch,S);
      WriteLn(FInit,S);
    end;
  CloseFile(FSketch);
  Flush(FInit);
end;

procedure CompileOtherProc(Head:Boolean);
var
i:Integer;
j:TTokenKind;
B:Boolean;
S:String;
SPTok : String;
begin
    for I := 0 to High(Code) do
      if FindOperator(Code[i],PROCEDURETOK)>-1 then
        begin
          B:=True;
          for j:=STARTTOK to ONRXCHARTOK do
            if FindOperator(Code[i],j)>-1 then  B:=False;
          if B then
            begin
              S := ReplacePasToC(Code[i],PROCEDURETOK);
              S := Replace(S,SEMICOLONTOK,'(void)');
              if FindOperator(Code[i+1],BEGINTOK)=-1 then
                if Head then
                begin
                  S := S+';';
                  AddTText(MainCode,S);
                  SPTok:= Replace(Code[i],PROCEDURETOK,'');
                  SPTok:= Replace(SPTok,SEMICOLONTOK,'');
                  SPTok:= DeleteSpaceBars(SPTok,0);
                  AddTText(ProcTokens,SpTok);
                end
                else
              else
                if not Head then

                begin
                  AddTText(MainCode,S);
                  AddTText(MainCode,'{');
                  CompileText(MainCode,'',i);
                  AddTText(MainCode,'}');
                end;
            end;
        end;
end;




procedure PrepareToMain;
var i:Integer;
begin
  SetLength(ProcTokens,0);
  for i:=0 to High(Timers) do
    if Timers[i].Delay>0 then
       begin
         AddTText(MainCode,'int Timer'+IntToStr(i)+'_maxcount = '+IntToStr(Timers[i].ProgramScale)+';');
         AddTText(MainCode,'int Timer'+IntToStr(i)+'_tail = '+IntToStr(Timers[i].Tail)+';');
         AddTText(MainCode,'int Timer'+IntToStr(i)+'_counter = 0;');
       end;
  for i:=0 to High(UARTS) do
    if UARTS[i].BaudRate>0 then
      begin
        AddTText(MainCode,'unsigned char RX_'+IntToStr(i)+';');
      end;
  AddTText(MainCode,'int main(int argc, char** argv);');
  AddTText(MainCode,'void __interrupt() high_isr(void);');
  CompileOtherProc(True);
  AddTText(MainCode,'int main(int argc, char** argv)');
  AddTText(MainCode,'{');
  AddTText(MainCode,'  Init();');
end;

procedure PrepareToHigh_isr;
begin
  AddTText(MainCode,'void __interrupt() high_isr(void)');
  AddTText(MainCode,'{');
end;

{
procedure PrepareTimer;
begin
  AddTText(MainCode,'void __interrupt() high_isr(void)');
  AddTText(MainCode,'{');
end;
}

procedure RunTimer(i:Integer);
begin
  case i of
    0:
      begin
      AddTText(MainCode,'if ((INTCONbits.TMR0IF) && ( INTCONbits.TMR0IE)) {');
      AddTText(MainCode,'INTCONbits.TMR0IF = 0;');
      end;
    1:
      begin
      AddTText(MainCode,'if ((PIE1bits.TMR1IE) && (PIR1bits.TMR1IF)) {');
      AddTText(MainCode,'PIR1bits.TMR1IF = 0;');
      end;
    2:
      begin
      AddTText(MainCode,'if ((PIE1bits.TMR2IE) && (PIR1bits.TMR2IF)) {');
      AddTText(MainCode,'PIR1bits.TMR2IF = 0;');
      end;
    3:
      begin
      AddTText(MainCode,'if ((PIE2bits.TMR3IE ) && (PIR2bits.TMR3IF)) {');
      AddTText(MainCode,'PIR2bits.TMR3IF = 0;');
      end;
    end;
    AddTText(MainCode,'Timer'+IntToStr(i)+'_counter++;');
    AddTText(MainCode,'if (Timer'+IntToStr(i)+'_counter <= Timer'+IntToStr(i)+'_maxcount)');
    AddTText(MainCode,'  if (Timer'+IntToStr(i)+'_counter == Timer'+IntToStr(i)+'_maxcount) '+TimerReset(i,True));
    AddTText(MainCode,'  else '+TimerReset(i,False));
    AddTText(MainCode,'else ');
    AddTText(MainCode,'{');
    AddTText(MainCode,'Timer'+IntToStr(i)+'_counter = 0;');
    AddTText(MainCode,TimerReset(i,False));
    AddTText(MainCode,'//User code');
end;

procedure RunUART(i:Integer);
begin
  case Cpu of
    PIC18F4520:
      begin

        AddTText(MainCode,'if ((RCSTAbits.OERR)||(RCSTAbits.FERR)) {');
        AddTText(MainCode,'  RCSTAbits.CREN = 0;');
        AddTText(MainCode,'  RCSTAbits.CREN = 1;');
        AddTText(MainCode,'}');
        AddTText(MainCode,'if (PIR1bits.RCIF)');
        AddTText(MainCode,'{');
        AddTText(MainCode,'RX_'+IntToStr(i)+' = RCREG;');
        //Обработка ошибкb
        AddTText(MainCode,'//User code');
      end;
  end;
end;

procedure CompileInitGlobal;
var i:Integer;
begin
WriteLn(FInit,'');
WriteLn(FInit,'void Init(void)');
WriteLn(FInit,'{');
WriteLn(FInit,'  InitCPU();');
WriteLn(FInit,'  InitTimers();');
for i:=0 to High(UARTs) do WriteLn(FInit,'  InitUART(',i,',',Uarts[i].BaudRate,');');
WriteLn(FInit,'}');
Flush(FInit);
end;

procedure FirstRun;
var i:Integer;

begin
  if YesCompile then
    begin
      SetLength(Errors,0);
      CompileInitTimers;
      CompileInitUART;
      CompileInitGlobal;
    end;
  RunF := True;
  if YesCompile then
  begin
   // FileToText('../../operators.txt',Operators);
    //AddTText(Operators,' ');
    PasToken.Load('../../API/Operators/');
    CToken.Load('../../API/COperators/');
    FileToText('../../usercode.pas',Code);
    SetLength(MainCode,0);
    CompileConst(MainCode);
    CompileVar(MainCode);
    PrepareToMain;
    //-------Compile Standart procedures
    CompileText(MainCode,'Start');
    AddTText(MainCode,'  while (1){');   //Суперцикл.
    CompileText(MainCode,'MainLoop');
    AddTText(MainCode,'}');
    AddTText(MainCode,'  return (EXIT_SUCCESS);');
    AddTText(MainCode,'}');
    PrepareToHigh_isr;
      //Timers
    for i:=0 to High(Timers) do
      if Timers[i].Delay>0 then
        begin
          RunTimer(i);
          CompileText(MainCode,'OnTimer'+InttoStr(i));
          AddTText(MainCode,'}');
          AddTText(MainCode,'}');
        end;
      //UART
    for i:=0 to High(Uarts) do
      if Uarts[i].BaudRate>0 then
        begin
          RunUART(i);
          CompileText(MainCode,'OnRxChar'+InttoStr(i));
          AddTText(MainCode,'}');
        end;
    AddTText(MainCode,'}');
     //--------Сompile other procedures
    CompileOtherProc(False);
    For i:=0 to High(MainCode) do Writeln(FMain,MainCode[i]);
    For i:=0 to High(Errors) do WriteMemo(Errors[i]); //Вывести ошибки
    Flush(FMain);
  end;

  //InitProc := P;
end;

procedure Run;
var
  i,mini:Integer;
  mincount : Int64;
begin
  if (not RunF) then FirstRun;
  WriteMemo('Запущена процедура Start');
  InitProc;
  while true do
    begin
      mini := -1;
      mincount := 1000000000;

      for i:= 0 to High(Timers) do
        if (Timers[i].Counter<mincount) and (Timers[i].Delay>0) then
          begin
           mini := i;
           mincount := Timers[mini].Counter;
          end;
      if (i=-1) then exit;// Таймеры выключены.
      for i:= 0 to High(Timers) do
        if (Timers[i].Delay>0) then Timers[i].Counter := Timers[i].Counter-mincount;
      Application.ProcessMessages;
      if (not YesRun) then exit;
      if Realtime then Sleep(Round(mincount/1000));
      WriteMemo('Прошло '+IntTOStr(mincount)+' мкс.');
      Timers[mini].Counter := Timers[mini].Delay;
      Timers[mini].IntProc;

    end;
  //Инициализируем UART
  //Инициализируем Таймер
  //Суперцикл
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 YesRun := not YesRun;
 if YesRun then
   begin
     Button1.Caption := 'Остановить эмуляцию';
     Run;
   end
 else Button1.Caption := 'Запустить эмуляцию';
end;

procedure SetCompile;
begin
  YesCompile := True;
  Form1.Button2.Visible :=True;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 if not RunF then FirstRun;
end;


//------------Inline proc   +APIPROC
procedure SetBit;
var C:Char;
i:Integer;
begin
   C := 'A';
   For i:=0 to (Port div 10)-1 do inc(C);
   WriteMemo('Порт R'+C+Chr($30+Port mod 10)+' успешно установлен на '+IntTOStr(Bit));
end;

procedure FastTx;
var
A:Array of Byte;
begin
  UARTS[USART].TXReg := Byte(Data);
  SetLength(A,1);
  A[0] := UARTS[USART].TXReg;
  if @UARTS[USART].OnPCRxChar<>nil then UARTS[USART].OnPCRxChar(A,1);
end;

procedure FastRx(USART:Byte;var Data:Byte);
begin
  Data := UARTS[USART].RxReg;
end;

procedure TransferStr(S:AnsiString);
var
A:Array of Byte;
i,n:Integer;
begin
  n := Length(S);
  SetLength(A,n);
  for I := 0 to n-1 do  A[i]:=Byte(S[i+1]);
  if @UARTS[0].OnPCRxChar<>nil then UARTS[0].OnPCRxChar(A,n);
end;

procedure InitUART(Port:Byte;BaudRate:Integer);
begin
  SetUart(Port,BaudRate,UARTS[Port].OnRxChar,UARTS[Port].OnPCRxChar);
end;

begin
  SetLength(UARTs,PICControllers.Uarts);
  SetLength(Timers,PICControllers.Timers);



end.

