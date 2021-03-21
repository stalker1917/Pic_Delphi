﻿unit Translator;
interface
uses  System.SysUtils,Tokens,Common;
type
 TConstI = Record
     S : String;
     N : Integer;
   End;
  TConstS = Record
     Sname,SValue : String;
   End;
var    
 Code,ConstN : Ttext;
 CommentN : Integer = -1;
 Errors  : TText;
 PasToken,CToken : TToken;
 ProcTokens  : TText;
 FullProcTokens  : TText;
function FindStrWithOperator(var Dump : TText; Number : TTokenKind; FirstStr:Integer = 0) : Integer;
function FindOperator(S:String; Number:TTokenKind; pos:Integer=1;LowerCaseFlag:Boolean=False) :Integer;
function FindString(S:String; StrToFind:String;pos:Integer) :Integer;
Procedure CompileConst(var OutCode:TText;Start:LongWord=0);
Procedure CompileVarType(var Code,OutCode:TText;IsType:Boolean=False;Start:LongWord=0);
Procedure CompileText(var OutCode:TText;FindStr:String;CodePos:Integer=-1);
Procedure AddTText(var T:TText; S:String);
function Replace(const S:String;N:TTokenKind;RepStr:String):String;
function ReplacePasToC(const S:String;N:TTokenKind):String;
Function SplitStrByToken(var S1,S2:String; Token: TTokenKind;Mode:Byte=0):Boolean;
function DeleteSpaceBars(S:String; Mode:Integer):String;// Удаляем пробелы
procedure StringToText(var OutCode:TText; S:String);
function TextToStr(var InCode:TText) :String;
Procedure ReplaceSemicolon(var OutCode:TText);

implementation


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

function FindString;
var i,High:Integer;
begin
  High := Length(s)-Length(StrToFind)+1;
  Result := -1;
  for I := pos to High do
    if (s[i]=StrToFind[1]) and (Copy(S,i,Length(StrToFind))=StrToFind) then
      begin
        Result := i;
        Break;
      end;
end;


function FindOperator;
//var i,High:Integer;
var StrToFind : String;
flag:Boolean;
begin
  if S='' then
  begin
   Result:=-1;
   exit;
  end;
  if LowerCaseFlag then S:=LowerCase(S);
  StrToFind := PasToken.GetToken(Number);
  repeat
  Result :=  FindString(S,StrToFind,pos);
  if (CommentN>-1) and (Result>=CommentN) then Result := -1;
  Flag := True;
  if Result>-1 then
    if (Number>=ANDTOK) and (Number<=XORTOK) and (Result>1)//(Number=ANDTOK) or (Number=XORTOK)  or (Number=ORTOK)  or (Number=NOTTOK)
     then
       begin
         flag := False;
         Pos := Result+1;
         case S[Result-1] of
          ' ': Flag := True;
          ')': Flag := True;
         end;
       end;
    if (Number=COLONTOK) and (S[Result+1]='=') then
      begin
        flag := False;
        Pos := Result+1;
      end;
    //if (Result>1) and (Number>ANDTOK) and (Number<XORTOK) and (S then

  until flag;
end;

function ToCycle(var S:String;N:Integer):Integer;
var i:Integer;
begin
   if N=-1 then
     begin
       result := -1;
       N      :=  1;
     end
   else result := Length(S)+1;
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
        result:=i; // Было i+1 ,чтобы пробел не считать.
        break;
      end;
end;


function DeleteSpaceBars(S:String; Mode:Integer):String;// Удаляем проблемы
var a,b:Integer;
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
         b := ToCycle(S,a)-1;
        end;
     2:      // ___Vasa_123__  ---->_123
       begin
         b := DownToCycle(S,-1);
         a := DownToCycle(S,b);
        end;
     else
       begin
         a := -1;
         b := -1;
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






function Replace(const S:String;N:TTokenKind;RepStr:String):String;
var
a,b,c : Integer;
begin
  a:=0;
  c:=1;
  result := S;
  while a>-1 do
    begin
      a := FindOperator(result,N,c);
      if N=EQTOK then //<= и >=
        begin
          c:=a+2;
          b:=FindOperator(result,GTTOK,c-3);
          if b=a-1 then continue;
          b:=FindOperator(result,LTTOK,c-3);
          if b=a-1 then continue;
        end;
      b := Length(PasToken.GetToken(N));
      if a>-1 then  result := Copy(result,1,a-1)+RepStr+Copy(result,a+b,Length(result)-a-b+1);
      c:=a+2;
      //else result := S;
    end;
