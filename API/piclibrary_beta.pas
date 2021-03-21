

unit piclibrary;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,translator,Common,Tokens, Vcl.StdCtrls,Math;

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
   Prescale : Word;
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
  Second = 1000*Millisecond;
  ReportRWPort = False; // ��������� � ���, ������� ���� �� ������ ��� ������ � ����
  PathOperators = '../../../';
  PathSketch = '../../../Sketch/';
  MainTail = '_main.txt';
  InitTail = '_init.txt';
  TimersTail='_timers.txt';
  UartTail='_uart.txt';
  ApiTail='_api.txt';
  ApihTail='_apih.txt';
var
  Form1: TForm1;
  Quartz      : Integer; //Mhz
  Clock       : Integer;
  YesCompile  : Boolean = False;
  RealTime    : Boolean = True;
  EC          : Boolean = False; //EC or HC Clock;
  FMain       : Text;
  FInit       : Text;
  FSketch     : Text;
  InitCPUF    : Boolean = False; //��������� �� ������������� CPU;
  RunF        : Boolean = False; //��������� �� ������������� ��������;
  TRIS        : Array [0..6] of Byte = (0,0,0,0,0,0,0);
  MainCode    : TText;
  UARTs       :  Array of TUART;
  Timers      :  Array of TTimer;
  InitProc    :  procedure;
  PICControllers : TPICCOntroller = (Clock : 40; Timers:4; Uarts:1);
  PIC32MZSetup   : TPICCOntroller = (Clock : 200; Timers:9; Uarts:6);
  CurrController : TPICCOntroller;
  YesRun      : Boolean=False;
  Ports       :  Array[0..6] of ^LongWord;
  PortA,PortB,PortC,PortD,PortE,PortF:LongWord; // ��� ������ � 32bit;
  OnPort      : TInterrupt = nil;
  MLoop       : TInterrupt = nil;
  MainPort    : Byte = 0;

procedure PrepareToMain;
procedure Run; //��������� ������������� ������������.
procedure InitCPU; //������������� CPU
procedure SetTimer(N:Byte;Delayus:Int64;Interrupt:TInterrupt);//������������� USART
//������������� ��������.
procedure SetUart(N:Byte; BaudRate:LongInt; Interrupt:TInterrupt; PcProc : TCallBackProc);
procedure SetAsIn(Port:Byte);
procedure SetBit(Port,Bit:Byte);
procedure FastRx(USART:Byte;var Data:Byte);
procedure FastTx(USART:Byte;Data:AnsiChar); overload;
procedure FastTx(USART:Byte;Data:Byte); overload;
procedure SetCompile;
procedure TransferStr(S:AnsiString);
procedure ChangePort(N:Byte);
procedure InitUART(Port:Byte;BaudRate:Integer);
procedure Nop;
procedure GetBit(Port:Byte;var Bit:Byte;InvertTRISA:Boolean=False);
procedure SetCPU(In_CPU:word);

implementation

{$R *.dfm}

Procedure WriteMemo(S:String);
begin
  Form1.Memo1.Lines.Add(S);
end;


procedure InitCPU;
var S:String;
C:Char;
i,j,Indiv:Integer;
CPU_Div:Integer;
Procedure CalcCpu_div;
var i:Integer;
begin
CPU_Div := Round(200/PIC32MZSetup.Clock);
if CPU_Div<1  then CPU_Div := 1;
if CPU_Div>16 then CPU_Div := 16;
j := 1;
  for I := 1 to 5 do
    begin
      if abs(CPU_Div-j)<abs(CPU_Div-2*j) then break;
      j:=j*2;
    end;
