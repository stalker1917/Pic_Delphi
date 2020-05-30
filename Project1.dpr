program Project1;

uses
  Vcl.Forms,
  piclibrary in 'API\piclibrary.pas' {Form1},
  translator in 'API\translator.pas',
  usercode in 'usercode.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  //-------Пользовательский код
  Cpu := PIC18F4520; //Модель СPU
  Quartz := 8;  //Частота кварца в МГц,INTERAL -внутренний.
  SetCompile; //Компилируем C- программу
  //YesCompile := True;//True;
  RealTime   := True; //Такие же времена ,как на контроллере.
  SetAsIn(RF);
  SetAsIn(RA+2); //Установить порт RA2 как входной.
  SetAsIn(RA+5);
  //SetTimer(1,9,nil);
  InitCPU;
  SetTimer(1,5000000,OnTimer1);
  SetTimer(2,3000*Millisecond,OnTimer2);
  InitProc := Start; //Процедура , которая выполниться при старте.
  //Конец пользовательского когда.
  Application.Run;
  //Run(Start);
end.
