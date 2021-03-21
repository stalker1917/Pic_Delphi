unit Translator;
interface
uses  System.SysUtils;
type
 TText = Array of String; 
 TConstI = Record
     S : String;
     N : Integer;
   End;
  TConstS = Record
     Sname,SValue : String;
   End;
var    
 Code,Operators,ConstN : Ttext;
function FindStrWithOperator(var Dump : TText; Number : Integer; FirstStr:Integer = 0) : Integer;
function FindOperator(S:String; Number:Integer; pos:Integer) :Integer;
Procedure FileToText(S:String;var Dump:TText); 
Procedure CompileConst(var OutCode:TText); 
Procedure CompileVar(var OutCode:TText); 
Procedure CompileText(var OutCode:TText;FindStr:String); 
Procedure AddTText(var T:TText; S:String);
implementation
Procedure FileToText(S:String;var Dump:TText);
var //s1:Ansistring;
s1:String;
f:Text;
begin
  Assignfile(f,s); //Список операторов
  Reset(f);
  SetLength(Dump,0);
  while not eof(f) do
    begin
      readln(f,s1);
      SetLength(Dump,Length(Dump)+1);
      Dump[Length(Dump)-1] := s1;//UTF8ToWideString(s1);
    end;
 //if Dump[0,1]=#$FEFF then Dump[0] := Copy(Dump[0],2,Length(Dump[0])-1);
 closeFile(f);
end;

function FindStrWithOperator;
var i,a:Integer;
begin
  result := -1;
  for i := FirstStr to High(Dump) do
    begin
      a:=FindOperator(Dump[i],Number,1);
      if a>-1 then
        begin
          result := i;
          exit;
        end;
    end;
end;

function FindOperator;
var i,High:Integer;
begin
  High := Length(s)-Length(Operators[Number])+1;
  Result := -1;
  for I := pos to High do
    if (s[i]=Operators[Number][1]) and (Copy(S,i,Length(Operators[Number]))=Operators[Number]) then
      begin
        Result := i;
        Break;
      end;
  //if i>High then  Result := -1;
end;