CPU_Div := j*2;
end;
  begin
   case Cpu of
      PIC18F4520:             CurrController := PICControllers;
      PIC32MZ64..PIC32MZ144:  CurrController := PIC32MZSetup;
   end;
  SetLength(UARTs,CurrController.Uarts);
  SetLength(Timers,CurrController.Timers);
    if initCPUF then
      begin
        WriteMemo('������: ������ �������� ������� InitCPU ��� ����!');
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
   // case Cpu of
      //PIC18F4520:
      if YesCompile then
        begin
          Assign(FSketch,PathSketch+CPU_Name[CPU]+MainTail);
          Reset(FSketch);
          while (not Eof(FSketch)) do
            begin
              Readln(FSketch,S);
              WriteLn(FMain,S);
            end;
          close(FSketch);
          Assign(FSketch,PathSketch+CPU_Name[CPU]+InitTail);
          Reset(FSketch);
          while (not Eof(FSketch)) do
            begin
              Readln(FSketch,S);
              WriteLn(FInit,S);
            end;
          Close(FSketch);
          CopyFile(PWideChar(PathSketch+CPU_Name[CPU]+APITail),'pasapi.c',false);
          CopyFile(PWideChar(PathSketch+CPU_Name[CPU]+APIHTail),'pasapi.h',false);
        end;
   case Cpu of
      PIC18F4520:
        begin
         // Clock :=  PICControllers.Clock;//PIC18F4520_Clock;
          if Quartz>PICControllers.Clock then
            begin
              WriteMemo('���������� ���������� ���������.');
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
                WriteMemo('���������� ������� ��������� �������� '+IntToStr(Quartz)+' ���. ����� HS.');
                if YesCompile then WriteLn(FMain,'#pragma config OSC = HS');
              end
            else
              begin
                Clock := Quartz*4;
                WriteMemo('���������� ������� ��������� �������� '+IntToStr(Quartz)+' ���. ����� HSPLL.');
                if YesCompile then WriteLn(FMain,'#pragma config OSC = HSPLL');
              end;
          WriteMemo('������� ����������� - '+IntToStr(Clock)+' ���.');
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
      PIC32MZ64..PIC32MZ144:
        begin
          if Quartz>PIC32MZSetup.Clock then
            begin
              WriteMemo('���������� ���������� ���������.');
              if YesCompile then
                begin
                WriteLn(FMain,'#pragma config FPLLICLK =   PLL_FRC ');
                WriteLn(FMain,'#pragma config FPLLRNG =    RANGE_5_10_MHZ');
                WriteLn(FMain,'#pragma config FPLLIDIV =   DIV_1');
                WriteLn(FMain,'#pragma config FPLLMULT =    MUL_50');
                CalcCpu_div;
                WriteLn(FMain,'#pragma config FPLLODIV =   DIV_'+IntToStr(CPU_Div));
                Clock := Round(PIC32MZSetup.Clock/CPU_Div);
                end;
            end
          else
            if Quartz<8 then WriteMemo('������. ������ ������������ ��������� ������ 8���')
            else if Quartz>64 then WriteMemo('������. ������ ������������ ��������� ������ 64���')
            else
              begin
                WriteMemo('���������� ������� ��������� �������� '+IntToStr(Quartz)+'���.');
                if not EC then WriteLn(FMain,'#pragma config POSCMOD =    HS              // External OSC ')
                          else WriteLn(FMain,'#pragma config POSCMOD =    EC              // External Clock ');
                if Quartz=12 then WriteLn(FMain,'#pragma config UPLLFSEL =   FREQ_12MHZ');
                if Quartz=24 then WriteLn(FMain,'#pragma config UPLLFSEL =   FREQ_24MHZ');
                WriteLn(FMain,'#pragma config FPLLICLK =   PLL_POSC');
                case Quartz of
                  8..9: WriteLn(FMain,'#pragma config FPLLRNG =    RANGE_5_10_MHZ');
                  10..14: WriteLn(FMain,'#pragma config FPLLRNG =    RANGE_8_16_MHZ');
                  15..23: WriteLn(FMain,'#pragma config FPLLRNG =    RANGE_13_26_MHZ');
                  24..38: WriteLn(FMain,'#pragma config FPLLRNG =    RANGE_21_42_MHZ');
                  39..64: WriteLn(FMain,'#pragma config FPLLRNG =    RANGE_34_64_MHZ');
                end;
                for Indiv := 1 to 8 do if (Quartz/Indiv)<=16 then break;
                WriteLn(FMain,'#pragma config FPLLIDIV =   DIV_'+IntToStr(Indiv));
                i := Round(400*Indiv/Quartz);
                WriteLn(FMain,'#pragma config FPLLMULT =    MUL_'+IntToStr(i));
                CalcCpu_div;
                WriteLn(FMain,'#pragma config FPLLODIV =   DIV_'+IntToStr(CPU_Div));
                Clock:=Round(i*Quartz/(CPU_Div*Indiv));
                WriteMemo('�������� ������� '+IntToStr(Clock)+'���.');
              end;
        end;
    end;