end;

function ReplacePasToC(const S:String;N:TTokenKind):String;
begin
  result := Replace(S,N,CToken.GetToken(N));
end;

procedure CodeToPort(NString,Pos:Integer;EndTok:TTokenKind;Var S:String;Lat:Boolean=False);
var b,c:Integer;
S2:String;
begin
  if Lat then S2:='LAT'
         else S2:='PORT';
  S := S+S2;
  if Lat then S2:=S2+Code[NString][Pos+1]
         else S2:=Copy(Code[NString],Pos,2);
  S := S+ Code[NString][Pos+1]+'bits.'+S2;
  b := FindOperator(Code[NString],PLUSTOK,1);
  if b=-1 then S:=S+'0'
    else
      begin
        c := FindOperator(Code[NString],EndTok,1);
        S:= S + DeleteSpaceBars(Copy(Code[NString],b+1,c-b-1),1);
      end;
end;

procedure StringToText(var OutCode:TText; S:String);
var Sbuf:String;
Flag:Boolean;
begin
  //Replace(S,OPARTOK,'');
  SetLength(OutCode,0);
  repeat
    Sbuf :=  S;
    Flag := SplitStrByToken(Sbuf,S,SEMICOLONTOK,1);  //Посмотреть куда попадает ;
    AddTText(Outcode,Sbuf);
  until (not Flag) or (S='');
end;

function TextToStr(var InCode:TText) :String;
var i:Integer;
begin
  result := '';
  for I := 0 to High(InCode) do result:=result+Incode[i];
end;

Procedure ReplaceSemicolon;
var i:Integer;
begin
  for I := 0 to High(OutCode) do
    if i=High(OutCode) then OutCode[i] := Replace(OutCode[i],SEMICOLONTOK,'')
                       else OutCode[i] := Replace(OutCode[i],SEMICOLONTOK,',')


end;


//--------Main Code----
Function FalseFound(Start:Integer;PosCh:Integer):Boolean;
var i:Integer;
begin
  if (Start>0) then
    begin
      i := FindStrWithOperator(Code,BEGINTOK,Start)+1;
      result := i<PosCh;
    end
  else result := False;
end;

Procedure CompileConst;
var a,b,c,i,j:Integer;
S,S1:String;
begin
  i:=FindStrWithOperator(Code,CONSTTOK,Start)+1;
  if i=-1 then exit;
  if FalseFound(Start,i) then exit;
  SetLength(ConstN,0);
  j:=0;
  while FindOperator(Code[i],EQTOK,1) >-1 do
    begin
      inc(j);
      a := FindOperator(Code[i],EQTOK,1); //
      S:= Copy(Code[i],1,a-1);
      AddTText(ConstN,DeleteSpaceBars(S,1)); //Запоминаем название константы.
      S := '#define '+S+' ';
      //USERSTR1 :='R';
      b := FindString(Code[i],'R',a);
      if b>-1 then
      begin
        //S1:=S+'_LAT ';
        S1 := '#define ' + ConstN[High(ConstN)]+'_LAT ';
        CodeToPort(i,b,SEMICOLONTOK,S);
        CodeToPort(i,b,SEMICOLONTOK,S1,True);
        AddTText(OutCode,S1);
      end
      else
        begin
          b :=  FindOperator(Code[i],SEMICOLONTOK,1);
          S :=  S + Copy(Code[i],a+1,b-a-1);
          //S := S + IntToStr(StrToInt(Copy(Code[i],b+1,c-b-1)));
        end;
      AddTText(OutCode,S);
      inc(i);
    end;
end;

