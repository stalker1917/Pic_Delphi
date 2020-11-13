program Project1;

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
  //-------���������������� ���
  SetCPU(PIC32MZ64); //������ �PU  PIC18F4520
  Quartz := 24;  //������� ������ � ���,INTERAL -����������.
  EC := True;  //ExternalClock;
  SetCompile; //����������� C- ���������
  //YesCompile := True;//True;
  RealTime   := True; //����� �� ������� ,��� �� �����������.
  SetAsIn(RC+4); //���������� ���� RC4 ��� �������.
  //SetTimer(1,9,nil);
  InitCPU;
  SetTimer(1,10*MilliSecond,OnTimer1);  //� ���.
  SetTimer(2,2*Second,OnTimer2);
  SetUART(0,115200,OnRxChar0,nil);
  OnPort := OnPortChange;
  InitProc := Start; //��������� , ������� ����������� ��� ������.
  //����� ����������������� �����.
  Application.Run;
  //Run(Start);
end.
