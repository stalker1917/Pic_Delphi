unit ADC_emulator;
//Эмулируем оцифровку данных . Что оцифровывам, зависит от PORTD
//AD7680

interface
uses piclibrary;




Procedure OnPortChange;

implementation
const
  DeviceNumber = RC;
  Mux_Number = RD;
  CS_pin=2;
  SCLK_pin=3;
  SDATA_pin=4;

var
  OState : Boolean = False;
  ClkState : Boolean = False;
  Clk_Num : Byte = 0;
  SDATA : Byte = 0;

Function GetData(Clk_Num:Byte):Byte;
var Data:Word;
begin
  if Ports[Mux_Number div 10]^<6 then Data := Ports[Mux_Number div 10]^*10000;
  if (Clk_Num<3) or (Clk_Num>18) then result:=0
  else result := (Data shr (15-Clk_Num+3) ) mod 2;
end;

Procedure OnPortChange;
var CS,SCLK:Byte;
begin
  GetBit(DeviceNumber+CS_pin,CS,True);
  GetBit(DeviceNumber+SCLK_pin,SCLK,True);
  if CS=0 then
    if not OState then
      begin
       OState :=True;
       Clk_Num := 0;
       exit;
      end
    else
  else OState :=False;
  if (SCLK=0) and (OState) and (not ClkState)  then
    begin
      ClkState := True;
      SDATA :=GetData(Clk_Num);
      SetBit(DeviceNumber+SDATA_pin,SDATA);
    end;
  if (SCLK=1) and (OState) and (ClkState)  then
    begin
      ClkState := False;
      inc(Clk_Num);
    end;
end;

end.