//���������� ���������������� ���������.
  if YesCompile then WriteLn(FInit,'}');
  if YesCompile then Flush(FMain);
  if YesCompile then Flush(FInit);
For i := 0 to High(Timers) do  Timers[i].Delay := 0;  //������� ���������.
For i := 0 to High(UARTS)  do  UARTS[i].BaudRate := 0; //����� ���������


end;

function FlagAnalisis:Boolean;
begin
  result := False;
  if (not InitCpuf) then
    begin
      WriteMemo('������ ���������������� ������� �� ������������� �����������');
      result := True;
    end;
  if (Runf) then
    begin
      WriteMemo('������ ���������������� ������� �� �������� ��������� ����� �������');
      result := True;
    end;
end;

procedure SetTimer(N:Byte;Delayus:Int64;Interrupt:TInterrupt);
var FCycles : Double;
MaxTimer,NCrit,MaxPrescale,MaxPrescaleCrit:LongWord;
Step,StepCrit :Word;
Divider :Word;

Procedure SetConfig(C1,C2,C3,C4,C5,C6:LongWord);
begin
   MaxTimer        := C1;
   NCrit           := C2;
   MaxPrescale     := C3;
   MaxPrescaleCrit := C4;
   Step            := C5;
   StepCrit        := C6;
end;

begin
  if FlagAnalisis then exit;
  if N>High(Timers) then WriteMemo('������� '+IntToStr(N)+' �� ���������� ��� ������� ���� ������������')
  else
    begin
      Timers[N].IntProc := Interrupt;
      Timers[N].Delay := Delayus;
      Timers[N].Counter := Delayus;
      case Cpu of
        PIC18F4520: Divider := 4;  //����� �� ��� MZ ��� ��?
        PIC32MZ64..PIC32MZ144:  Divider:=  2;
      end;
      FCycles := (Clock*Delayus)/Divider;
      Timers[N].Prescalecode := 0;
      Timers[N].Prescale := 1;
      case Cpu of
        PIC18F4520: SetConfig(255,2,16,8,2,4);
        PIC32MZ64..PIC32MZ144: SetConfig(65535,0,64,256,2,8);
      end;
      if N<>NCrit  then
        while (FCycles>MaxTimer) and (Timers[N].Prescale<MaxPrescale) do
          begin
            Timers[N].Prescale := Timers[N].Prescale*Step ;
            inc(Timers[N].Prescalecode);
            FCycles := FCycles/Step;
          end
      else
        while (FCycles>MaxTimer) and (Timers[N].Prescale<MaxPrescaleCrit) do
          begin
            Timers[N].Prescale := Timers[N].Prescale*StepCrit;
            inc(Timers[N].Prescalecode);
            FCycles := FCycles/StepCrit;
          end;
      Timers[N].ProgramScale := Trunc(FCycles/(MaxTimer+1)); //������� ����� �� 255
      Timers[N].Tail := Round(FCycles) - Timers[N].ProgramScale*(MaxTimer+1); //��������� ���� ����������.
      if Clock>0 then WriteMemo('����������� ������������ ������� �'+IntToStr(N)+' �� ��������� '+FloatToStr((Round(FCycles)*Timers[N].Prescale*Divider)/Clock)+' ���')
      else  WriteMemo('������ ������������� �������: ������� ����������� ������-�� ����������� 0');
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
  if N>High(UARTS) then WriteMemo('����� '+IntToStr(N)+' �� ���������� ��� ������� ���� ������������')
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
            WriteMemo('����������� �������� '+IntToStr(Division(SPBRG+SPBRH*256+1)));
          end;
       PIC32MZ64..PIC32MZ144:
         begin
           Scale := 8;
           SPBRG := Division(BaudRate)-1;
           WriteMemo('UxBRG = '+InttoStr(SPBRG));
           WriteMemo('����������� �������� '+IntToStr(Division(SPBRG+1)));
         end;
      end;

    end;
end;