Procedure CompileVarString(var S1:String;var recflag:Byte;Var unionflag : Boolean; var recbuf : String);
var
a,b,c:Integer;
j : TTokenKind;
S,S2,S3,S4:String;
begin
      S2:='';
      S3:='';
      if (FindOperator(S1,ENDTOK)>-1) and ( Recflag>0) then
        begin
          S1 :='} '+recbuf+';';
          //AddTText(OutCode,'} '+recbuf+';');
          //inc(i);
          Recflag := 0;
          recbuf := '';
          unionflag := False;
          exit;
        end;

      if Unionflag then
        begin
          S4 := S1;
          if FindOperator(S4,COLONTOK,1)=-1 then  AddTText(Errors,'Ошибка! Каждый элемент вариантной записи может содержать только одну переменную!');
          SplitStrByToken(S4,S,OPARTOK);
          S4 := Copy(S,2,Length(S)-1);
        end
      else S4 := S1;

      for j:= EMPTYTYPE to RECTYPE do
       begin
        //USERSTR1 := GetTypeSpelling(i);  //Разобраться
        if  FindOperator(S4,j,1,True)>-1 then  //Понижаем регистр
          begin
             S := S4;
             SplitStrByToken(S,S3,EQTOK);
             //S3 := LowerCase(S3); // Типы в нижнем регистре.
              case j of
                 STRINGTYPE: //STRINGTYPE
                   begin
                     S := 'char';
                     a := FindOperator(S4,OBRACKETTOK,1);
                     if a=-1 then S2:='[32]'
                     else
                       begin
                         b := FindOperator(S1,CBRACKETTOK,a);
                         S2 := Copy(S4,a,b-a+1);
                       end;
                     S3:=ReplacePasToC(S3,QUOTETOK);
                   end;
                 RECTYPE:
                  begin
                    recflag := 2;
                    //if FindOperator({Code[i+1]}S1,CASETOK)>-1 then
                     // begin
                     //   S := 'union';
                      //  unionFlag := True;
                     // end
                    S := CToken.GetToken(j);
                    S3:=' ';
                  end
                 else
                   begin
                     S := CToken.GetToken(j);
                     S3:=ReplacePasToC(S3,DOLLARTOK);
                   end;
              end;
              if S3='' then  S3:=';';
              if (FindOperator(S4,ARRAYTYPE,1)>-1) then  //Массив
                begin
                  a :=FindOperator(S4,RANGETOK,1);
                  b :=FindOperator(S4,CBRACKETTOK,a);
                  c :=FindOperator(S4,COMMATOK,a);
                  S3 := '[';
                  while (c<b) and (c>-1) do
                    begin
                     S3:=S3+Copy(S4,a+2,c-a-2)+'+1][';
                     a:=FindOperator(S4,RANGETOK,c);
                     if a=-1 then a:=c+1;
                     c :=FindOperator(S4,COMMATOK,a);
                    end;
                  S3:=S3+Copy(S4,a+2,b-a-2)+'+1];';
                end;
              a := FindOperator(S4,COLONTOK,1);
              a := FindOperator(S4,j,a,True); //Надо по СolonTok!
              //Ecли не запись , иначе по другому.
              if recflag<2 then S:=S+' '+DeleteSpaceBars(Copy(S4,1,a),1)+S2+S3//+';';
                           else Recbuf := DeleteSpaceBars(Copy(S4,1,a),1);
              //AddTText(OutCode,S);
              S1:=S;
              exit;
          end
       end;
       if unionflag then  SplitStrByToken(S4,S,CPARTOK);
       SplitStrByToken(S4,S3,COLONTOK);
       S3[1]:=' ';
       S3[Length(S3)]:=' ';
       S1:=S3+S4+';';
end;

Procedure CompileVarType;
var i:Integer;
S:String;
recflag : Byte;
unionflag : Boolean;
recbuf : String;
HeadTok :TTokenKind;
QuasiColonTok :TTokenKind;
begin
  if IsType then
    begin
      HeadTok := TYPETOK;
      QuasiColonTok :=  EQTOK;
    end
  else
    begin
      HeadTok := VARTOK;
      QuasiColonTok := COLONTOK;
    end;

  i:=FindStrWithOperator(Code,HeadTok,Start)+1;  //var
  if i=-1 then exit;
  if FalseFound(Start,i) then exit;
  recflag := 0;
  unionflag :=False;
  recbuf := '';
  while (FindOperator(Code[i],QuasiColonTok,1) >-1) or (recflag>0) do  //:
    begin
      S := Code[i];
      CompileVarString(S,recflag,unionflag,recbuf);
      if (recflag=2) and (FindOperator(Code[i+1],CASETOK)>-1) then
        begin
          AddTText(OutCode,'union');
          unionFlag := True;
        end
      else
        if (RecFlag<>1) and IsType and (S[1]<>'}') then AddTText(OutCode,'typedef '+S)
        else AddTText(OutCode,S);
      if recflag=2 then
        begin
          dec(recflag);
          AddTText(OutCode,'{');
          if unionFlag then inc(i);
        end;
      inc(i);
    end;
