program PIC_Translator;

uses
  Vcl.Forms,
  piclibrary in '..\API\piclibrary.pas' {Form1},
  translator in '..\API\translator.pas',
  usercode in 'usercode.pas',
  common in '..\API\common.pas',
  tokens in '..\API\tokens.pas',
  ADC_emulator in 'ADC_emulator.pas';

{$R *.res}

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  //-------Пользовательский код
  SetCPU(PIC32MZ64); //Модель СPU  PIC18F4520
  Quartz := 24;  //Частота кварца в МГц,INTERAL -внутренний.
  EC := True;  //ExternalClock;
  SetCompile; //Компилируем C- программу
  //YesCompile := True;//True;
  RealTime   := True; //Такие же времена ,как на контроллере.
  //SetAsIn(RC+4); //Установить порт RC4 как входной.
  //SetTimer(1,9,nil);
  InitCPU;
  SetTimer(1,10*MilliSecond,OnTimer1);  //в кмс.
  SetTimer(2,2*Second,OnTimer2);
  SetUART(0,115200,OnRxChar0,nil);
  SetUART(1,115200,OnRxChar1,nil);
  SetUART(2,115200,OnRxChar2,nil);
  SetUART(4,115200,OnRxChar4,nil);
  OnPort := OnPortChange;
  InitProc := Start; //Процедура , которая выполниться при старте.
  //Конец пользовательского когда.
  Application.Run;
  //Run(Start);
end.