procedure SetAsIn(Port:Byte);
var c:Char; i:Integer;
begin
  if initCPUF then WriteMemo('������: ������ �������� ���� �� ���� ����� ���������� InitCPU!')
  else
    begin
      case Cpu of
        PIC18F4520:
          if Port>42 then
             begin
               WriteMemo('������: ��� ������ �����!');
               exit;
             end;
      end;
      C := 'A';
      For i:=0 to (Port div 10)-1 do inc(C);
      WriteMemo('���� R'+C+Chr($30+Port mod 10)+' ������� ����� �� ����');
      TRIS[Port div 10]:= TRIS[Port div 10] or (1 shl (Port mod 10));
    end;
end;

Function TimerReset(i:Integer;ForceTail:Boolean):String;
var j,k:Integer;
begin
       case CPU of
         PIC18F4520 : k:=i;
         PIC32MZ64..PIC32MZ144    : k:=i+1;
       end;

       if (Timers[i].ProgramScale>0) and (not ForceTail) then
           if ((i mod 2)=0) or (Cpu<>PIC18F4520) then Result := 'TMR'+IntToStr(k)+' = 0;'
                                                 else Result := 'TMR'+IntToStr(k)+' = 0xff00;'
        else
          begin
           if ((i mod 2)=0) and (Cpu=PIC18F4520)    then j:=256-Timers[i].Tail
                                                    else j:=65536-Timers[i].Tail; //���� 66526
           //if ForceTail then Result := 'TMR'+IntToStr(k)+' = Timer'+IntToStr(i)+'_tail'+';'
                        {else} Result := 'TMR'+IntToStr(k)+' = '+IntToStr(j)+';';
          end;
end;

procedure CompileInitTimers;
var S:String;
i,j:Integer;
begin
  Assign(FSketch,PathSketch+CPU_Name[CPU]+TimersTail);
  Reset(FSketch);
  while (not Eof(FSketch)) do
    begin
      Readln(FSketch,S);
      WriteLn(FInit,S);
    end;
  CloseFile(FSketch);
  //���������� init
  {for I := 0 to 8 do
    begin
       WriteLn(FInit,'//Init Timer',i+1);
       WriteLn(FInit,'T',i+1,'CONbits.ON = 0;');
       WriteLn(FInit,'IPC',i+1,'bits.T',i+1,'IF = 0;');
       WriteLn(FInit,'IFS0bits.T',i+1,'IF = 0;');
       WriteLn(FInit,'IEC0bits.T',i+1,'IE = 0;');
       WriteLn(FInit,'');
    end; }

  For i := 0 to High(Timers) do
    if Timers[i].Delay>0 then
    case CPU of
    PIC18F4520:
      begin
        if i=0 then WriteLn(FInit,'T',i,'CONbits.T',i,'PS = ',Timers[i].PrescaleCode,';')
               else WriteLn(FInit,'T',i,'CONbits.T',i,'CKPS = ',Timers[i].PrescaleCode, ';');
        WriteLn(FInit,TimerReset(I,False));
        WriteLn(FInit,'T',i,'CONbits.TMR',i,'ON = 1;');
        WriteLn(FInit,'');
      end;
    PIC32MZ64..PIC32MZ144:
      begin
        if (i mod 2 = 1) then  WriteLn(FInit,'T',i+1,'CONbits.T32 = 0;');
        WriteLn(FInit,'T',i+1,'CONbits.TCKPS =',Timers[i].PrescaleCode,';');
        WriteLn(FInit,'T',i+1,'CONbits.ON = 1;');
        WriteLn(FInit,'');
      end;
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
   Assign(FSketch,PathSketch+CPU_Name[CPU]+UARTTail);
   //case Cpu of
     // PIC18F4520:
    //       Assign(FSketch,'../../../Sketch/pic18f4520_uart.txt');
  // end;
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
  case CPU of
     PIC18F4520: AddTText(MainCode,'void __interrupt() high_isr(void);');
     PIC32MZ64..PIC32MZ144 : AddTText(MainCode,'void __ISR(0, ipl1) InterruptHandler(void);');
  end;
  CompileOtherProc(True);
  AddTText(MainCode,'int main(int argc, char** argv)');
  AddTText(MainCode,'{');
  AddTText(MainCode,'  Init();');
end;