end;

procedure DecodeParams(const S_in:String;var S_out :TText);
var a,b,c : Integer;
begin
  SetLength(S_out,0);
  a := FindOperator(S_in,OPARTOK,1);
  if a<0 then exit;
  b := FindOperator(S_in,CPARTOK,a);
  if (b<0) or (b=a+1) then exit;   //fun()
  repeat
    c := FindOperator(S_in,COMMATOK,a+1);
    if c<0 then c:=b;
    AddTText(S_out,Copy(S_in,a+1,c-a-1));
    a := c;
  until (c>=b);
end;
//Вычленяем параметры функции

Function CheckLength(A:TText;N:Integer;S:String):Boolean;
begin
  result := Length(A)<>N;
  if result then AddTText(Errors,'Ошибка! Встроенная функция'+ S+'требует '+IntToStr(N)+' параметров');

end;

function LengthTok(A:TTokenKind):Byte;
begin
  result :=  Length(PasToken.GetToken(A));
end;




// if i=1 then j:=2
// i=1
// j:=2
procedure DecodeTok(const Arr:TArray<TTokenKind>;const S_in:String; var  S_out :TText);
var i,a,b:Integer;
begin
  SetLength(S_out,Length(Arr));
  a := FindOperator(S_in,Arr[0],1);
  if a<0 then exit;
  i:=0;
  while i<High(Arr) do
    begin
      a := a+LengthTok(Arr[i]);
      b := FindOperator(S_in,Arr[i+1],a+1);
      S_out[i] := Copy(S_in,a,b-a);
      a := b;
      inc(i);
    end;
  a := a+LengthTok(Arr[i]);
  S_out[High(Arr)] := Copy(S_in,a,High(S_in)-a+1);
end;

Function SplitStrByToken;
var Position:Integer;
begin
 Result:=True;
 S2 :='';
 Position := FindOperator(S1,Token,1);
  if Position>-1 then
    begin
      if Mode=1 then inc(Position);
      S2:=Copy(S1,Position,Length(S1)-Position+1);
      if Position=1 then Result:=False
                    else S1:=Copy(S1,1,Position-1);
    end;
end;



Procedure ReplaceAll(var S:String;Logical:Boolean=False);
var //Comment : Integer;
a,b:Integer;
S1,S2:String;
begin
  S2:='';
  if (not SplitStrByToken(S,S2,COMMENTTOK)) then exit;
  if Logical then
    begin
      S := Replace(S,EQTOK,'==');
      S := Replace(S,ORTOK,'||');
      S := Replace(S,ANDTOK,'&&');
    end
  else
    begin
      S := Replace(S,ASSIGNTOK,'=');  //Переписать в полную замену.
      S := Replace(S,XORTOK,'^');
      S := Replace(S,ORTOK,'|');
      S := Replace(S,ANDTOK,'&');
    end;
  S := ReplacePasToC(S,DOLLARTOK);
  S := ReplacePasToC(S,SHLTOK);
  S := ReplacePasToC(S,SHRTOK);
  S := ReplacePasToC(S,IDIVTOK);
  S := ReplacePasToC(S,MODTOK);
  S := Replace(S,NETOK,'!=')+S2;
  SplitStrByToken(S,S2,OBRACKETTOK);
  while S2<>'' do
    begin
      SplitStrByToken(S2,S1,CBRACKETTOK);
      S := S+Replace(S2,COMMATOK,'][');
      SplitStrByToken(S1,S2,OBRACKETTOK);
      S := S+S1;
    end;
  //S := Replace(S,COMMATOK,'][');
end;

Procedure SetState(i:Integer; Tok:TTokenKind;Var State :TTokenKind );
var b:Integer;
begin
   b := FindOperator(Code[i],Tok,1);    //SetBit
   if b>-1 then State := Tok;
end;

Function SetTabs(N:Integer):String;
var j:Integer;
begin
   Result := '';
   for j := 1 to N do Result:=Result+'  ';
end;

