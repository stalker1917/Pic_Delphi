program Project1;

uses
  Vcl.Forms,
  piclibrary in 'API\piclibrary.pas' {Form1},
  translator in 'API\translator.pas',
  usercode in 'usercode.pas',
  common in 'API\common.pas',
  tokens in 'API\tokens.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  //-------���������������� ���
  Cpu := PIC18F4520; //������ �PU
  Quartz := 8;  //������� ������ � ���,INTERAL -����������.
  SetCompile; //����������� C- ���������
  //YesCompile := True;//True;
  RealTime   := True; //����� �� ������� ,��� �� �����������.
  SetAsIn(RF);
  SetAsIn(RA+2); //���������� ���� RA2 ��� �������.
  SetAsIn(RA+5);
  //SetTimer(1,9,nil);
  InitCPU;
  SetTimer(1,1000,OnTimer1);
  SetTimer(2,3000*Millisecond,OnTimer2);
  SetUART(0,115200,OnRxChar0,nil);
  InitProc := Start; //��������� , ������� ����������� ��� ������.
  //����� ����������������� �����.
  Application.Run;
  //Run(Start);
end.