procedure PrepareToHigh_isr;
begin
   case CPU of
     PIC18F4520: AddTText(MainCode,'void __interrupt() high_isr(void)');
     PIC32MZ64..PIC32MZ144 : AddTText(MainCode,'void __ISR(0, ipl1) InterruptHandler(void)');
  end;
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
  case CPU of
  PIC18F4520:
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
  PIC32MZ64..PIC32MZ144:
    if i<6 then
      begin
        AddTText(MainCode,'if ((IFS0bits.T'+IntToStr(i+1)+'IF) && (IEC0bits.T'+IntToStr(i+1)+'IE)) {');
        AddTText(MainCode,'IFS0bits.T'+IntToStr(i+1)+'IF = 0;');
      end
    else
      begin
        AddTText(MainCode,'if ((IFS1bits.T'+IntToStr(i+1)+'IF) && (IEC1bits.T'+IntToStr(i+1)+'IE)) {');
        AddTText(MainCode,'IFS1bits.T'+IntToStr(i+1)+'IF = 0;');
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
var
S,S2:String;
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
        //��������� �����b
        AddTText(MainCode,'//User code');
      end;
    PIC32MZ64..PIC32MZ144:
      begin
        S:='U'+IntToStr(i+1);
        AddTText(MainCode,'if (('+S+'STAbits.OERR)||('+S+'STAbits.FERR)) {');
        AddTText(MainCode,'  '+S+'STAbits.URXEN = 0;');
        AddTText(MainCode,'  '+S+'STAbits.URXEN = 1;');
        AddTText(MainCode,'}');
        case i of
          0:    S2:= 'IFS3bits.';
          1,2:  S2:= 'IFS4bits.';
          3..5: S2:= 'IFS5bits.';
        end;
        AddTText(MainCode,'if ('+S2+S+'RXIF)'+' while ('+S+'STAbits.URXDA)');
        AddTText(MainCode,'{');
        AddTText(MainCode,'RX_'+IntToStr(i)+' = '+S+'RXREG;');
        //��������� ������
        AddTText(MainCode,'//User code');
      end;
  end;
end;

procedure EndUART(i:Integer);
var
S,S2:String;
begin
  AddTText(MainCode,'}');
  case Cpu of
    PIC32MZ64..PIC32MZ144:
      begin
        S:='U'+IntToStr(i+1);
        case i of
          0:    S2:= 'IFS3bits.';
          1,2:  S2:= 'IFS4bits.';
          3..5: S2:= 'IFS5bits.';
        end;
        AddTText(MainCode,S2+S+'RXIF = 0;'); //����� �����.
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
for i:=0 to High(UARTs) do
 if Uarts[i].BaudRate>0 then WriteLn(FInit,'  InitUART(',i,',',Uarts[i].BaudRate,');');
WriteLn(FInit,'}');
Flush(FInit);
end;

procedure FirstRun;
var i:Integer;

begin
  if YesCompile then
    begin
      CompileInitTimers;
      CompileInitUART;
      CompileInitGlobal;
    end;
  RunF := True;
  if YesCompile then
  begin
   // FileToText('../../operators.txt',Operators);
    //AddTText(Operators,' ');
    PasToken.Load(PathOperators+'API/Operators/');
    CToken.Load(PathOperators+'API/COperators/');
    FileToText('../../usercode.pas',Code);
    SetLength(MainCode,0);
    SetLength(Errors,0);
    CompileConst(MainCode);
    //CompileType(MainCode);
    CompileVarType(MainCode,True);
    CompileVarType(MainCode);
    PrepareToMain;
    //-------Compile Standart procedures
    CompileText(MainCode,'Start');
    AddTText(MainCode,'  while (1){');   //���������.
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
          EndUART(i);
          //AddTText(MainCode,'}');
          //case Cpu of  ��� do..whilw
          //PIC32MZ64..PIC32MZ144: AddTText(MainCode,' while ('+'U'+IntToStr(i+1)+'STAbits.URXDA)');
          //end;
        end;
    AddTText(MainCode,'}');
     //--------�ompile other procedures
    CompileOtherProc(False);


    For i:=0 to High(Errors) do Form1.Memo1.Lines.Add(Errors[i]);//Writeln(FMain,MainCode[i]);
    For i:=0 to High(MainCode) do Writeln(FMain,MainCode[i]);
    Flush(FMain);
  end;

  //InitProc := P;
end;