function ToCycle(var S:String;N:Integer):Integer;
var i:Integer;
begin
   if N=-1 then
     begin
       result := -1;
       N      :=  1;
     end
   else result := Length(S);
   for I := N to Length(S) do
     if (S[i]<>' ') and (S[i]<>#9) xor (result>0) then
      begin
        result:=i;
        break;
      end;
end;

function DowntoCycle(var S:String;N:Integer):Integer;
var i:Integer;
begin
   result := -1;
   if N<0 then N:= Length(S)
          else result := 1;
   for I := N downto 1 do
     if (S[i]<>' ') and (S[i]<>#9) xor (result=1) then
      begin
        result:=i+1;
        break;
      end;
end;


function DeleteSpaceBars(S:String; Mode:Integer):String;// Удаляем проблемы
var i,a,b:Integer;
begin

   case Mode of
     0:      // ___Vasa_123__  ---->Vasa_123
       begin
         a := ToCycle(S,-1);
         b := DowntoCycle(S,-1);
       end;
     1:    // ___Vasa_123__  ---->Vasa
        begin
         a := ToCycle(S,-1);
         b := ToCycle(S,a);
        end;
     2:      // ___Vasa_123__  ---->_123
       begin
         b := DownToCycle(S,-1);
         a := DownToCycle(S,b);
        end;
   end;

 if (a<0) or (b<0) or (a>b) then result := ''
 else result := Copy(S,a,b-a+1);
end;

Procedure AddTText(var T:TText; S:String);
begin
  SetLength(T,Length(T)+1);
  T[High(T)] := S;
end;

function Replace(const S:String;N:Integer;RepStr:String):String;
var
a,b : Integer;
begin
  a := FindOperator(S,N,1);
  b := Length(Operators[N]);
  if a>-1 then  result := Copy(S,1,a-1)+RepStr+Copy(S,a+b,Length(S)-a-b+1)
  else result := S;
end;

procedure CodeToPort(NString,Pos:Integer;Var S:String);
var b,c:Integer;
begin
  S := S+'PORT'+Code[NString][Pos+1]+'bits.'+Copy(Code[NString],Pos,2);
  b := FindOperator(Code[NString],2,1);
  if b=-1 then S:=S+'0'
    else 
      begin
        c := FindOperator(Code[NString],5,1); 
        S:= S + DeleteSpaceBars(Copy(Code[NString],b+1,c-b-1),1);
      end;
end;

//--------Main Code----
Procedure CompileConst; 
var a,b,c,i,j:Integer;
S:String;
begin
  i:=FindStrWithOperator(Code,26)+1;
  if i=-1 then exit;   
  SetLength(ConstN,0);
  j:=0;
  while FindOperator(Code[i],4,1) >-1 do
    begin
      inc(j);
      a := FindOperator(Code[i],4,1); //
      S:= Copy(Code[i],1,a-1);
      AddTText(ConstN,DeleteSpaceBars(S,1));
      //ConstN[j-1] := DeleteSpaceBars(S,1); //Запоминаем название константы. 
      S := '#define '+S+' ';
      b := FindOperator(Code[i],27,a);
      if b>-1 then CodeToPort(i,b,S)
      else 
        S := S + IntToStr(StrToInt(Copy(Code[i],b+1,c-b-1)));
      AddTText(OutCode,S);
      inc(i);   
    end;
end;

Procedure CompileVar(var OutCode:TText); 
var a,b,c,i,j:Integer;
S:String;
begin
  i:=FindStrWithOperator(Code,13)+1;  //var
  if i=-1 then exit;   
  while FindOperator(Code[i],22,1) >-1 do  //: 
    begin
      for j:= 14 to 19 do 
        if  FindOperator(Code[i],j,1)>-1 then
          begin
              case j of 
                 14:
                   begin
                     a := FindOperator(Code[i],28,1);
                     if a=-1 then S := 'char[32] '  
                     else 
                       begin
                         b := FindOperator(Code[i],29,a);
                         S := 'char'+Copy(Code[i],a,b-a+1)+' ';
                       end;
                   end;
                 15: S := 'unsigned char '; 
                 16: S := 'int ';
                 17: S := 'float ';
                 18: S := 'unsigned int ';
                 19: S := 'int ';
              end;
              a := FindOperator(Code[i],j,1);
              S:=S+DeleteSpaceBars(Copy(Code[i],1,a),1)+';';
              AddTText(OutCode,S);
              break;
          end;  
      inc(i);
    end;
end;

procedure CompileText;
var a,b,c,i,j:Integer;
State:Integer;
S:String;
begin
  a := FindStrWithOperator(Code,34); 
  if a=-1 then exit;
  Operators[High(Operators)] := FindStr;
  a := FindStrWithOperator(Code,High(Operators),a);
  if a=-1 then exit;
  i:=a;
  repeat 
    inc(i)
  until FindOperator(Code[i],11,1)>-1;
  inc(i);
  repeat 
    State:=0;
    b := FindOperator(Code[i],33,1);
    if b>-1 then State:=1;
    Case State of
      0:
        begin       
         S := Replace(Code[i],0,'=');
         S := Replace(S,32,'^');
        end;
      1:
      begin
        b := FindOperator(Code[i],23,1);      //(
        c := FindOperator(Code[i],6,1);      //,
        //S:= Copy(Code[i],b+1,c-b);
        S:='';
        if Code[i][b+1]='R' then CodeToPort(i,b+1,S)
                            else S:= Copy(Code[i],b+1,c-b-1);  
        S := '  '+S+' = ';   
        b := FindOperator(Code[i],24,1); 
        S:= S+Copy(Code[i],c+1,b-c-1)+';';
       // inc(i);
        //continue;
        //for j:=0 to High(ConstN)
          //if ConstN[i]=
      end
    end;
    AddTText(OutCode,S);
    inc(i)
  until FindOperator(Code[i],12,1)>-1;
end;

begin

end.