procedure CompileText;
var a,b,c,i,j:Integer;
Tok:TTokenKind;
TokArr : TArray<TTokenKind>;
State:TTokenKind;
Begins:Integer;
S,S2:String;
Params : TText;
FirstCase : Boolean;
//IfTokOpen : Byte;
CaseHeap : TArray<Word>;
begin
  if CodePos=-1 then
    begin
      //SetLength(Errors,0);
      Begins:=0;
      FirstCase := True;
      CaseHeap := TArray<Word>.Create();
      a := FindStrWithOperator(Code,IMPLEMENTATIONTOK);
      if a=-1 then
        begin
          AddTText(Errors,'Ошибка! Нет секции implementation!');
          exit;
        end;
        //Operators[High(Operators)] := FindStr;
      USERSTR1 := FindStr;
      a := FindStrWithOperator(Code,USERTOK1,a);
    end
  else a := CodePos;
  if a=-1 then
    begin
      AddTText(Errors,'Ошибка! Отсутствует функция '+FindStr);
      exit;
    end;
  i:=a;
  repeat
    inc(i)
  until FindOperator(Code[i],BEGINTOK,1)>-1;
  inc(i);
  repeat
    CommentN := -1;
    CommentN := FindOperator(Code[i],COMMENTTOK,1);
   // if CommentN>-1 then
    //  j:=1;
    if Code[i]='' then
      begin
        inc(i);
        continue;
      end;

    State:=EMPTYTOK;
    for Tok := SETBITTOK to DECTOK do  SetState(i,Tok,State);
    SetState(i,RESULTTOK,State);
    SetState(i,ELSETOK,State);  //Самый низкий приоритет
    SetState(i,COLONTOK,State); //Видиом надо ставить выше, чтобы if отрабатывало
    SetState(i,BEGINTOK,State);
    SetState(i,IFTOK,State);
    SetState(i,CASETOK,State);
    SetState(i,ENDTOK,State);
    SetState(i,FORTOK,State);


    DecodeParams(Code[i],Params);
    Case State of
      SETBITTOK:
      begin
        if CheckLength(Params,2,'SetBit') then exit;
        S:='';
        if Params[0][1]='R' then
          begin
             b := FindString(Code[i],Params[0],1);
             CodeToPort(i,b,COMMATOK,S,True);
          end
        else S:= Params[0]+'_LAT';
        S := SetTabs(begins+1)+S+' = ';
        S:= S+Params[1]+';';
      end;
      GETBITTOK:
      begin
        if CheckLength(Params,2,'GetBit') then exit;
        S:='';
        if Params[0][1]='R' then
          begin
             b := FindString(Code[i],Params[0],1);
             CodeToPort(i,b,COMMATOK,S);
          end
        else S:= Params[0];
        S := SetTabs(begins+1)+Params[1]+' = '+S+';';
      end;
     FASTTXTOK:
       begin
         if CheckLength(Params,2,'FASTTX') then exit;
          case CPU of
            PIC18F4520:
              begin
                AddTText(OutCode,'while (!TXSTAbits.TRMT);');
                S:=SetTabs(begins+1)+'TXREG = '+ReplacePasToC(Params[1],DOLLARTOK)+';';
              end;
            PIC32MZ64..PIC32MZ144:
             if Params[0]='255' then
               begin
                 AddTText(OutCode,'while (!STABits->TRMT);');
                 S:=SetTabs(begins+1)+'*TXREG = '+ReplacePasToC(Params[1],DOLLARTOK)+';';
               end
             else
               begin
                 S:='U'+IntToStr(StrToInt(Params[0])+1);
                 AddTText(OutCode,'while (!'+S+'STAbits.TRMT);');
                 S:=SetTabs(begins+1)+S+'TXREG = '+ReplacePasToC(Params[1],DOLLARTOK)+';';
               end;
          end;

       end;
     FASTRXTOK:
       begin
         if CheckLength(Params,2,'FASTRX') then exit;
         S := SetTabs(begins+1)+Params[1]+' = RX_'+Params[0]+';';
       end;
     NOPTOK:
        S:=SetTabs(begins+1)+'Nop();';
     INCTOK:
       begin
         if CheckLength(Params,1,'inc') then exit;
         S := SetTabs(begins+1)+Params[0]+'++;';
       end;
     DECTOK:
       begin
         if CheckLength(Params,1,'dext') then exit;
         S := SetTabs(begins+1)+Params[0]+'--;';
       end;
     RESULTTOK:
       begin
         S := ReplacePasToC(Code[i],RESULTTOK); //Result в return. Надо чтобы в другой строчке , не где if
         S := Replace(S,ASSIGNTOK,'');
         ReplaceAll(S);
       end;
     IFTOK:
       begin
         TokArr:= TArray<TTokenKind>.Create(IFTOK,THENTOK);
         DecodeTok(TokArr,Code[i],Params);
         ReplaceAll(Params[0],True);
         ReplaceAll(Params[1]);
         S := SetTabs(begins+1)+'if ('+Params[0]+') '+Params[1];
         if FindOperator(Code[i+1],ELSETOK,1)>-1 then S:=S+';';

         //TokArr.Free;
       end;
     CASETOK:
       begin
         TokArr:= TArray<TTokenKind>.Create(CASETOK,OFTOK);
         DecodeTok(TokArr,Code[i],Params);
         ReplaceAll(Params[0],True);
         S := SetTabs(begins+1)+'switch ('+Params[0]+') {';
         FirstCase := True;
         TArrHack<Word>.Append(CaseHeap,Begins);
         //<Word>
       end;
     FORTOK:
       begin
         TokArr:= TArray<TTokenKind>.Create(FORTOK,ASSIGNTOK,TOTOK,DOTOK);
         DecodeTok(TokArr,Code[i],Params);
         ReplaceAll(Params[3],false);
         Params[0] := DeleteSpaceBars(Params[0],0);
         S := SetTabs(begins+1)+'for ('+Params[0]+' ='+Params[1]+';'+Params[0]+' <='+Params[2]+';'+Params[0]+'++)'+Params[3];
       end;
     BEGINTOK:
       begin
         inc(begins);
         S:=SetTabs(begins);
         //for j := 1 to begins*2 do S:=S+' ';
         S := S+CToken.GetToken(BEGINTOK);
       end;
     ENDTOK:
       begin
         S:=SetTabs(begins);
         //for j := 1 to begins*2 do S:=S+' ';
         S := S+CToken.GetToken(ENDTOK);
         if (Length(CaseHeap)>0) and (TArrHack<Word>.GetHigh(CaseHeap)>=Begins) then
          begin
            TArrHack<Word>.DeleteHigh(CaseHeap);
            FirstCase := (length(CaseHeap)=0);
          end
         else dec(begins);
       end;
     COLONTOK: if (length(CaseHeap)>0) then  //Если не было case то так не транслируем.
       begin
         if Firstcase then FirstCase:=False
                      else AddTText(OutCode,SetTabs(begins+1)+'break;');
         S := Code[i];
         SplitStrByToken(S,S2,COLONTOK);
         S := DeleteSpaceBars(S,2);
         S := ReplacePasToC(S,DOLLARTOK);
         ReplaceAll(S2);
         S:= SetTabs(begins+1)+' case '+S+S2;
       end
       else;
     ELSETOK: if (length(CaseHeap)>0) and (FindOperator(Code[i-1],SEMICOLONTOK)>-1) then  //Если не было case то так не транслируем.
       begin
         if Firstcase then FirstCase:=False
                      else AddTText(OutCode,SetTabs(begins+1)+'break;');
         S := Code[i];
         S := ReplacePasToC(S,ELSETOK);
         //ReplaceStr(
       end
       else
         begin
           S := Code[i];
           ReplaceAll(S);
         end
      else
        begin
          S:=Code[i];
          ReplaceAll(S);
        end;
    end;
    for j := 0 to High(ProcTokens) do
      begin
        a := FindString(S,ProcTokens[j],1);
        if a>-1 then
          begin
            if S[a+Length(ProcTokens[j])]<>'(' then  AddTText(Errors,'Ошибка! Надо вызывать процедуру как '+ProcTokens[j]+'(), а не '+ProcTokens[j]);
            break;
          end;
      end;



    AddTText(OutCode,S);
    S := '';
    inc(i)
  until (FindOperator(Code[i],ENDTOK,1)>-1) and (Begins=0) and (Length(CaseHeap)=0);  //Последняя end не обрабатывается
  CommentN := -1;
end;

begin

end.