procedure Run;
var
  i,mini:Integer;
  mincount : Int64;
  A:Array of Byte;
begin
  if (not RunF) then FirstRun;
  WriteMemo('�������� ��������� Start');
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
      if (i=-1) then exit;// ������� ���������.
      for i:= 0 to High(Timers) do
        if (Timers[i].Delay>0) then Timers[i].Counter := Timers[i].Counter-mincount;
      Application.ProcessMessages;
      if (not YesRun) then exit;
      if Realtime then Sleep(Round(mincount/1000));
      WriteMemo('������ '+IntTOStr(mincount)+' ���.');
      Timers[mini].Counter := Timers[mini].Delay;
      Timers[mini].IntProc;
      if @MLoop<>nil then MLoop;
      SetLength(A,4);
      for I := 0 to 3 do
        begin
          A[i]:= mincount  mod 256;
          mincount  := mincount  div 256;
        end;
      for I := 0 to High(UARTS) do
        if @UARTS[i].OnPCRxChar<>nil then UARTS[i].OnPCRxChar(A,-1);
    end;
  //�������������� UART
  //�������������� ������
  //���������
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 YesRun := not YesRun;
 if YesRun then
   begin
     Button1.Caption := '���������� ��������';
     Run;
   end
 else Button1.Caption := '��������� ��������';
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

procedure SetCPU(In_CPU:word);
begin
  if In_CPU>High_CPU then  Cpu := 0
  else Cpu := In_CPU;
end;


//------------Inline proc   +APIPROC
procedure SetOneBit(var Prt:LongWord;Nbit:Byte; YesSet:Boolean);
begin
  Prt := Prt or Round(Power(2,NBit));
  if not YesSet then Prt := Prt xor Round(Power(2,NBit));
end;

function GetOneBit(Prt:LongWord;Nbit:Byte):Byte;
begin
  Prt := Prt shr Nbit;
  result := Prt mod 2;
end;


procedure SetBit;  //���������� �� 32  ����
var C:Char;
i,NPort:Integer;

begin
   C := 'A';
   Nport := Port div 10;
   For i:=0 to Nport-1 do inc(C);
   //���� �� ��������� �� TRIS
   SetOneBit(Ports[Nport]^,Port mod 10,Bit>0);
   if ReportRWPort then WriteMemo('���� R'+C+Chr($30+Port mod 10)+' ������� ���������� �� '+IntTOStr(Bit));
   if @OnPort<>nil then OnPort;
end;

procedure GetBit;
var C:Char;
i,NPort,NPin:Integer;
begin
   C := 'A';
   NPort := Port div 10;
   Npin := Port mod 10;
   For i:=0 to (NPort)-1 do inc(C);
   Bit:=GetOneBit(TRIS[NPort],Npin);
   if (InvertTrisa xor (Bit>0)) then
     begin
       Bit:=GetOneBit(Ports[NPort]^,Npin);
       if ReportRWPort then WriteMemo('���� R'+C+Chr($30+Port mod 10)+' ���������� � ��������� '+IntTOStr(Bit));
     end;
end;

procedure FastTx(USART:Byte;Data:AnsiChar);
var
A:Array of Byte;
begin
  UARTS[USART].TXReg := Byte(Data);
  SetLength(A,1);
  A[0] := UARTS[USART].TXReg;
  if @UARTS[USART].OnPCRxChar<>nil then UARTS[USART].OnPCRxChar(A,1);
end;

procedure FastTx(USART:Byte;Data:Byte);
var
A:Array of Byte;
begin
  UARTS[USART].TXReg := Data;
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
  if @UARTS[MainPort].OnPCRxChar<>nil then UARTS[MainPort].OnPCRxChar(A,n);
end;

Procedure ChangePort;
begin
  MainPort := N;
end;

procedure InitUART(Port:Byte;BaudRate:Integer);
begin
  SetUart(Port,BaudRate,UARTS[Port].OnRxChar,UARTS[Port].OnPCRxChar);
end;

procedure Nop;
var a:byte;
begin
  a:=0;
end;



begin
  Ports[0] := @PortA;
  Ports[1] := @PortB;
  Ports[2] := @PortC;
  Ports[3] := @PortD;
  Ports[4] := @PortE;
  Ports[5] := @PortF;
end.

