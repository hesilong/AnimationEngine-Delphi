unit NewScript;

interface

uses
    Windows, Messages, VCL.Graphics, SysUtils, Classes, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs,
    FMX.StdCtrls, Math, MMSystem, WinInet, UITypes;


type
  TGetValue = procedure(inStr : String; Var OutStr : String; Var OType : Byte) of Object;
  TSetValue = procedure(inStr : String; Var OutStr : String) of Object;
  T_isVar = Function(inStr : String) : Boolean of Object;
  T_isFunction = Function(inStr : String) : Boolean of Object;
  TShowString = procedure (Msg : String) of Object;
  TOutFunctionCall = Function(Str1,Str2 : String) : String of Object;
  TLoadStream = Procedure(inStr : String; Var DataStored : TMemoryStream; stype : Byte) of Object;
  TPlaySound = Procedure(inStr : String) of Object;

Const
 QuotaChar = '"';

type
  TItem = record
   Name : string;
   Content : String;
   is_routine : boolean;
   value : string;
  end;

  StatusPoints = record
   sType : Byte;
   Pos   : integer;
  end;

  TPSource = record
   sName : String;
   sSource : String;
  end;

  ExecPoint = record
   Command : Byte;  //0 : normal assign, that means assign right to left...
                    //1 : condition, if right is true goto c1, if false goto c2...
                    //2 : Null point, such as repeat cause it...
                    //3 : routine call such as movie5.startaction, etc...
                    //4 : jump, jump to c1 directly, the if then else can cause it...
   C1,C2 : integer;
   left : string;
   right : String;
  end;

  TVar = record
   Name : String;
   Value : String;
   IntArray : Array of integer;
   RealArray : Array of Real;
   StrArray : Array of String;
   DLength : integer;
   Dimension : Byte;
   DimensionCount : String;
//   StrList : TStringList;
   sType : Byte; //0 : Boolean; 1 : string; 2 : integer; 3 : real;
                 //4 : Array of integer; 5 : array of real; 6: array of string;
                 //7 : TStringlist;
  end;

  TObj = record
   Name : String;
   stype : Byte;
   Data : Pointer;
  end;

type

  TExp = class
   private
    Content : String;
    Items   : word;
    Ops     : word;
    ItemsArray   : Array of TItem;
    FOnGetValue : TGetValue;
    FOnFunctionCall : TOutFunctionCall;
    procedure BuildItemArray(Var Inputstr : String);
    procedure CalculateItem;
    Function GetItemValue(inStr : String; Var sType : Byte) : String;
    Function FunctionResult(inStr1,inStr2 : String) : String;
    Function Calc(inStr : String) : String;
   public
    Constructor create;
    destructor destroy; override;
    procedure setContent(inStr : String);
    Function GetResult : String;
    Procedure CalcSubIndex(inStr : String);
    Function SmartString(inStr : String) : String;
   published
    property OnGetValue : TGetValue read FOnGetValue write FOnGetValue;
    property OnFunctionCall : TOutFunctionCall read FOnFunctionCall write FOnFunctionCall;
   end;

  TStatusStack = class
   private
    StatusCount : integer;
    Count : integer;
    StatusList : Array of StatusPoints;
   Public
    _isControl : byte;
    Constructor create;
    destructor destroy; override;
    procedure Push(stype : Byte; sPos : integer);
    procedure Pop(Var stype : Byte; Var sPos : integer);
    function _isEmpty : Boolean;
  end;

  TVars = class
   private
    VarsCount : integer;
    VarList : Array of TVar;
    FOnLoadStream : TLoadStream;
   public
    Constructor create;
    destructor destroy; override;
    procedure DefineVar(inStr : String; stype : Byte);
    procedure LoadFromFile(inStr, filename : String; Var stype : Byte);
    procedure SaveTOFile(inStr, filename : String; Var stype : Byte);
    procedure ExtraLoadFromFile(inStr, filename : String; Var stype : Byte);
    procedure ExtraSaveToFile(inStr, filename : String; Var stype : Byte);
    procedure sysLoadStrings(inStr,filename : String; Var stype : Byte);
    procedure sysSaveStrings(inStr,filename : String; Var stype : Byte);
    procedure sysLoadFile(inStr : String; Var stype : Byte);
    procedure sysSaveFile(inStr : String; Var stype : Byte);
    function GetValue(inStr : String; Var stype : Byte) : String;
    procedure SetValue(inStr : String; iValue : String; Var uType : Byte);
    function _isVar(inStr : String) : Boolean;
    function EmunVar(index : integer; Var vName : String) : integer;
    function VarOut(index : integer) : TVar;
    function ArrayX(inStr : String): integer;
    function ArrayY(inStr : String): integer;
    procedure AddVar(inVar : TVar);
   Published
    property OnLoadStream : TLoadStream read FOnLoadStream write FOnLoadStream;
  end;

{  TObjs = class
   private
    ObjsCount : integer;
    ObjsList : Array of TObj;
   public
    Constructor create;
    destructor destroy; override;
    procedure DefineObj(inStr : String; stype);
   end;}

Type
 TScript = class
  private
   selfVar : TVars;
   indexVar : TVars;
   Gindex : TVars;
   selfExp : TExp;
   selfStack : TStatusStack;
   VarIndex : String;
   feedIn  : string;
   FOnShowString : TShowString;
   PointNumber : integer;
   ScriptName : String;
   ScriptType : Byte; //0 .. main program; 1 .. procedure; 20 .. function of boolean;
                      //21 .. function of integer; 22 .. function of real;
                      //23 .. function of string;
   //CurrentPos : integer;
   //CurrentState : integer;

   ExecStream : Array of ExecPoint;
   FOutSideVar : TGetValue;
   FOnSetValue : TSetValue;
   TOn_isVar : T_isVar;
   TOn_isFunction : T_isFunction;
   FOnFunctionCall : TOutFunctionCall;
   FOnLoadStream : TLoadStream;
   FOnPlaySound : TPlaySound;

   procedure compile;
   procedure TreateVarBlock(inStr : String);
   procedure RequestValue(inStr : String; Var OutStr : String; Var OType : Byte);
   function FunctionCall(inStr : String) : Boolean;
  public
   ReturnResult : String;
   Constructor create;
   destructor destroy; override;
   procedure setfeedIn(inStr : String);
   procedure compile_2;
   procedure Run;
   procedure SaveToFile(FileName : String);
   Function GetFeedIn : String;
   Procedure Replace_ExecStream(oStr,rStr : String);
   Function ScriptL(Var sName, vIndex : string; Var scType : Byte) : integer;
   Function OutExecPoint(index : integer) : ExecPoint;
   Procedure AddExecPoint(inExecPoint : ExecPoint);
  Published
   Property OnShowString : TShowString Read FOnShowString Write FOnShowString;
   Property OnOutSideVar : TGetValue Read FOutSideVar Write FOutSideVar;
   property OnSetValue : TSetValue Read FOnSetValue Write FOnSetValue;
   property On_isVar : T_isVar read TOn_isVar write TOn_isVar;
   property On_isFunction : T_isFunction read TOn_isFunction write TOn_isFunction;
   property OnFunctionCall : TOutFunctionCall read FOnFunctionCall write FOnFunctionCall;
   property OnLoadStream : TLoadStream read FOnLoadStream write FOnLoadStream;
   property OnPlaySound : TPlaySound read FOnPlaySound write FOnPlaySound;
  end;

Type
 TProgramBody = class
  private
   GVars : TVars;
   MainScript : TScript;
   F_and_P    : Array of TScript;
   Event_Source : Array of TScript;
   ESCount : integer;
   RunningScript : TScript;
   FPCount : integer;
   FOnShowString : TShowString;
   FOnFunctionCall : TOutFunctionCall;
   FOnSetValue : TSetValue;
   FOnGetValue : TGetValue;
   FOnLoadStream : TLoadStream;
   FOnPlaySound : TPlaySound;
   Procedure GetOutVar(inStr : String; Var OutStr : String; Var OType : Byte);
   Function _isVar(inStr : String) : Boolean;
   Function _isFunction(inStr : String) : Boolean;
   Procedure SetOutVar(inStr : String; Var OutStr : String);


  public
   compiled : Boolean;
   Running : Boolean;
   Constructor create;
   destructor destroy; override;
   Procedure setMain(inStr : string);
   Procedure setFP(inStr : String);
   procedure setEvent(inStr : String);
   procedure RunEvent(inName : String);
   procedure RuntmpEvent(inStr : String);
   Procedure Compile;
   Procedure Run;
   procedure defineVar(inStr : String; oType : Byte);
   procedure setVarValue(inStr : String; iValue : String);
   Function GetVarValue(inStr : String; Var oType : Byte) : String;
   Procedure FP_Filter(Var inStr : String);
   Function FunctionCall(str1,str2 : String) : string;
  Published
   Property OnShowString : TShowString Read FOnShowString Write FOnShowString;
   property OnFunctionCall : TOutFunctionCall read FOnFunctionCall write FOnFunctionCall;
   property OnSetValue : TSetValue read FOnSetValue write FOnSetValue;
   property OnGetValue : TGetValue read FOnGetValue write FOnGetValue;
   property OnLoadStream : TLoadStream read FOnLoadStream write FOnLoadStream;
   property OnPlaySound : TPlaySound read FOnPlaySound write FOnPlaySound;
 end;


{Function GetWord(Var inStr : string) : String;
Function GetOperator(Var inStr : String) : String;
Function GetInclude(Var inStr : String; Var is_routine : Boolean; re_str : string) : String;
Function GetCStr(Var inStr : String; re_Str : String) : String;
Function cExp(inStr : String) : String;

Function GetHeadString(Var inStr : String; Seperator : Char) : string;
}

implementation

   function CheckOffline(address : string) : boolean;
     var
      ConnectState: DWORD;
      StateSize: DWORD;
      s : string;
     begin
      ConnectState:= 0;
      StateSize:= SizeOf(ConnectState);
      s := 'http://'+address+ '/';
      result:= false;
      if InternetQueryOption(nil, INTERNET_OPTION_CONNECTED_STATE, @ConnectState, StateSize) then
       if (ConnectState and INTERNET_STATE_DISCONNECTED) <> 2 then
        begin
         if InternetCheckConnection(@s[1], 1, 0) then
          result:= true;
        end;
     end;

Function GetDirString(PathName : String) : string;      //Pathname ´øÐ±¸Ü
 var
 sr : TSearchRec;
 FileAttrs : Integer;
 jj : integer;
 str : string;
 tmp : TStringList;
begin
    result := '';
    Tmp := TStringList.Create;
    str := PathName;
    if str= '' then exit;
    FileAttrs :=  fadirectory;
    if FindFirst(str+'*.*', FileAttrs, sr) = 0 then
      begin
       if (sr.Attr and FileAttrs) = sr.Attr then
       begin
        if (sr.Name <> '.') and (sr.Name <> '..') then
        begin
         tmp.Add( sr.name);
        end;
       end;
       while FindNext(sr) = 0 do
        begin
         if (sr.Attr and FileAttrs) = sr.Attr then
          begin
           if (sr.Name <> '.') and (sr.Name <> '..') then
            begin
             tmp.Add(sr.name);
            end;
          end;
        end;
       FindClose(sr);
      end;
    if tmp.Count = 0 then exit;
    str := '';
    for jj := 0 to tmp.Count - 1 do
     begin
      str := str + tmp.Strings[jj] + '|';
     end;
    result := str;
    tmp.free;
end;

Function GetHeadString(Var inStr : String; Seperator : Char) : string;
 var
  tempstr : String;
  i,j,k: integer;
  u : String;
 begin
//  inStr := trim(inStr);
  if inStr = '' then
   begin
    result := '';
    exit;
   end;
  j := Pos(Seperator,inStr);
  if j = 0 then
   begin
    result := inStr;
    inStr := '';
    exit;
   end;

  i := Pos(QuotaChar,inStr);
  if (i = 0) or (i >= j) then
   begin
    tempstr := copy(inStr,1,j-1);
    delete(inStr,1,j);
    result := tempstr;
    exit;
   end;

  inStr[i] := 'A';
  k := Pos(QuotaChar,inStr);
  inStr[i] := QuotaChar;
  if (k =0) or (k <= j) then
   begin
    tempstr := copy(inStr,1,j-1);
    delete(inStr,1,j);
    result := tempstr;
    exit;
   end;

  if (j > i) and (j < k) then
   begin
    u := copy(inStr,1,k);
    delete(inStr,1,k);
    result := u + GetHeadString(inStr,Seperator);
   end;

 end;

Function StringToDoubleLength(inStr : String) : String;
 Var
  i : integer;
  j : byte;
  s : String;
  c : Char;
 begin
  Randomize;
  if inStr = '' then begin result := ''; exit; end;
  s := '';
  for i := 1 to length(inStr) do
   begin
    c := inStr[i];
    repeat
     j := random(255);
    until j >= 128;
    s := s + Chr(j)+c;
   end;
  result := s;
 end;

Function DoubleLengthToString(inStr : String) : String;
 Var
  s : string;
  c1,c2 : Char;
 begin
  if inStr = '' then begin result := ''; exit; end;
  if ((length(inStr) mod 2) <> 0) then begin result := ''; exit; end;
  s := '';
  repeat
   c1 := inStr[1];
   c2 := inStr[2];
   //j :=  ord(c1)*16 + ord(c2);
   //j := j - 255;
   s := s + c2;
   delete(inStr,1,2);
  until inStr = '';
  result := s;
 end;

Function GetRandomString(theNumber : integer) : string;
 Var
  TmpArray,IniArray,ResArray : Array of Integer;
  OldNumber : integer;
  i,j : integer;
  s : string;
 begin
  Randomize;
  SetLength(IniArray,theNumber);
  SetLength(ResArray,theNumber);
  SetLength(tmpArray,theNumber);
  for i := 1 to theNumber do
   begin
    IniArray[i-1] := i;
    tmpArray[i-1] := i;
   end;

  OldNumber := theNumber;

  while theNumber > 1 do
   begin
    j := RandomFrom(tmpArray);
    ResArray[OldNumber-theNumber] := j;
    IniArray[j-1] := 0;
    tmpArray := Nil;
    theNumber := theNumber - 1;
    SetLength(tmpArray,theNumber);
    j := 0;
    for i := 1 to OldNumber do
     begin
      if IniArray[i-1] = 0 then begin end else
      begin
       tmpArray[j] := IniArray[i-1];
       inc(j);
      end;
     end;
   end;
  j := tmpArray[0];
  ResArray[OldNumber-1] := j;
  s := '';
  for i := 1 to OldNumber do
   begin
    s := s + IntToStr(ResArray[i-1]) + ';';
   end;
  IniArray := Nil;
  tmpArray := Nil;
  ResArray := Nil;
  result := s;
 end;

Function SelfEncode(inStr : String) : String;
 Var
  i : integer;
  c1 : char;
  t1,t2 : integer;
  s1,s2,s3 : string;
 begin
  result := '';
  Randomize;
  if inStr = '' then exit;
  s3 := '';
  for i := 1 to Length(inStr) do
   begin
    c1 := inStr[i];
    t1 := ord(c1);
    t1 := t1 * 38;
    s1 := IntToHEX(t1,0);
    if length(s1) < 3 then
     begin
      t2 := 200 + Random(55);
      s2 := IntTOHEX(t2,0);
     end else
    if length(s1) = 3 then
      s2 := '0' else
      s2 := '';
    s1 := s2 + s1;
    s3 := s3 + s1;
   end;
  result := s3;
 end;

Function SelfDecode(inStr : String) : String;
 Var
  i : integer;
  c1 : Char;
  s1,s2,s3 : string;
  t1 : integer;
 begin
  result := '';
  if inStr = '' then exit;
  s3 := '';
  while inStr <> '' do
   begin
    s1 := Copy(inStr,1,4);
    delete(inStr,1,4);
    if s1[1] = '0' then
     begin
      s1 := '$' + s1;
      t1 := StrToInt(s1);
      t1 := t1 div 38;
      c1 := Chr(t1);
     end else
    if (Uppercase(s1[1]) = 'C') or
       (Uppercase(s1[1]) = 'D') or
       (Uppercase(s1[1]) = 'E') or
       (Uppercase(s1[1]) = 'F') then
     begin
      delete(s1,1,2);
      s1 := '$' + s1;
      t1 := StrToInt(s1);
      t1 := t1 div 38;
      c1 := Chr(t1);
     end else
     begin
      s1 := '$' + s1;
      t1 := StrToInt(s1);
      t1 := t1 div 38;
      c1 := Chr(t1);
     end;
    s3 := s3 + c1;
   end;
  result := s3;
 end;
  
Function myPos(subStr : String; inStr : String) : integer;
Var
 i,j,k : integer;
 l : integer;
 m : integer;
begin
 if substr = QuotaChar then
  begin
   result := Pos(substr,instr);
   exit;
  end;
 i := Pos(QuotaChar,inStr);
 if i = 0 then
  begin
   result := Pos(substr,instr);
   exit;
  end;
 inStr[i] := 'A';
 k := Pos(QuotaChar,inStr);
 j := Pos(subStr,inStr);
 if j < i then
  begin
   result := Pos(substr,instr);
   exit;
  end;
 l := k;
 delete(inStr,1,k);
 m := myPos(substr,inStr);
 if m = 0 then result := 0 else
 result := l + m;
end;

Function isInteger(inStr : String) : Byte;
Var
 i : integer;
 ok : Boolean;
 ch : Char;
begin
 result := 0;
 inStr := trim(inStr);
 if inStr = '' then exit;
 if (inStr[1] = '-') or (inStr[1] = '+') then delete(inStr,1,1);
 inStr := trim(inStr);
 if inStr = '' then exit;
 for i := 1 to Length(inStr) do
  begin
   ch := inStr[i];
   ok := (ch in ['0'..'9']);
   if not ok then exit;
  end;
 result := 1;
end;

Function isLongDate(inStr : String) : Byte;
Var
 i : integer;
 s1,s2 : string;
begin
 result := 0;
 if isInteger(inStr) <> 1 then exit;
 if Length(inStr) <> 8 then exit;
 result := 1;
end;

Function IntToTime(inI : integer) : String;
Var
  s1,s2,s3 : string;
  i,j,k   : integer;
begin
 i := floor( inI / 3600);
 j := inI Mod 3600;
 k := floor(j / 60);
 j := inI - i * 3600 - k * 60;
 if j < 0 then j := 0;
 s1 := IntToStr(i);
 s2 := IntToStr(k);
 if length(s2) < 2 then s2 := '0' + s2;
 s3 := IntToStr(j);
 if length(s3) < 2 then s3 := '0' + s3;
 result := s1 + ':' + s2 + ':' + s3;
end;

function PointInPoly(APoint : TPoint ; APoly : array of TPoint) : boolean;
Var
  i, j : integer;
  npol : integer;
begin
  Result := false;
  npol := length(APoly);
  for i := 0 to npol - 1 do begin
    j := (i + 1) mod npol;
    if ((((APoly[i].Y <= APoint.Y) and (APoint.Y < APoly[j].Y)) or
         ((APoly[j].Y <= APoint.Y) and (APoint.Y < APoly[i].Y))) and
        (APoint.X < (APoly[j].X - APoly[i].X) * (APoint.Y - APoly[i].Y) /
                    (APoly[j].Y - APoly[i].Y) + APoly[i].X)) then
      Result := not Result;
  end;
end;

Function PointInSidePolygon(inStr : String) : Boolean;
Var
 ThePoint : TPoint;
 Points : Array of TPoint;
 s1,s2 : string;
 Ncount : integer;
begin
 result := false;
 inStr := trim(inStr);
 if inStr = '' then exit;
 while Pos('"',inStr) <> 0 do
  delete(inStr,Pos('"',inStr),1);
 ThePoint.X := StrToInt(GetHeadString(inStr,' '));
 inStr := trim(inStr);
 if inStr = '' then exit;
 ThePoint.Y := StrToInt(GetHeadString(inStr,' '));
 inStr := trim(inStr);
 if inStr = '' then exit;
 Ncount := 0;
 while inStr <> '' do
  begin
   inc(nCount);
   setLength(Points,Ncount);
   Points[Ncount-1].X := StrToInt(GetHeadString(inStr,' '));
   inStr := trim(inStr);
   if inStr = '' then exit;
   Points[Ncount-1].Y := StrToInt(GetHeadString(inStr,' '));
   inStr := trim(inStr);
  end;
 result := PointInPoly(ThePoint,Points);
end;

Function TExp.FunctionResult(inStr1,inStr2 : String) : String;
Var
 tByte : Byte;
 k : String;
 t1,t2 : String;
 u1,u2 : integer;
 tCh : Char;
begin
 if inStr1 = 'SIN' then
  result := FloatToStr(sin(StrToFloat(GetItemValue(inStr2,tByte)))) else
 if inStr1 = 'COS' then
  result := FloatToStr(cos(StrToFloat(GetItemValue(inStr2,tByte)))) else
 if inStr1 = 'TAN' then
  result := FloatToStr(tan(StrToFloat(GetItemValue(inStr2,tByte)))) else
 if inStr1 = 'RANDOM' then
  result := FloatToStr(random(StrToInt(GetItemValue(inStr2,tByte)))) else
 if inStr1 = 'ABS' then
  result := FloatToStr(abs(StrToFloat(GetItemValue(inStr2,tByte)))) else
 if inStr1 = 'ISINTEGER' then
  result := IntToStr(isInteger(GetItemValue(inStr2,tByte))) else
 if inStr1 = 'ISLONGDATE' then
  result := IntToStr(isLongDate(GetItemValue(inStr2,tByte))) else
 if inStr1 = 'UPPERCASE' then
  result := '"'+Uppercase(GetItemValue(inStr2,tByte))+'"' else
 if inStr1 = 'LOWERCASE' then
  result := '"'+Lowercase(GetItemValue(inStr2,tByte))+'"' else
 if inStr1 = 'INTTOSTR' then
  result := '"'+GetItemValue(inStr2,tByte)+'"' else
 if inStr1 = 'GETRANDOMSTRING' then
  result := '"'+GetRandomString(StrToInt(GetItemValue(inStr2,tByte)))+'"' else 
 if inStr1 = 'INTTOTIME' then
  result := '"'+IntToTime(StrToInt(GetItemValue(inStr2,tByte)))+'"' else
 if inStr1 = 'FLOATTOSTR' then
  result := '"'+GetItemValue(inStr2,tByte)+'"' else
 if inStr1 = 'CHR' then
  result := '"'+Chr(StrToInt(GetItemValue(inStr2,tByte)))+'"' else
 if inStr1 = 'ORD' then
  begin
   t1 := GetItemValue(inStr2,tByte);
   if t1[1] = '"' then
    begin
     delete(t1,1,1);
     //delete(t1,length(t1),1);
    end;
   if t1[length(t1)] = '"' then
    begin
     delete(t1,Length(t1),1);
    end;
   if t1 ='' then begin result := '0'; end else
   begin
    tCh := t1[1];
    result := IntToStr(ord(tCh));
   end;
  end else
 if inStr1 = 'HEXTOINT' then
  begin
   t1 := GetItemValue(inStr2,tByte);
   if t1[1] = '#' then t1[1] := '$';
   result := IntToStr(strtoint(t1));
  end else
 if inStr1 = 'INTTOHEX' then
  begin
   t1 := GetItemValue(inStr2,tByte);
   u1 := StrToInt(t1);
   result := '"#' + IntToHEX(u1,1) + '"';
  end else
 if inStr1 = 'STRTOINT' then
  result := GetItemValue(inStr2,tByte) else
 if inStr1 = 'POINTINPOLYGON' then
  begin
   if PointInSidePolygon(GetItemValue(inStr2,tByte)) then
    result := '1' else
    result := '0';
  end else
 if inStr1 = 'CHECKONLINE' then
  begin
   if CheckOffLine(GetItemValue(inStr2,tByte)) then
    result := '1' else
    result := '0';
  end else
 if inStr1 = 'STRTOFLOAT' then
  result := GetItemValue(inStr2,tByte) else
 if inStr1 = 'ROUND' then
  result := IntToStr(Round(StrToFloat(GetItemValue(inStr2,tByte)))) else
 if inStr1 = 'LENGTH' then
  begin
   k := GetItemValue(inStr2,tByte);
   if tByte <> 1 then
    begin
     result := '';
     //error...
     exit;
    end;
   result := IntToStr(length(k));
  end else
 if inStr1 = 'GETDIRSTRING' then
  begin
   {
   k := GetItemValue(inStr2,tByte);
   t1 := ExtractFilePath(Application.exeName);
   t1 := t1 + 'data\';
   k := t1 + k;
   if k[length(k)] <> '\' then
    k := k + '\';
   result := '"' + GetDirString(k) + '"'; }
  end else
 if inStr1 = 'DIREXISTS' then
  begin
   {
   k := GetItemValue(inStr2,tByte);
   t1 := ExtractFilePath(Application.ExeName);
   t1 := t1 + 'data\';
   k := t1 + k;
   if k[length(k)] <> '\' then
    k := k + '\';
   if DirectoryExists(k) then
    result := '1' else
    result := '0';
    }
  end else
 if inStr1 = 'CREATEDIR' then
  begin
   {
   k := GetItemValue(inStr2,tByte);
   t1 := ExtractFilePath(Application.ExeName);
   t1 := t1 + 'data\';
   k := t1 + k;
   if k[length(k)] <> '\' then
    k := k + '\';
   if not DirectoryExists(k) then
    begin
     CreateDir(k);
     result := '1';
    end else
    result := '0';
   }
  end else
 if inStr1 = 'SYSFILEEXISTS' then
  begin
   {
   k := GetItemValue(inStr2,tByte);
   t1 := ExtractFilePath(Application.ExeName);
   t1 := t1 + 'system\';
   k := t1 + k;
   if FileExists(k) then
    begin
     result := '1';
    end else
    result := '0';
    }
  end else
 if inStr1 = 'SYSDELETEFILE' then
  begin
   {
   k := GetItemValue(inStr2,tByte);
   t1 := ExtractFilePath(Application.ExeName);
   t1 := t1 + 'system\';
   k := t1 + k;
   if FileExists(k) then
    begin
     DeleteFile(k);
     result := '1';
    end else
    result := '0';
    }
  end else
 if inStr1 = 'FILEEXISTS' then
  begin
   {
   k := GetItemValue(inStr2,tByte);
   t1 := ExtractFilePath(Application.ExeName);
   t1 := t1 + 'data\';
   k := t1 + k;
   if FileExists(k) then
    begin
     result := '1';
    end else
    result := '0';
    }
  end else
 if inStr1 = 'DELETEFILE' then
  begin
   {
   k := GetItemValue(inStr2,tByte);
   t1 := ExtractFilePath(Application.ExeName);
   t1 := t1 + 'data\';
   k := t1 + k;
   if FileExists(k) then
    begin
     DeleteFile(k);
     result := '1';
    end else
    result := '0';
    }
  end else
 if inStr1 = 'POS' then
  begin
   t2 := GetItemValue(inStr2,tByte);
   t1 := GetHeadString(t2,',');
   inStr2 := GetHeadString(t2,';');
   t2 := inStr2;
   t1 := GetItemValue(t1,tByte);
   t2 := GetItemValue(t2,tByte);
//   delete(t2,1,1);
   result := IntToStr(Pos(t1,t2));
//   if Pos(t1,t2) <> 0 then
//    result := 'TRUE' else
//    result := 'FALSE';
  end else
 if inStr1 = 'COPY' then
  begin
   t2 := GetItemValue(inStr2,tByte);
   t1 := GetHeadString(t2,',');
   t1 := GetItemValue(t1,tByte);
   if t1[1] = '"' then
    begin
     delete(t1,1,1);
     delete(t1,length(t1),1);
    end;
   k := GetHeadString(t2,',');
   u1 := StrToInt(GetItemValue(k,tByte));
   k := GetHeadString(t2,';');
   u2 := StrToInt(GetItemValue(k,tByte));
   Result := '"'+Copy(t1,u1,u2)+'"';
  end else
 if inStr1 = 'GETHEADSTRING' then
  begin
   t2 := GetItemValue(inStr2,tByte);
   t1 := GetHeadString(t2,',');
   t1 := GetItemValue(t1,tByte);
   if t1[1] = '"' then
    begin
     delete(t1,1,1);
     delete(t1,length(t1),1);
    end;
   k := GetHeadString(t2,';');
   k := GetItemValue(k,tByte);
   if k[1] = '"' then
    begin
     delete(k,1,1);
     delete(k,length(k),1);
    end;
   result := '"' + GetHeadString(t1,k[1]) + '"';
  end else
 if inStr1 = 'DELETELEADING' then
  begin
   t2 := GetItemValue(inStr2,tByte);
   t1 := GetHeadString(t2,',');
   t1 := GetItemValue(t1,tByte);
   if t1[1] = '"' then
    begin
     delete(t1,1,1);
     delete(t1,length(t1),1);
    end;
   k := GetHeadString(t2,';');
   k := GetItemValue(k,tByte);
   if k[1] = '"' then
    begin
     delete(k,1,1);
     delete(k,length(k),1);
    end;
   GetHeadString(t1,k[1]);
   result := '"' + t1 + '"';
  end else
 if inStr1 = 'NOW' then
  begin
   result := '"'+DateTimeToStr(Now)+'"';
  end else
 if inStr1 = 'RGBTOCOLOR' then
  begin
   t2 := GetItemValue(inStr2,tByte);
   t1 := GetHeadString(t2,',');
   t1 := GetItemValue(t1,tByte);
   if t1[1] = '"' then
    begin
     delete(t1,1,1);
     delete(t1,length(t1),1);
    end;
   k := GetHeadString(t2,',');
   u1 := StrToInt(GetItemValue(k,tByte));
   k := GetHeadString(t2,';');
   u2 := StrToInt(GetItemValue(k,tByte));
   Result := '"#'+IntToHex(RGB(StrToInt(t1),u1,u2),1)+'"';
  end else
 if inStr1 = 'TRIM' then
  begin
   k := GetItemValue(inStr2,tByte);
   if tByte <> 1 then
    begin
     result := '""';
     //error...
     exit;
    end;
   k := trim(k);
   result := '"'+k+'"';
  end else
 if inStr1 = 'MESSAGEBOX' then
  begin
   {
   t2 := GetItemValue(inStr2,tByte);
   t1 := GetHeadString(t2,',');
   t1 := GetItemValue(t1,tByte);
   if t1[1] = '"' then
    begin
     delete(t1,1,1);
     delete(t1,length(t1),1);
    end;
   k := GetHeadString(t2,',');
   k := GetItemValue(k,tByte);
   if k[1] = '"' then
    begin
     delete(k,1,1);
     delete(k,length(k),1);
    end;
   inStr2 := GetHeadString(t2,';');
   u2 := StrToInt(GetItemValue(inStr2,tByte));
   u1 := Application.MessageBox(@t1[1],@k[1],u2);
   result := IntToStr(u1);
   }
  end else
  begin
//   showMessage('Unknow function call!');
   result := 'OutSide';
  end;
 if result[1] = '-' then result[1] := '~';
end;

  function varthings(inStr : string): Byte;
   Var
    i : integer;
    ok : Boolean;
   begin
    //result: 0 for constant string... 1 for constant integer... 2 for constant real...
    //3 for vars... 4 for constant boolean...

    if Pos('"',inStr) <> 0 then
    begin
     result := 0;
     exit;
    end;
    if (uppercase(inStr) = 'TRUE') or
       (Uppercase(inStr) = 'FALSE') then
     begin
      result := 4;
      exit;
     end;
     ok := false;
     for i := 1 to length(inStr) do
      begin
       ok := not (inStr[i] in ['+','-','.','0'..'9']);
       if ok then break;
      end;
     if ok then
      begin
       if i = 1 then
        begin
         result := 3;
         exit;
        end;
       if (inStr[i] in ['e','E']) and
          (inStr[i-1] in ['0'..'9']) and
          (inStr[i+1] in ['+','-','0'..'9']) then
        begin
         result := 2;
         exit;
        end;
       result := 3;
       exit;
      end;
     if Pos('.',inStr) <> 0 then
      begin
       result := 2;
       exit;
      end;
     result := 1;
   end;

Function TExp.GetItemValue(inStr : String; Var sType : Byte) : string;
Var
 i : integer;
 ok : Boolean;
 comingStr : String;
 tMode : Byte;
begin
 if Pos('"',inStr) <> 0 then
  begin
   sType := 1;
   delete(inStr,Pos('"',inStr),1);
   delete(inStr,Pos('"',inStr),1);
   result := inStr;
  end else
 if (Uppercase(inStr) = 'TRUE') or (Uppercase(inStr) = 'FALSE') then
  begin
   sType := 0;
   result := inStr;
  end else
  begin
   // we need more thing to identity the value, but...
   ok := false;
   if Pos('~',inStr) = 1 then
    inStr[1] := '-';
   for i := 1 to length(inStr) do
    begin
     ok := not (inStr[i] in ['0'..'9','+','-','.']);
     if ok then break;
    end;
   if not ok then
    begin
     sType := 2;
     result := inStr;
    end else
    begin
     ok := false;
     for i := 0 to Items - 1 do
      begin
       if ItemsArray[i].Name = inStr then ok := true;
       if ok then break;
      end;
     if ok then
      begin
       if (Uppercase(ItemsArray[i].Value) = 'TRUE') or (Uppercase(ItemsArray[i].Value) = 'FALSE') then
        sType := 0 else
       if Pos('"',ItemsArray[i].Value) <> 0 then
        sType := 1 else
        sType := 2;
       result := ItemsArray[i].value;
       if stype = 1 then
        begin
         delete(result,1,1);
         delete(result,length(result),1);
        end;
      end else
      begin
       if assigned(FOnGetValue) then
        begin
//         if instr = '@s12.showcaption' then
//          begin
//           stype := 3;
//          end;
         FOnGetValue(inStr,comingStr,tMode);
         if tMode = 255 then
          begin
           // jinsong showmessage('255 Unknow identifier '+inStr);
           result := '';
          end else
          begin
           sType := tMode;
           if tMode = 1 then
            begin
             if comingStr <> '' then
              begin
               if comingStr[1] = '"' then
                delete(comingStr,1,1);
               if comingStr[length(comingStr)] = '"' then
                delete(comingStr,length(comingStr),1);
              end else
              begin
              end;
            end;
           result := comingStr;
          end
        end else
        begin
         // jinsong showmessage('Unknow identifier '+inStr);
         result := '';
        end;
      end;
    end;
  end
end;

Function TExp.Calc(inStr : String) : String;
var
 i, j, k : integer;
 tmpStr : String;
 kStr : String;
 uStr : String;
 operator1 : Char;
 it1,it2,it3,it4,it5 : string;
 tByte : Byte;
 b1,b2 : Boolean;
begin
 if inStr = '' then begin result := ''; exit; end;
 tmpStr := inStr;
 if (Uppercase(tmpStr) = 'TRUE') or (Uppercase(tmpStr) = 'FALSE') then
  begin
   result := tmpStr;
   exit;
  end;
 kStr := '';
 if (tmpStr[1] = '"') and (tmpStr[Length(tmpStr)-1] = '"') then
  begin
   it4 := GetItemValue(GetHeadString(tmpStr,';'),tByte);
   if tByte = 1 then
    result := '"' + it4 + '"' else
    result := it4;
   exit;
  end;
 while Pos('`',tmpStr) <> 0 do
  begin
   it1 := copy(tmpStr,1,Pos('`',tmpStr)-1);
   delete(tmpStr,1,Pos('`',tmpStr));
   GetHeadString(tmpStr,';');
   it2 := GetHeadString(tmpStr,';');
   it4 := '';
   while it1 <> '' do
    begin
     it3 := GetHeadString(it1,';');
     if it1 <> '' then
      it4 := it4 + it3 + ';';
    end;
   it3 := uppercase(it3);
   it5 := FunctionResult(it3,it2);
   if it5 = 'OutSide' then
    begin
     it2 := GetItemValue(it2,tByte);
     if tbyte=1 then it2 := '"'+it2+'"';
     it1 := '';
     while Pos(',',it2) <> 0 do
      begin
       it5 := GetHeadString(it2,',');
       if (Pos('RE_',it5)<> 0) and (Pos('_RE',it5)<>0) then
        begin
         it5 := GetItemValue(it5,tByte);
         if tbyte=1 then it5 := '"'+it5+'"';
         it1 := it1 + it5 + ',';
        end else
        begin
         it5 := GetItemValue(it5,tByte);
         if tByte=1 then it5 := '"'+it5+'"';
         it1 := it1 + it5 + ',';
        end;
      end;
     if Pos(';',it2) <> 0 then
      it5 := GetHeadString(it2,';') else
      it5 := it2;
     if (Pos('RE_',it5)<> 0) and (Pos('_RE',it5)<>0) then
      begin
       it5 := GetItemValue(it5,tByte);
       if tbyte=1 then it5 := '"'+it5+'"';
       it1 := it1 + it5 + ',';
      end else
      begin
         it5 := GetItemValue(it5,tByte);
         if tByte=1 then it5 := '"'+it5+'"';
         it1 := it1 + it5 + ',';
       //it1 := it1 + it5 + ',';
      end;
     if Assigned(FOnFunctionCall) then
      it5 := OnFunctionCall(it3,it1) else
      it5 := '';
     tmpStr := it4 + it5 + ';' + tmpStr;
     //we need add something here... jinsong chen comment here...
    end else
   tmpStr := it4 + it5 + ';' + tmpStr
  end;

 repeat
  i := myPos('*',tmpStr);
  k := i;
  i := myPos('/',tmpStr);
  if i = 0 then begin end else
  if (i <> 0) and (i < k) then k := i else
  if (i <> 0) and (k = 0) then k := i else begin end;
  i := myPos('%',tmpStr);
  if i = 0 then begin end else
  if (i <> 0) and (i < k) then k := i else
  if (i <> 0) and (k = 0) then k := i else begin end;
  i := myPos('?',tmpStr);
  if i = 0 then begin end else
  if (i <> 0) and (i < k) then k := i else
  if (i <> 0) and (k = 0) then k := i else begin end;

  if k = 0 then begin end else
   begin
    Operator1 := tmpStr[k];
    it1 := copy(tmpStr,1,k-1);
    delete(tmpStr,1,k);
    GetHeadString(tmpStr,';');
    it2 := GetHeadString(tmpStr,';');
    it4 := '';
    while it1 <> '' do
     begin
      it3 := GetHeadString(it1,';');
      if it1 <> '' then
       it4 := it4 + it3 + ';';
     end;
    if operator1 = '*' then
     it5 := FloatToStr(StrToFloat(GetItemValue(it3,tByte))*StrToFloat(GetItemValue(it2,tByte))) else
    if operator1 = '/' then
     it5 := FloatToStr(StrToFloat(GetItemValue(it3,tByte))/StrToFloat(GetItemValue(it2,tByte))) else
    if operator1 = '%' then
     it5 := IntToStr(StrToInt(GetItemValue(it3,tByte)) MOD StrToInt(GetItemValue(it2,tByte))) else
    if operator1 = '?' then
     it5 := IntToStr(StrToInt(GetItemValue(it3,tByte)) DIV StrToInt(GetItemValue(it2,tByte)));
    if it5[1] = '-' then it5[1] := '~';
    tmpStr := it4 + it5 + ';' + tmpStr
   end;
 until k = 0;

 repeat
  i := myPos('+',tmpStr);
  j := myPos('-',tmpStr);
  if j <> 0 then
   begin
    if i <> 0 then
     begin
      if i < j then k := i else k := j;
     end else
      k := j
   end else
   begin
    if i <> 0 then
     k := i else k := 0;
   end;
  if k = 0 then begin end else
  if k = 1 then
   begin
    uStr := tmpStr;
    it1 := GetHeadString(uStr,';');
    if uStr = '' then
     begin
      result := it1;
      exit;
     end;
    tmpStr[k] := '~';
   end else
   begin
    Operator1 := tmpStr[k];
    it1 := copy(tmpStr,1,k-1);
    delete(tmpStr,1,k);
    GetHeadString(tmpStr,';');
    it2 := GetHeadString(tmpStr,';');
    it4 := '';
    while it1 <> '' do
     begin
      it3 := GetHeadString(it1,';');
      if it1 <> '' then
       it4 := it4 + it3 + ';';
     end;
    if operator1 = '+' then
     begin
      it1 := GetItemValue(it3,tByte);
      if (tByte = 1) then
       begin
        it5 := it1 + GetItemValue(it2,tByte);
        it5 := '"' + it5 + '"';
       end else
      if (tByte in [2,3,4,5]) then
       it5 := FloatToStr(StrToFloat(it1)+StrToFloat(GetItemValue(it2,tByte))) else
      begin
       //Error...
       it5 := '';
      end
     end else
     begin
      it5 := FloatToStr(StrToFloat(GetItemValue(it3,tByte))-StrToFloat(GetItemValue(it2,tByte)));
     end;
//    if (it4 <> '') or (tmpStr <> '') then
//     begin
      if it5[1] = '-' then
       it5[1] := '~';
//     end;
    tmpStr := it4 + it5 + ';' + tmpStr
   end;
 until k = 0;

 repeat
  i := myPos('>',tmpStr);
  k := i;
  i := myPos('<',tmpStr);
  if i = 0 then begin end else
  if (i <> 0) and (i < k) then k := i else
  if (i <> 0) and (k = 0) then k := i else begin end;
  i := myPos('|',tmpStr);
  if i = 0 then begin end else
  if (i <> 0) and (i < k) then k := i else
  if (i <> 0) and (k = 0) then k := i else begin end;
  i := myPos('!',tmpStr);
  if i = 0 then begin end else
  if (i <> 0) and (i < k) then k := i else
  if (i <> 0) and (k = 0) then k := i else begin end;
  i := myPos('\',tmpStr);
  if i = 0 then begin end else
  if (i <> 0) and (i < k) then k := i else
  if (i <> 0) and (k = 0) then k := i else begin end;
  i := myPos('=',tmpStr);
  if i = 0 then begin end else
  if (i <> 0) and (i < k) then k := i else
  if (i <> 0) and (k = 0) then k := i else begin end;

  if k = 0 then begin end else
  if k = 1 then
   begin

    //error........!!!
    result := '';
    exit;

   end else
   begin
    Operator1 := tmpStr[k];
    it1 := copy(tmpStr,1,k-1);
    delete(tmpStr,1,k);
    GetHeadString(tmpStr,';');
    it2 := GetHeadString(tmpStr,';');
    it4 := '';
    while it1 <> '' do
     begin
      it3 := GetHeadString(it1,';');
      if it1 <> '' then
       it4 := it4 + it3 + ';';
     end;

    it1 := GetItemValue(it3,tByte);
    case tByte of
     0 : begin
          if Operator1 = '=' then
           begin
            if Uppercase(it1) = Uppercase(GetItemValue(it2,tByte)) then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
          if Operator1 = '\' then
           begin
            if Uppercase(it1) <> Uppercase(GetItemValue(it2,tByte)) then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
           begin
            result := '';
            exit;
            //error
           end;
         end;
     1 : begin
          if Operator1 = '=' then
           begin
            if it1 = GetItemValue(it2,tByte) then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
          if Operator1 = '\' then
           begin
            if it1 <> GetItemValue(it2,tByte) then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
          if Operator1 = '<' then
           begin
            if it1 < GetItemValue(it2,tByte) then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
          if Operator1 = '>' then
           begin
            if it1 > GetItemValue(it2,tByte) then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
           begin
            result := '';
            exit;
            //error...
           end;
         end;
     2,3 : begin
          if Operator1 = '=' then
           begin
            if strToFloat(it1) = StrToFloat(GetItemValue(it2,tByte)) then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
          if Operator1 = '\' then
           begin
            if StrToFloat(it1) <> StrToFloat(GetItemValue(it2,tByte)) then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
          if Operator1 = '<' then
           begin
            if StrToFloat(it1) < StrToFloat(GetItemValue(it2,tByte)) then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
          if Operator1 = '>' then
           begin
            if StrToFloat(it1) > StrToFloat(GetItemValue(it2,tByte)) then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
          if Operator1 = '|' then
           begin
            if StrToFloat(it1) >= StrToFloat(GetItemValue(it2,tByte)) then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
          if Operator1 = '!' then
           begin
            if StrToFloat(it1) <= StrToFloat(GetItemValue(it2,tByte)) then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end;
         end;
    end;
    tmpStr := it4 + it5 + ';' + tmpStr
   end;
 until k = 0;

 repeat
  i := myPos('^',tmpStr);
  k := i;
  i := myPos('$',tmpStr);
  if i = 0 then begin end else
  if (i <> 0) and (i < k) then k := i else
  if (i <> 0) and (k = 0) then k := i else begin end;
  i := myPos('#',tmpStr);
  if i = 0 then begin end else
  if (i <> 0) and (i < k) then k := i else
  if (i <> 0) and (k = 0) then k := i else begin end;
  i := myPos('&',tmpStr);
  if i = 0 then begin end else
  if (i <> 0) and (i < k) then k := i else
  if (i <> 0) and (k = 0) then k := i else begin end;

  if k = 0 then begin end else
  if (k = 1) and (tmpStr[k] <> '#') then
   begin

    //error........!!!
    result := '';
    exit;

   end else
   begin
    Operator1 := tmpStr[k];
    it1 := copy(tmpStr,1,k-1);
    delete(tmpStr,1,k);
    GetHeadString(tmpStr,';');
    it2 := GetHeadString(tmpStr,';');
    it4 := '';
    while it1 <> '' do
     begin
      it3 := GetHeadString(it1,';');
      if it1 <> '' then
       it4 := it4 + it3 + ';';
     end;

    it1 := GetItemValue(it3,tByte);
    case tByte of
     0 : begin
          if Operator1 = '^' then
           begin
            b1 := Uppercase(it1)='TRUE';
            b2 := Uppercase(GetItemValue(it2,tByte))='TRUE';
            if b1 and b2 then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
          if Operator1 = '$' then
           begin
            b1 := Uppercase(it1)='TRUE';
            b2 := Uppercase(GetItemValue(it2,tByte))='TRUE';
            if b1 or b2 then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
          if Operator1 = '&' then
           begin
            b1 := Uppercase(it1)='TRUE';
            b2 := Uppercase(GetItemValue(it2,tByte))='TRUE';
            if b1 xor b2 then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
          if Operator1 = '#' then
           begin
            b2 := Uppercase(GetItemValue(it2,tByte))='TRUE';
            if not b2 then
             it5 := 'TRUE' else
             it5 := 'FALSE';
           end else
           begin
            result := '';
            exit;
            //error
           end;
         end;
     1 : begin
          //error...
         end;
     2 : begin
          if Operator1 = '^' then
           begin
            it5 := IntToStr(StrToInt(it1) and StrToInt(GetItemValue(it2,tByte)));
           end else
          if Operator1 = '$' then
           begin
            it5 := IntToStr(StrToInt(it1) or StrToInt(GetItemValue(it2,tByte)));
           end else
          if Operator1 = '&' then
           begin
            it5 := IntToStr(StrToInt(it1) xor StrToInt(GetItemValue(it2,tByte)));
           end else
          if Operator1 = '#' then
           begin
            it5 := IntToStr(not StrToInt(GetItemValue(it2,tByte)));
           end else
           begin
            result := '';
            exit;
            //error
           end;
         end;
    end;
    if it5[1] = '-' then it5[1] := '~';
    tmpStr := it4 + it5 + ';' + tmpStr
   end;
 until k = 0;

 it4 := GetItemValue(GetHeadString(tmpStr,';'),tByte);
 if tByte = 1 then
  result := '"' + it4 + '"' else
  result := it4;
end;


Function GetCStr(Var inStr : String; re_Str : String) : String;
var
 i,j,u : integer;
 ok : Boolean;
 c : Char;
 tmpStr, t1, t2 : String;
begin
 if Pos('"',inStr) = 0 then
  begin
   result := '';
   exit;
  end;
 i := Pos('"',inStr);
 j := i;
 u := 1;
 tmpStr := '';
 repeat
  inc(j);
  c := inStr[j];
  if c = '"' then u := u - 1 else
   tmpStr := tmpStr + c;
  if (tmpStr <> '') and (u = 0) then
   ok := true else
  if (tmpStr = '') and (u <= -1) then
   ok := true else
  ok := false;
 until ok or (j >= length(inStr));
 if (not ok) and (u > 0) then
  begin
   // jinsong showmessage('string constant not properly nested!');
   result := '';
   exit;
  end;
 if (tmpStr = '') and ( u = 0) then
  j := i + 1;
 t1 := copy(inStr,1,i-1);
 t2 := copy(inStr,j+1,length(inStr));
 inStr := t1 + re_Str + t2;
 if tmpStr <> '' then
  result := '"' + tmpStr + '"' else
 if (tmpStr = '') and (u = 0) then
  result := '""' else
 if (tmpStr = '') and (u < 0) then
  result := '"""';
end;

Function GetInclude(Var inStr : String; Var is_routine : Boolean; re_str : string) : String;
var
 i, j, k, u : integer;
 ok : Boolean;
 c : Char;
 tmpStr,t1,t2 : String;
begin
 if Pos('(',inStr) = 0 then
  begin
   result := '';
   exit;
  end;
 i := Pos('(',inStr);
 j := i; k := i;
 ok := false;
 tmpStr := '';
 if j=1 then begin end else
 repeat
  dec(j);
  c := inStr[j];
  ok := c in [' ','+','-','*','/','`','>','<','='];
  if not ok then tmpStr := c + tmpStr;
 until ok or (j = 1);
 if ok then inc(j);
 if tmpStr <> '' then
  begin
//   if j <> 1 then inc(j);
   i := j;
   is_routine := True;
  end else
   is_routine := false;
 u := 1;
 if k=length(inStr) then
  begin
   // jinsong showMessage('error!, ( is at End...');
   result := '';
   exit;
  end else
  repeat
   inc(k);
   c := inStr[k];
   if c = '(' then u := u + 1;
   if c = ')' then u := u - 1;
  until (u = 0) or (k = length(inStr));
 if u <> 0 then
  begin
   // jinsong showMessage('Error, () is not properly nested!');
   result := '';
   exit;
  end;
 tmpStr := Copy(inStr,i,k-i+1);
 t1 := Copy(inStr,1,i-1);
 t2 := Copy(inStr,k+1,length(inStr)-j);
 inStr := t1 + re_Str + t2;
 result := tmpStr;
end;

Function GetOperator(Var inStr : String) : String;
Var
 c : Char;
 c1 : Char;
 tempStr : String;
begin
 tempStr := '';
 inStr := trim(inStr);
 if inStr = '' then
  begin
   result := '';
   exit;
  end;
 c := inStr[1];
 if (c in ['+','-','*','/','(',')','<','>','=','`']) then
  begin
   if c = '<' then
    begin
     if inStr[2]= '=' then
      c1 := '!' else
     if inStr[2]= '>' then
      c1 := '\' else
      c1 := 'N';
    end else
   if c = '>' then
    begin
     if inStr[2] = '=' then
      c1 := '|' else
      c1 := 'N';
    end else
   c1 := 'N';
   if c1 <> 'N' then
    begin
     delete(inStr,1,2);
     result := tempstr + c1;
    end else
    begin
     delete(inStr,1,1);
     result := tempstr + c;
    end;
  end else
 result := '';
end;

Function Getword(Var inStr : String) : String;
Var
 i,j : integer;
 c : Char;
 tmpStr : String;
 ok : boolean;
begin
 ok := false;
 if inStr = '' then
  begin
   result := '';
   exit;
  end;
 tmpStr := '';
 j := 0;
 for i := 1 to length(inStr) do
  begin
   c := inStr[i];
   if (c in ['+','-','*','/',' ','(',')','<','>','=','`']) then
    ok := true else
   tmpStr := tmpStr + c;
   if ok then break;
   inc(j);
  end;
 if j <> 0 then delete(inStr,1,j);
 result := tmpStr;
end;

Function cExp(inStr : String) : String;
Var
 tmpStr : String;
 k,l : string;
 i : integer;
 routine : boolean;
begin
 tmpStr := '';
 i := 0;
 while Pos('(',inStr)<> 0 do
  begin
   GetInclude(inStr,routine,'RE_'+IntToStr(i)+'_RE');
   inc(i);
  end;

 while inStr <> '' do
  begin
   k := GetWord(inStr);
   if k <> '' then tmpStr := tmpStr + k + ';';
   l := GetOperator(inStr);
   if l <> '' then tmpStr := tmpStr + l + ';';
  end;
 result := tmpStr;
end;

Constructor TExp.create;
 begin
  inherited;
  Items := 0;
  Ops := 0;
 end;

Destructor TExp.destroy;
 begin
  ItemsArray := Nil;
 end;

Procedure TExp.setContent(inStr : String);
 begin
  Items := 0;
  ItemsArray := Nil;
  Content := inStr;
  BuildItemArray(Content);
  CalculateItem;
 end;

Function TExp.SmartString(inStr : String) : String;
 Var
  tmpStr : String;
  t1,t2,t3,t4,t5 : String;
  i,j : integer;
  ok : boolean;
 begin
  if Pos('[',inStr) = 0 then
   begin
    result := inStr;
    exit;
   end;
  tmpStr := inStr;
  j := 0;
//  k := 0;
  repeat
   ok := false;
   for i := 1 to length(tmpStr) do
    begin
     if tmpStr[i] = '[' then j := i;
     if tmpStr[i] = ']' then
      begin
//       k := i;
       ok := true;
       break;
      end;
    end;
   if not ok then
    begin
     // jinsong showmessage('[ is not equilvent!');
     Result := '';
     exit;
    end;
   t1 := copy(tmpstr,1,j-1);
   delete(tmpstr,1,j);
   t2 := GetHeadString(tmpstr,']');
   t3 := tmpStr;
   t4 := t2 + ',';
   t5 := '';
   while t4 <> '' do
    begin
     t2 := GetHeadString(t4,',');
     setContent(t2);
     t2 := GetResult;
     t5 := t5 + t2 +',';
    end;
   delete(t5,Length(t5),1);
   t2 := t5;
   tmpStr := t1+'{'+t2+'}'+t3;
  until Pos('[',tmpStr)=0;
  for i := 1 to length(tmpstr) do
   if tmpStr[i] = '{' then
    tmpStr[i] := '[' else
   if tmpStr[i] = '}' then
    tmpStr[i] := ']';
  Result := tmpStr;
//  setContent(tmpStr);
 end;

Procedure TExp.CalcSubIndex(inStr : String);
 Var
  tmpStr : String;
  t1,t2,t3,t4,t5 : String;
  i,j : integer;
  ok : boolean;
 begin
  if (Pos('[',inStr) = 0) or ((inStr[1]='"') and (inStr[length(inStr)]='"')) then
   begin
    setContent(inStr);
    exit;
   end;
  tmpStr := inStr;
  j := 0;
//  k := 0;
  repeat
   ok := false;
   for i := 1 to length(tmpStr) do
    begin
     if tmpStr[i] = '[' then j := i;
     if tmpStr[i] = ']' then
      begin
//       k := i;
       ok := true;
       break;
      end;
    end;
   if not ok then
    begin
     // jinsong showmessage('[ is not equilvent!');
     exit;
    end;
   t1 := copy(tmpstr,1,j-1);
   delete(tmpstr,1,j);
   t2 := GetHeadString(tmpstr,']');
   t3 := tmpStr;
   t4 := t2 + ',';
   t5 := '';
   while t4 <> '' do
    begin
     t2 := GetHeadString(t4,',');
     setContent(t2);
     t2 := GetResult;
     t5 := t5 + t2 +',';
    end;
   delete(t5,Length(t5),1);
   t2 := t5;
   tmpStr := t1+'{'+t2+'}'+t3;
  until Pos('[',tmpStr)=0;
  for i := 1 to length(tmpstr) do
   if tmpStr[i] = '{' then
    tmpStr[i] := '[' else
   if tmpStr[i] = '}' then
    tmpStr[i] := ']';
  setContent(tmpStr);
 end;

Procedure TExp.BuildItemArray(Var InputStr : String);
 Var
  i : integer;
  tmpStr : String;
  routine : Boolean;
  k,l : string;
  u,v : string;
  xStr : String;
  is_O : Boolean;
 begin
{  if Pos('(',InputStr) = 0 then
   begin
    exit;
   end;
  inc(Items);}

 while Pos('"',InputStr)<>0 do
  begin
   inc(Items);
   tmpStr := 'RE_'+IntToStr(Items)+'_RE';
   k := GetCStr(InputStr,tmpStr);
   setLength(ItemsArray,Items);
   ItemsArray[items-1].Name := tmpStr;
   ItemsArray[items-1].Content := k + ';';
   ItemsArray[items-1].is_routine := false;
   ItemsArray[items-1].value := k;
  end;

 for i := 1 to length(InputStr) do
  if InputStr[i] = '{' then InputStr[i] := '[' else
   if InputStr[i] = '}' then InputStr[i] := ']';

  if (InputStr[1] = '-') or (inPutStr[1] = '+') then
   InputStr := '0' + inputStr;

  while Pos('(',InputStr)<> 0 do
   begin
    inc(Items);
    routine := false;
    tmpStr := 'RE_'+IntToStr(Items)+'_RE';
    k := GetInclude(InputStr,routine,tmpStr);
    if not routine then
     begin
      delete(k,1,1);
      delete(k,Length(k),1);
     end else
     begin
      l := copy(k,1,Pos('(',k)-1);
      delete(k,1,Pos('(',k)-1);
      k := l + '`' + k;
     end;
    setLength(ItemsArray,Items);
    ItemsArray[items-1].Name := tmpStr;
    ItemsArray[items-1].Content := k;
    ItemsArray[items-1].is_routine := routine;
    i := items - 1;
//    while Pos('(',ItemsArray[i].content) <> 0 do
//     begin
    xStr := ItemsArray[items-1].Content;
      BuildItemArray(xStr);
    ItemsArray[i].Content := xStr;
//     end;
   end;
  l := '';
  k := inputStr;
  while Pos(' ,',k) <> 0 do
   begin
    delete(k,Pos(' ,',k),1);
   end;
  while Pos(', ',k) <> 0 do
   begin
    delete(k,Pos(', ',k)+1,1);
   end;
  is_O := True;
  while k <> '' do
   begin
    u := GetWord(k);
    if u <> '' then
     begin
      tmpStr := Uppercase(u);
      if tmpStr = 'AND' then begin u := '^'; is_O := True; end else
      if tmpStr = 'OR' then begin u := '$'; is_O := True; end else
      if tmpStr = 'XOR' then begin u := '&'; is_O := True; end else
      if tmpStr = 'NOT' then begin u := '#'; is_O := True; end else
      if tmpStr = 'MOD' then begin u := '%'; is_O := True; end else
      if tmpStr = 'DIV' then begin u := '?'; is_O := True; end else
       is_O := false;
      l := l + u + ';';
     end;
    v := GetOperator(k);
    if v <> '' then
     begin
      if (v = '-') and is_O then
       l := l +'~' else
       l := l + v + ';';
      is_O := True;
     end;
   end;
  inputStr := l;
 end;

Procedure TExp.CalculateItem;
 Var
  i : integer;
  ut : String;
 begin
  if items = 0 then exit;
  for i := items - 1 downto 0 do
   begin
    ut := ItemsArray[i].Content;
    if (Pos('"',ut) = 0) and (Pos(',',ut) <> 0) then
     ItemsArray[i].value := ut else
    ItemsArray[i].value := calc(ut);
   end;
 end;

Function TExp.GetResult : String;
 Var
  ut : String;
 begin
  ut := Content;
  result := calc(ut);
 end;

Constructor TStatusStack.create;
 begin
  StatusCount := 0;
  Count := 0;
  _isControl := 0;
 end;

Destructor TStatusStack.destroy;
 begin
  StatusList := Nil;
  inherited destroy;
 end;

Procedure TStatusStack.Push(stype : Byte; sPos : integer);
 begin
  if StatusCount = Count then
   begin
    inc(StatusCount);
    inc(Count);
    setLength(StatusList,StatusCount);
   end else
   begin
    inc(StatusCount);
   end;
  StatusList[StatusCount-1].sType := stype;
  StatusList[StatusCount-1].Pos := sPos;
  _isControl := stype;
 end;

Procedure TStatusStack.Pop(Var stype : Byte; Var sPos : integer);
 begin
  if StatusCount = 0 then
   begin
    exit;
   end;
  sType := StatusList[StatusCount-1].sType;
  sPos := StatusList[StatusCount-1].Pos;
  Dec(StatusCount);
  if StatusCount = 0 then _isControl := 0 else
   _isControl := StatusList[StatusCount-1].sType;
 end;

Function TStatusStack._isEmpty : Boolean;
 begin
  Result := StatusCount = 0;
 end;

Constructor TVars.create;
 begin
  VarsCount := 0;
 end;

Destructor TVars.destroy;
 Var
  i : integer;
 begin
  if VarsCount <> 0 then
   begin
    for i := 0 to VarsCount - 1 do
     begin
      if VarList[i].sType = 4 then
       VarList[i].IntArray := Nil else
      if VarList[i].sType = 5 then
       VarList[i].RealArray := Nil else
      if VarList[i].sType = 6 then
       VarList[i].StrArray := Nil;
//      if VarList[i].sType = 7 then
//       VarList[i].StrList.Destroy;
     end;
    VarList := Nil;
   end;
  inherited destroy;
 end;

Procedure TVars.DefineVar(inStr : String; sType : Byte);
 Var
  i,j : integer;
  DIM,tmpInt1, tmpInt2 : Integer;
  tmpStr1,s1 : String;
 begin
  if VarsCount = 0 then begin end else
  begin
   for j := 0 to VarsCount - 1 do
    begin
     if (sType in [0,1,2,3]) then
      begin
       if VarList[j].Name = inStr then
        begin
         VarList[j].sType := sType;
         exit;
        end;
      end else
      begin
       s1 := inStr;
       s1 := GetHeadString(s1,'[');
       if VarList[j].Name = s1 then
        begin
         VarList[j].sType := sType;
         exit;
        end;
      end;
    end;
  end;
  inc(VarsCount);
  i := VarsCount - 1;
  setLength(VarList,VarsCount);
  case sType of
   0 : begin
        VarList[i].Name := inStr;
        VarList[i].Value := 'FALSE';
        VarList[i].sType  := 0;
       end;
   1 : begin
        VarList[i].Name := inStr;
        VarList[i].Value := '""';
        VarList[i].sType := 1;
       end;
   2 : begin
        VarList[i].Name := inStr;
        VarList[i].Value := '0';
        VarList[i].sType := 2;
       end;
   3 : begin
        VarList[i].Name := inStr;
        VarList[i].Value := '0';
        VarList[i].sType := 3;
       end;
   4,5,6
     : begin
        VarList[i].Name := trim(GetHeadString(inStr,'['));
        tmpStr1 := trim(GetHeadString(inStr,']'));
        tmpStr1 := tmpStr1 + ',';
        VarList[i].DimensionCount := tmpStr1;
        DIM := 0;
        tmpInt2 := 0;
        while tmpStr1 <> '' do
         begin
          tmpInt1 := StrToInt(trim((GetHeadString(tmpstr1,','))));
          inc(DIM);
          if DIM = 1 then
          tmpInt2 := tmpInt1 else
          tmpInt2 := tmpInt2*tmpInt1;
         end;
        VarList[i].DLength := tmpInt2;
        VarList[i].Dimension := DIM;
        if stype = 4 then
         setlength(VarList[i].IntArray, tmpInt2) else
        if stype = 5 then
         setlength(VarList[i].RealArray, tmpInt2) else
        if stype = 6 then
         setlength(VarList[i].StrArray, tmpInt2);
        VarList[i].sType := stype;
       end;
//   7 : begin
//        VarList[i].Name := inStr;
//        VarList[i].strList := TStringList.create;
//        VarList[i].stype := 7;
//       end;
  end;
 end;

Procedure TVars.LoadFromFile(inStr, filename : String; Var stype : Byte);
Var
 tmpList : TStringList;
 st1,st2,st3 : string;
 i,j,l,m : integer;
 uByte : Byte;
 ok : Boolean;
 tempStream : TMemoryStream;
begin
 if VarsCount = 0 then begin stype := 255; exit; end;
 ok := false;
 for i := 0 to VarsCount - 1 do
  begin
   ok := Uppercase(inStr) = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 if not ok then begin stype := 255; exit; end;
 if (VarList[i].sType in [4,5,6]) then
  begin
   tmpList := TStringList.Create;
   if assigned(FOnLoadStream) then
    begin
     tempStream := TMemoryStream.create;
     FOnLoadStream(filename,tempStream,0);
     tempStream.seek(0,0);
     if tempStream.Size = 0 then
      begin
       tempStream.Free;
       tmpList.Free;
       exit;
      end;
     tmpList.LoadFromStream(tempStream);
     tempStream.free;
    end else
   tmpList.LoadFromFile(filename);
   case VarList[i].sType of
    4 : begin
         j := tmpList.Count;
         st1 := tmpList.Strings[0];
         st1 := trim(st1);
         l := 0;
         while st1 <> '' do
          begin
           GetHeadString(st1,'`');
           trim(st1);
           inc(l);
          end;
//         k := VarList[i].Dimension;
         if l > 1 then
          begin
           VarList[i].DimensionCount := inttoStr(l)+','+InttoStr(j)+',';
           VarList[i].Dimension := 2;
          end else
          begin
           VarList[i].DimensionCount := InttoStr(j)+',';
           VarList[i].Dimension := 1;
          end;
         VarList[i].DLength := l*j;
         Finalize(VarList[i].IntArray);
         VarList[i].IntArray := Nil;
         setLength(VarList[i].IntArray,VarList[i].Dlength);
         for m := 0 to j -1 do
          begin
           st1 := tmpList.Strings[m];
           l := 0;
           while st1 <> '' do
            begin
             st2 := GetHeadString(st1,'`');
             if VarList[i].Dimension = 2 then
              st3 := inStr + '['+IntToStr(l)+','+IntToStr(m)+']' else
              st3 := inStr + '['+IntToStr(m)+']';
             uByte := 4;
             setValue(st3,st2,uByte);
             trim(st1);
             inc(l);
            end;
          end;
        end;
    5 : begin
         j := tmpList.Count;
         st1 := tmpList.Strings[0];
         st1 := trim(st1);
         l := 0;
         while st1 <> '' do
          begin
           GetHeadString(st1,'`');
           trim(st1);
           inc(l);
          end;
//         k := VarList[i].Dimension;
         if l > 1 then
          begin
           VarList[i].DimensionCount := inttoStr(l)+','+InttoStr(j)+',';
           VarList[i].Dimension := 2;
          end else
          begin
           VarList[i].DimensionCount := InttoStr(j)+',';
           VarList[i].Dimension := 1;
          end;
         VarList[i].DLength := l*j;
         Finalize(VarList[i].RealArray);
         VarList[i].RealArray := Nil;
         setLength(VarList[i].RealArray,l*j);
         for m := 0 to j -1 do
          begin
           st1 := tmpList.Strings[m];
           l := 0;
           while st1 <> '' do
            begin
             st2 := GetHeadString(st1,'`');
             if VarList[i].Dimension = 2 then
              st3 := inStr + '['+IntToStr(l)+','+IntToStr(m)+']' else
              st3 := inStr + '['+IntToStr(m)+']';
             uByte := 5;
             setValue(st3,st2,uByte);
             trim(st1);
             inc(l);
            end;
          end;
        end;
    6 : begin
         j := tmpList.Count;
         st1 := tmpList.Strings[0];
         st1 := trim(st1);
         l := 0;
         while st1 <> '' do
          begin
           GetHeadString(st1,'`');
           trim(st1);
           inc(l);
          end;
//         k := VarList[i].Dimension;
         if l > 1 then
          begin
           VarList[i].DimensionCount := inttoStr(l)+','+InttoStr(j)+',';
           VarList[i].Dimension := 2;
          end else
          begin
           VarList[i].DimensionCount := InttoStr(j)+',';
           VarList[i].Dimension := 1;
          end;
         VarList[i].DLength := l*j;
         Finalize(VarList[i].StrArray);
         VarList[i].StrArray := Nil;
         setLength(VarList[i].StrArray,l*j);
         for m := 0 to j -1 do
          begin
           st1 := tmpList.Strings[m];
           l := 0;
           while st1 <> '' do
            begin
             st2 := GetHeadString(st1,'`');
             st2 := '"'+st2+'"';
             if VarList[i].Dimension = 2 then
              st3 := inStr + '['+IntToStr(l)+','+IntToStr(m)+']' else
              st3 := inStr + '['+IntToStr(m)+']';
             uByte := 6;
             setValue(st3,st2,uByte);
             trim(st1);
             inc(l);
            end;
          end;
        end;
   end;
   tmpList.free;
   stype := 0;
  end else
  begin
   stype := 255;
  end;
end;

Procedure TVars.SaveTOFile(inStr, filename : String; Var stype : Byte);
Var
 tmpList : TStringList;
 st1,st2,st3,st4 : string;
 i,j,k,l,m : integer;
 uByte : Byte;
 ok : Boolean;
 tempStream : TMemoryStream;
begin
 if VarsCount = 0 then begin stype := 255; exit; end;
 ok := false;
 for i := 0 to VarsCount - 1 do
  begin
   ok := Uppercase(inStr) = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 if not ok then begin stype := 255; exit; end;
 if not (VarList[i].sType in [4,5,6]) then begin stype := 255; exit; end;
 tmpList := TStringList.Create;
 case VarList[i].sType of
  4 : begin
       case VarList[i].Dimension of
        1 : begin
             for j := 0 to VarList[i].DLength - 1 do
              tmpList.Add(IntToStr(VarList[i].IntArray[j])+'`');
            end;
        2 : begin
             st1 := VarList[i].DimensionCount;
             j := StrToInt(GetHeadString(st1,','));
             k := StrToInt(GetHeadString(st1,','));
             uByte := 4;
             for l := 0 to k-1 do
              begin
               st2 := '';
               for m := 0 to j-1 do
                begin
                 st4 := inStr + '[' + IntTOStr(m) + ',' + IntToStr(l) + ']';
                 st3 := GetValue(st4,uByte);
                 st2 := st2 + st3 + '`';
                end;
               tmpList.Add(st2);
              end;
            end;
       end;
      end;
  5 : begin
       case VarList[i].Dimension of
        1 : begin
             for j := 0 to VarList[i].DLength - 1 do
              tmpList.Add(FloatToStr(VarList[i].RealArray[j])+'`');
            end;
        2 : begin
             st1 := VarList[i].DimensionCount;
             j := StrToInt(GetHeadString(st1,','));
             k := StrToInt(GetHeadString(st1,','));
             uByte := 5;
             for l := 0 to k-1 do
              begin
               st2 := '';
               for m := 0 to j-1 do
                begin
                 st4 := inStr + '[' + IntTOStr(m) + ',' + IntToStr(l) + ']';
                 st3 := GetValue(st4,uByte);
                 st2 := st2 + st3 + '`';
                end;
               tmpList.Add(st2);
              end;
            end;
       end;
      end;
  6 : begin
       case VarList[i].Dimension of
        1 : begin
             for j := 0 to VarList[i].DLength - 1 do
              begin
               st2 := VarList[i].StrArray[j];
               if st2[1] = '"' then delete(st2,1,1);
               if st2[length(st2)] = '"' then delete(st2,length(st2),1);
               tmpList.Add(st2+'`');
              end;
            end;
        2 : begin
             st1 := VarList[i].DimensionCount;
             j := StrToInt(GetHeadString(st1,','));
             k := StrToInt(GetHeadString(st1,','));
             uByte := 6;
             for l := 0 to k-1 do
              begin
               st2 := '';
               for m := 0 to j-1 do
                begin
                 st4 := inStr + '[' + IntTOStr(m) + ',' + IntToStr(l) + ']';
                 st3 := GetValue(st4,uByte);
                 if st3[1] = '"' then delete(st3,1,1);
                 if st3[length(st3)] = '"' then delete(st3,length(st3),1);
                 st2 := st2 + st3 + '`';
                end;
               tmpList.Add(st2);
              end;
            end;
       end;
      end;
 end;
 if Assigned(FOnLoadStream) then
  begin
   tempStream := TMemoryStream.Create;
   tmpList.SaveToStream(tempStream);
   tempStream.Seek(0,0);
   OnLoadStream(filename,tempStream,1);
   tempStream.Destroy;
  end else
  tmpList.SaveToFile(filename);
 tmpList.Destroy;
 stype := 0;
end;

Procedure TVars.sysLoadStrings(inStr,filename : string; Var stype : Byte);
Var
 tmpList : TStringList;
 st1,st2,st3 : string;
 i,j,l,m : integer;
 uByte : Byte;
 ok : Boolean;
 tempStream : TMemoryStream;
begin
 if VarsCount = 0 then begin stype := 255; exit; end;
 ok := false;
 for i := 0 to VarsCount - 1 do
  begin
   ok := Uppercase(inStr) = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 if not ok then begin stype := 255; exit; end;
 if (VarList[i].sType in [4,5,6]) then
  begin
   tmpList := TStringList.Create;
   {
    // notice must give the app's path here...
   }
   //st1 := ExtractFilePath(application.ExeName);
   st1 := st1 + 'system\' + filename;
   tmpList.LoadFromFile(st1);
   case VarList[i].sType of
    4 : begin

        end;
    5 : begin

        end;
    6 : begin
         j := tmpList.Count;
         st1 := tmpList.Strings[0];
         st1 := trim(st1);
         st1 := SelfDecode(st1);
         l := 1;
//         while st1 <> '' do
//          begin
//           GetHeadString(st1,'`');
//           trim(st1);
//           inc(l);
//          end;
//         k := VarList[i].Dimension;
         if l > 1 then
          begin
           VarList[i].DimensionCount := inttoStr(l)+','+InttoStr(j)+',';
           VarList[i].Dimension := 2;
          end else
          begin
           VarList[i].DimensionCount := InttoStr(j)+',';
           VarList[i].Dimension := 1;
          end;
         VarList[i].DLength := l*j;
         Finalize(VarList[i].StrArray);
         VarList[i].StrArray := Nil;
         setLength(VarList[i].StrArray,l*j);
         for m := 0 to j -1 do
          begin
           st1 := tmpList.Strings[m];
           st1 := SelfDecode(st1);
           while st1 <> '' do
            begin
             //st2 := GetHeadString(st1,'`');
             st2 := '"'+st1+'"';
             st1 := '';
             st3 := inStr + '['+IntToStr(m)+']';
             uByte := 6;
             setValue(st3,st2,uByte);
            end;
          end;
        end;
   end;
   tmpList.free;
   stype := 0;
  end else
  begin
   stype := 255;
  end;
end;

Procedure TVars.sysLoadFile(inStr : String; Var stype : Byte);
Var
 tmpList : TStringList;
 st1,st2,st3 : string;
 i,j,l,m : integer;
 uByte : Byte;
 ok : Boolean;
 tempStream : TMemoryStream;
begin
 if VarsCount = 0 then begin stype := 255; exit; end;
 ok := false;
 for i := 0 to VarsCount - 1 do
  begin
   ok := Uppercase(inStr) = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 if not ok then begin stype := 255; exit; end;
 if (VarList[i].sType in [4,5,6]) then
  begin
   tmpList := TStringList.Create;
   //st1 := ExtractFilePath(application.ExeName);
   {
    notice must get the app's path here...
   }
   st1 := st1 + 'system\tryshell.shl';
   tmpList.LoadFromFile(st1);
   case VarList[i].sType of
    4 : begin

        end;
    5 : begin

        end;
    6 : begin
         j := tmpList.Count;
         st1 := tmpList.Strings[0];
         st1 := trim(st1);
         st1 := DoubleLengthToString(st1);
         l := 1;
//         while st1 <> '' do
//          begin
//           GetHeadString(st1,'`');
//           trim(st1);
//           inc(l);
//          end;
//         k := VarList[i].Dimension;
         if l > 1 then
          begin
           VarList[i].DimensionCount := inttoStr(l)+','+InttoStr(j)+',';
           VarList[i].Dimension := 2;
          end else
          begin
           VarList[i].DimensionCount := InttoStr(j)+',';
           VarList[i].Dimension := 1;
          end;
         VarList[i].DLength := l*j;
         Finalize(VarList[i].StrArray);
         VarList[i].StrArray := Nil;
         setLength(VarList[i].StrArray,l*j);
         for m := 0 to j -1 do
          begin
           st1 := tmpList.Strings[m];
           st1 := DoubleLengthToString(st1);
           while st1 <> '' do
            begin
             //st2 := GetHeadString(st1,'`');
             st2 := '"'+st1+'"';
             st1 := '';
             st3 := inStr + '['+IntToStr(m)+']';
             uByte := 6;
             setValue(st3,st2,uByte);
            end;
          end;
        end;
   end;
   tmpList.free;
   stype := 0;
  end else
  begin
   stype := 255;
  end;
end;

Procedure TVars.sysSaveStrings(inStr,filename : string; Var stype : Byte);
Var
 tmpList : TStringList;
 st1,st2,st3,st4 : string;
 i,j,k,l,m : integer;
 uByte : Byte;
 ok : Boolean;
 tempStream : TMemoryStream;
begin
 if VarsCount = 0 then begin stype := 255; exit; end;
 ok := false;
 for i := 0 to VarsCount - 1 do
  begin
   ok := Uppercase(inStr) = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 if not ok then begin stype := 255; exit; end;
 if not (VarList[i].sType in [4,5,6]) then begin stype := 255; exit; end;
 tmpList := TStringList.Create;
 case VarList[i].sType of
  4 : begin

      end;
  5 : begin

      end;
  6 : begin
       case VarList[i].Dimension of
        1 : begin
             for j := 0 to VarList[i].DLength - 1 do
              begin
               st2 := VarList[i].StrArray[j];
               if st2[1] = '"' then delete(st2,1,1);
               if st2[length(st2)] = '"' then delete(st2,length(st2),1);
               st2 := SelfEncode(st2);
               tmpList.Add(st2);
              end;
            end;
        2 : begin
             st1 := VarList[i].DimensionCount;
             j := StrToInt(GetHeadString(st1,','));
             k := StrToInt(GetHeadString(st1,','));
             uByte := 6;
             for l := 0 to k-1 do
              begin
               st2 := '';
               for m := 0 to j-1 do
                begin
                 st4 := inStr + '[' + IntTOStr(m) + ',' + IntToStr(l) + ']';
                 st3 := GetValue(st4,uByte);
                 if st3[1] = '"' then delete(st3,1,1);
                 if st3[length(st3)] = '"' then delete(st3,length(st3),1);
                 st2 := st2 + st3 + '`';
                end;
               st2 := SelfEncode(st2);
               tmpList.Add(st2);
              end;
            end;
       end;
      end;
 end;
 {
  notice must get the app's path here...
 }
 //st1 := ExtractFilePath(application.ExeName);
 st1 := st1 + 'system\' + filename;
 repeat
  i := 0;
  ok := false;
  repeat
   if trim(tmpList.Strings[i]) = '' then
    begin
     tmpList.Delete(i);
     ok := true;
    end else
   inc(i);
  until i >= tmpList.Count;
 until not ok;
 tmpList.SaveToFile(st1);
 tmpList.Destroy;
 stype := 0;
end;

Procedure TVars.sysSaveFile(inStr : String; Var stype : Byte);
Var
 tmpList : TStringList;
 st1,st2,st3,st4 : string;
 i,j,k,l,m : integer;
 uByte : Byte;
 ok : Boolean;
 tempStream : TMemoryStream;
begin
 if VarsCount = 0 then begin stype := 255; exit; end;
 ok := false;
 for i := 0 to VarsCount - 1 do
  begin
   ok := Uppercase(inStr) = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 if not ok then begin stype := 255; exit; end;
 if not (VarList[i].sType in [4,5,6]) then begin stype := 255; exit; end;
 tmpList := TStringList.Create;
 case VarList[i].sType of
  4 : begin

      end;
  5 : begin

      end;
  6 : begin
       case VarList[i].Dimension of
        1 : begin
             for j := 0 to VarList[i].DLength - 1 do
              begin
               st2 := VarList[i].StrArray[j];
               if st2[1] = '"' then delete(st2,1,1);
               if st2[length(st2)] = '"' then delete(st2,length(st2),1);
               st2 := StringToDoubleLength(st2);
               tmpList.Add(st2);
              end;
            end;
        2 : begin
             st1 := VarList[i].DimensionCount;
             j := StrToInt(GetHeadString(st1,','));
             k := StrToInt(GetHeadString(st1,','));
             uByte := 6;
             for l := 0 to k-1 do
              begin
               st2 := '';
               for m := 0 to j-1 do
                begin
                 st4 := inStr + '[' + IntTOStr(m) + ',' + IntToStr(l) + ']';
                 st3 := GetValue(st4,uByte);
                 if st3[1] = '"' then delete(st3,1,1);
                 if st3[length(st3)] = '"' then delete(st3,length(st3),1);
                 st2 := st2 + st3 + '`';
                end;
               st2 := StringToDoubleLength(st2);
               tmpList.Add(st2);
              end;
            end;
       end;
      end;
 end;
 //st1 := ExtractFilePath(application.ExeName);
 {
  notice must get the app's path here...
 }
 st1 := st1 + 'system\tryshell.shl';
 tmpList.SaveToFile(st1);
 tmpList.Destroy;
 stype := 0;
end;

Procedure TVars.ExtraLoadFromFile(inStr, filename : String; Var stype : Byte);
Var
 tmpList : TStringList;
 st1,st2,st3 : string;
 i,j,l,m : integer;
 uByte : Byte;
 ok : Boolean;
 tempStream : TMemoryStream;
begin
 if VarsCount = 0 then begin stype := 255; exit; end;
 ok := false;
 for i := 0 to VarsCount - 1 do
  begin
   ok := Uppercase(inStr) = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 if not ok then begin stype := 255; exit; end;
 if (VarList[i].sType in [4,5,6]) then
  begin
   tmpList := TStringList.Create;
   {
   notice must get the app's path here...
   }
   //st1 := ExtractFilePath(application.ExeName);
   st1 := st1 + 'data\';
   filename := st1 + filename;
   tmpList.LoadFromFile(filename);
   case VarList[i].sType of
    4 : begin
         j := tmpList.Count;
         st1 := tmpList.Strings[0];
         st1 := trim(st1);
         l := 0;
         while st1 <> '' do
          begin
           GetHeadString(st1,'`');
           trim(st1);
           inc(l);
          end;
//         k := VarList[i].Dimension;
         if l > 1 then
          begin
           VarList[i].DimensionCount := inttoStr(l)+','+InttoStr(j)+',';
           VarList[i].Dimension := 2;
          end else
          begin
           VarList[i].DimensionCount := InttoStr(j)+',';
           VarList[i].Dimension := 1;
          end;
         VarList[i].DLength := l*j;
         Finalize(VarList[i].IntArray);
         VarList[i].IntArray := Nil;
         setLength(VarList[i].IntArray,VarList[i].Dlength);
         for m := 0 to j -1 do
          begin
           st1 := tmpList.Strings[m];
           l := 0;
           while st1 <> '' do
            begin
             st2 := GetHeadString(st1,'`');
             if VarList[i].Dimension = 2 then
              st3 := inStr + '['+IntToStr(l)+','+IntToStr(m)+']' else
              st3 := inStr + '['+IntToStr(m)+']';
             uByte := 4;
             setValue(st3,st2,uByte);
             trim(st1);
             inc(l);
            end;
          end;
        end;
    5 : begin
         j := tmpList.Count;
         st1 := tmpList.Strings[0];
         st1 := trim(st1);
         l := 0;
         while st1 <> '' do
          begin
           GetHeadString(st1,'`');
           trim(st1);
           inc(l);
          end;
//         k := VarList[i].Dimension;
         if l > 1 then
          begin
           VarList[i].DimensionCount := inttoStr(l)+','+InttoStr(j)+',';
           VarList[i].Dimension := 2;
          end else
          begin
           VarList[i].DimensionCount := InttoStr(j)+',';
           VarList[i].Dimension := 1;
          end;
         VarList[i].DLength := l*j;
         Finalize(VarList[i].RealArray);
         VarList[i].RealArray := Nil;
         setLength(VarList[i].RealArray,l*j);
         for m := 0 to j -1 do
          begin
           st1 := tmpList.Strings[m];
           l := 0;
           while st1 <> '' do
            begin
             st2 := GetHeadString(st1,'`');
             if VarList[i].Dimension = 2 then
              st3 := inStr + '['+IntToStr(l)+','+IntToStr(m)+']' else
              st3 := inStr + '['+IntToStr(m)+']';
             uByte := 5;
             setValue(st3,st2,uByte);
             trim(st1);
             inc(l);
            end;
          end;
        end;
    6 : begin
         j := tmpList.Count;
         st1 := tmpList.Strings[0];
         st1 := trim(st1);
         l := 0;
         while st1 <> '' do
          begin
           GetHeadString(st1,'`');
           trim(st1);
           inc(l);
          end;
//         k := VarList[i].Dimension;
         if l > 1 then
          begin
           VarList[i].DimensionCount := inttoStr(l)+','+InttoStr(j)+',';
           VarList[i].Dimension := 2;
          end else
          begin
           VarList[i].DimensionCount := InttoStr(j)+',';
           VarList[i].Dimension := 1;
          end;
         VarList[i].DLength := l*j;
         Finalize(VarList[i].StrArray);
         VarList[i].StrArray := Nil;
         setLength(VarList[i].StrArray,l*j);
         for m := 0 to j -1 do
          begin
           st1 := tmpList.Strings[m];
           l := 0;
           while st1 <> '' do
            begin
             st2 := GetHeadString(st1,'`');
             st2 := '"'+st2+'"';
             if VarList[i].Dimension = 2 then
              st3 := inStr + '['+IntToStr(l)+','+IntToStr(m)+']' else
              st3 := inStr + '['+IntToStr(m)+']';
             uByte := 6;
             setValue(st3,st2,uByte);
             trim(st1);
             inc(l);
            end;
          end;
        end;
   end;
   tmpList.free;
   stype := 0;
  end else
  begin
   stype := 255;
  end;
end;

Procedure TVars.ExtraSaveTOFile(inStr, filename : String; Var stype : Byte);
Var
 tmpList : TStringList;
 st1,st2,st3,st4 : string;
 i,j,k,l,m : integer;
 uByte : Byte;
 ok : Boolean;
 tempStream : TMemoryStream;
begin
 if VarsCount = 0 then begin stype := 255; exit; end;
 ok := false;
 for i := 0 to VarsCount - 1 do
  begin
   ok := Uppercase(inStr) = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 if not ok then begin stype := 255; exit; end;
 if not (VarList[i].sType in [4,5,6]) then begin stype := 255; exit; end;
 tmpList := TStringList.Create;
 case VarList[i].sType of
  4 : begin
       case VarList[i].Dimension of
        1 : begin
             for j := 0 to VarList[i].DLength - 1 do
              tmpList.Add(IntToStr(VarList[i].IntArray[j])+'`');
            end;
        2 : begin
             st1 := VarList[i].DimensionCount;
             j := StrToInt(GetHeadString(st1,','));
             k := StrToInt(GetHeadString(st1,','));
             uByte := 4;
             for l := 0 to k-1 do
              begin
               st2 := '';
               for m := 0 to j-1 do
                begin
                 st4 := inStr + '[' + IntTOStr(m) + ',' + IntToStr(l) + ']';
                 st3 := GetValue(st4,uByte);
                 st2 := st2 + st3 + '`';
                end;
               tmpList.Add(st2);
              end;
            end;
       end;
      end;
  5 : begin
       case VarList[i].Dimension of
        1 : begin
             for j := 0 to VarList[i].DLength - 1 do
              tmpList.Add(FloatToStr(VarList[i].RealArray[j])+'`');
            end;
        2 : begin
             st1 := VarList[i].DimensionCount;
             j := StrToInt(GetHeadString(st1,','));
             k := StrToInt(GetHeadString(st1,','));
             uByte := 5;
             for l := 0 to k-1 do
              begin
               st2 := '';
               for m := 0 to j-1 do
                begin
                 st4 := inStr + '[' + IntTOStr(m) + ',' + IntToStr(l) + ']';
                 st3 := GetValue(st4,uByte);
                 st2 := st2 + st3 + '`';
                end;
               tmpList.Add(st2);
              end;
            end;
       end;
      end;
  6 : begin
       case VarList[i].Dimension of
        1 : begin
             for j := 0 to VarList[i].DLength - 1 do
              begin
               st2 := VarList[i].StrArray[j];
               if st2 = '' then st2 := '""';
               if st2[1] = '"' then delete(st2,1,1);
               if st2[length(st2)] = '"' then delete(st2,length(st2),1);
               tmpList.Add(st2+'`');
              end;
            end;
        2 : begin
             st1 := VarList[i].DimensionCount;
             j := StrToInt(GetHeadString(st1,','));
             k := StrToInt(GetHeadString(st1,','));
             uByte := 6;
             for l := 0 to k-1 do
              begin
               st2 := '';
               for m := 0 to j-1 do
                begin
                 st4 := inStr + '[' + IntTOStr(m) + ',' + IntToStr(l) + ']';
                 st3 := GetValue(st4,uByte);
                 if st3[1] = '"' then delete(st3,1,1);
                 if st3[length(st3)] = '"' then delete(st3,length(st3),1);
                 st2 := st2 + st3 + '`';
                end;
               tmpList.Add(st2);
              end;
            end;
       end;
      end;
 end;
 //st1 := ExtractFilePath(application.ExeName);
 {
  notice must get the app's path here
 }
 st1 := st1 + 'data\';
 filename := st1 + filename;
 tmpList.SaveToFile(filename);
 tmpList.Destroy;
 stype := 0;
end;

Function TVars.ArrayX(inStr : String) : integer;
Var
 st1,st2 : string;
 i : integer;
 ok : Boolean;
begin
 if VarsCount = 0 then begin result := -1; exit; end;
 ok := false;
 for i := 0 to VarsCount - 1 do
  begin
   ok := Uppercase(inStr) = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 if not ok then begin result := -1; exit; end;
 if not (VarList[i].sType in [4,5,6]) then begin result := -1; exit; end;
 st1 := VarList[i].DimensionCount;
 st2 := GetHeadString(st1,',');
 result := StrToInt(st2);
end;

Function TVars.ArrayY(inStr : String) : integer;
Var
 st1,st2 : string;
 i : integer;
 ok : Boolean;
begin
 if VarsCount = 0 then begin result := -1; exit; end;
 ok := false;
 for i := 0 to VarsCount - 1 do
  begin
   ok := Uppercase(inStr) = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 if not ok then begin result := -1; exit; end;
 if not (VarList[i].sType in [4,5,6]) then begin result := -1; exit; end;
 st1 := VarList[i].DimensionCount;
 st2 := GetHeadString(st1,',');
 st1 := trim(st1);
 if Pos(',',st1) <> 0 then
  begin
   st2 := GetHeadString(st1,',');
   result := StrToInt(st2);
  end else
   result := -1;
end;

Function TVars._isVar(inStr : String) : Boolean;
Var
 i : integer;
 tmpStr : String;
 ok : Boolean;
begin
 if Pos('[',inStr) <> 0 then
  begin
   tmpStr := trim(GetHeadString(inStr,'['));
  end else
  tmpStr := inStr;
 ok := false;
 for i := 0 to VarsCount - 1 do
  begin
   ok := Uppercase(tmpStr) = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 result := ok;
end;

Function TVars.GetValue(inStr : String; Var stype : Byte) : String;
Var
 i : integer;
 tmpStr : String;
 OStr : String;
 ok : Boolean;
 subIndex : Boolean;
 indexCount : String;
 ts3 : string;
 j,m,n,o,p : integer;
 t1 : String;
 uByte : Byte;
 xuStr : String;
 Cur_Pos : TPoint;
begin
 if inStr = '' then
  begin
   stype := 255;
   result := '';
   exit;
  end;
 if inStr[1] = '@' then
  begin
   delete(inStr,1,1);
   if Pos('.',inStr) <> 0 then
    begin
     xuStr := GetHeadString(inStr,'.');
     xuStr := GetValue(xuStr,uByte);
     if xuStr = '' then
      begin
       sType := 255;
       exit;
      end;
     if xuStr[1] = '"' then
      begin
       delete(xuStr,1,1);
       delete(xuStr,length(xuStr),1);
      end;
     inStr := xuStr+'.'+inStr;
    end else
   inStr := GetValue(inStr,uByte);
   if inStr[1] = '"' then delete(inStr,1,1);
   if inStr[Length(inStr)] = '"' then delete(inStr,length(inStr),1);
  end;
 Ostr := inStr;
 subIndex := false;
 if Pos('[',inStr) <> 0 then
  begin
   tmpStr := trim(GetHeadString(inStr,'['));
   indexCount := trim(GetHeadString(inStr,']'));
   indexCount := indexCount + ',';
   subIndex := True;
  end else
  tmpStr := inStr;
 tmpStr := Uppercase(tmpStr);
 if tmpStr = 'SCREENWIDTH' then
  begin
   result := IntToStr(Screen.Width);
   stype := 2;
   exit;
  end else
 if tmpStr = 'SCREENHEIGHT' then
  begin
   result := IntToStr(Screen.Height);
   stype := 2;
   exit;
  end else
 {
  TBrushStyle = (bsSolid, bsClear, bsHorizontal, bsVertical,
    bsFDiagonal, bsBDiagonal, bsCross, bsDiagCross);
 }
 if tmpStr = 'BSSOLID' then
  begin
   result := '0';
   stype := 2;
   exit;
  end else
 if tmpStr = 'BSCLEAR' then
  begin
   result := '1';
   stype := 2;
   exit;
  end else
 if tmpStr = 'BSHORIZONTAL' then
  begin
   result := '2';
   stype := 2;
   exit;
  end else
 if tmpStr = 'BSVERTICAL' then
  begin
   result := '3';
   stype := 2;
   exit;
  end else
 if tmpStr = 'BSFDIAGONAL' then
  begin
   result := '4';
   stype := 2;
   exit;
  end else
 if tmpStr = 'BSBDIAGONAL' then
  begin
   result := '5';
   stype := 2;
   exit;
  end else
 if tmpStr = 'BSCROSS' then
  begin
   result := '6';
   stype := 2;
   exit;
  end else
 if tmpStr = 'BSDIAGCROSS' then
  begin
   result := '7';
   stype := 2;
   exit;
  end else
 if tmpStr = 'MB_ABORTRETRYIGNORE' then
  begin
   result := '2';
   stype := 2;
   exit;
  end else
 if tmpStr = 'MB_OK' then
  begin
   result := '0';
   stype := 2;
   exit;
  end else
 if tmpStr = 'MB_OKCANCEL' then
  begin
   result := '1';
   stype := 2;
   exit;
  end else
 if tmpStr = 'MB_RETRYCANCEL' then
  begin
   result := '5';
   stype := 2;
   exit;
  end else
 if tmpStr = 'MB_YESNO' then
  begin
   result := '4';
   stype := 2;
   exit;
  end else
 if tmpStr = 'MB_YESNOCANCEL' then
  begin
   result := '3';
   stype := 2;
   exit;
  end else
 if tmpStr = 'IDOK' then
  begin
   result := '1';
   stype := 2;
   exit;
  end else
 if tmpStr = 'IDCANCEL' then
  begin
   result := '2';
   stype := 2;
   exit;
  end else
 if tmpStr = 'IDABORT' then
  begin
   result := '3';
   stype := 2;
   exit;
  end else
 if tmpStr = 'IDRETRY' then
  begin
   result := '4';
   stype := 2;
   exit;
  end else
 if tmpStr = 'IDIGNORE' then
  begin
   result := '5';
   stype := 2;
   exit;
  end else
 if tmpStr = 'IDYES' then
  begin
   result := '6';
   stype := 2;
   exit;
  end else
 if tmpStr = 'IDNO' then
  begin
   result := '7';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRDEFAULT' then
  begin
   result := '0';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRNONE' then
  begin
   result := '1';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRARROW' then
  begin
   result := '2';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRCROSS' then
  begin
   result := '3';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRLBEAM' then
  begin
   result := '4';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRSIZENESW' then
  begin
   result := '6';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRSIZENS' then
  begin
   result := '7';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRSIZENWSE' then
  begin
   result := '8';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRSIZEWE' then
  begin
   result := '9';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRUPARROW' then
  begin
   result := '10';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRHOURGLASS' then
  begin
   result := '11';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRDRAG' then
  begin
   result := '12';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRNODROP' then
  begin
   result := '13';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRHSPLIT' then
  begin
   result := '14';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRVSPLIT' then
  begin
   result := '15';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRMULTIDRAG' then
  begin
   result := '16';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRSQLWAIT' then
  begin
   result := '17';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRNO' then
  begin
   result := '18';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRAPPSTART' then
  begin
   result := '19';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRHELP' then
  begin
   result := '20';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRHANDPOINT' then
  begin
   result := '21';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRSIZE' then
  begin
   result := '22';
   stype := 2;
   exit;
  end else
 if tmpStr = 'CRSIZEALL' then
  begin
   result := '22';
   stype := 2;
   exit;
  end else
 if tmpStr = 'LASTSTEP' then
  begin
   result := '-5';
   stype := 2;
   exit;
  end else
 if tmpStr = 'FIRSTSTEP' then
  begin
   result := '-4';
   stype := 2;
   exit;
  end else
 if tmpStr = 'PRESTEP' then
  begin
   result := '-2';
   stype := 2;
   exit;
  end else
 if tmpStr = 'NEXTSTEP' then
  begin
   result := '-3';
   stype := 2;
   exit;
  end;
 if tmpStr = 'NEXTTEN' then
  begin
   result := '-6';
   stype := 2;
   exit;
  end else
 if tmpStr = 'PRETEN' then
  begin
   result := '-7';
   stype := 2;
   exit;
  end else
 if tmpStr = 'MOUSEX' then
  begin
   GetCursorPos(Cur_Pos);
   result := IntToStr(Cur_Pos.X);
   stype := 2;
   exit;
  end else
 if tmpStr = 'MOUSEY' then
  begin
   GetCursorPos(Cur_Pos);
   result := IntToStr(Cur_Pos.Y);
   stype := 2;
   exit;
  end;
 ok := false;
 for i := 0 to VarsCount - 1 do
  begin
   ok := tmpStr = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 if not ok then
  begin
   //error;
//   showMessage(' not found the identifier...' + OStr);
//result: 0 for constant string... 1 for constant integer... 2 for constant real...
    //3 for vars... 4 for constant boolean...

   uByte := Varthings(tmpStr);
   if uByte <> 3 then
    begin
     result := tmpStr;
     stype := uByte;
    end else
    begin
     result := '';
     stype := 255;
    end;
   exit;
  end;
 case VarList[i].sType of
  0 : result := VarList[i].Value;
  1 : begin
       if not subIndex then result := VarList[i].Value else
       begin
        t1 := trim(GetHeadString(indexCount,','));
        if varthings(t1) = 1 then
         j := StrToInt(t1) else
         j := StrToInt(GetValue(t1,uByte));
        t1 := VarList[i].Value;
        delete(t1,1,1);
        result := '"'+t1[j]+'"';
       end;
      end;
  2 : result := VarList[i].Value;
  3 : result := VarList[i].Value;
  4,5,6
    : begin
       ts3 := VarList[i].DimensionCount;
       case VarList[i].Dimension of
        1 : begin
             t1 := trim(GetHeadString(indexCount,','));
             if varthings(t1) = 1 then
              j := StrToInt(t1) else
              j := StrToInt(GetValue(t1,uByte));
            end;
        2 : begin
             t1 := trim(GetHeadString(indexCount,','));
             if varthings(t1) = 1 then
              j := StrToInt(t1) else
              j := StrToInt(GetValue(t1,uByte));
             t1 := trim(GetHeadString(indexCount,','));
             if varthings(t1) = 1 then
              m := StrToInt(t1) else
              m := StrToInt(GetValue(t1,uByte));
             m := m*StrToInt(trim(GetHeadString(ts3,',')));
             j := j + m;
            end;
        3 : begin
             t1 := trim(GetHeadString(indexCount,','));
             if varthings(t1) = 1 then
              j := StrToInt(t1) else
              j := StrToInt(GetValue(t1,uByte));
             t1 := trim(GetHeadString(indexCount,','));
             if varthings(t1) = 1 then
              m := StrToInt(t1) else
              m := StrToInt(GetValue(t1,uByte));
             t1 := trim(GetHeadString(indexCount,','));
             if varthings(t1) = 1 then
              n := StrToInt(t1) else
              n := StrToInt(GetValue(t1,uByte));
             o := StrToInt(trim(GetHeadString(ts3,',')));
             p := strToInt(trim(GetHeadString(ts3,',')));
             m := m*o;
             n := n*p*o;
             j := n + m + j;
            end;
       end;

       if VarList[i].sType = 4 then
        result := IntToStr(VarList[i].IntArray[j]) else
       if VarList[i].sType = 5 then
        result := FloatToStr(VarList[i].RealArray[j]) else
        begin
         if Pos('[',inStr) <> 0 then
          begin
           GetHeadString(inStr,'[');
           indexCount := GetHeadString(inStr,']');
           indexCount := indexCount + ',';
           t1 := trim(GetHeadString(indexCount,','));
           if varthings(t1) = 1 then
            m := StrToInt(t1) else
            m := StrToInt(GetValue(t1,uByte));
           t1 := VarList[i].StrArray[j];
           delete(t1,1,1);
           result := '"'+t1[m]+'"';
          end else
          result := VarList[i].StrArray[j];
        end;
      end;
 end;
 stype := VarList[i].sType;
end;

Procedure TVars.SetValue(inStr : String; iValue : String; Var uType : Byte);
Var
 i : integer;
 tmpStr : String;
 OStr : String;
 ok : Boolean;
 subIndex : Boolean;
 indexCount : String;
 ts3 : string;
 j,m,n,o,p : integer;
 t1 : String;
 uByte : Byte;
 xuStr : String;
 tmpReal : real;
begin
 if inStr[1] = '@' then
  begin
   delete(inStr,1,1);
   if Pos('.',inStr) <> 0 then
    begin
     xuStr := GetHeadString(inStr,'.');
     xuStr := GetValue(xuStr,utype);
     if xuStr = '' then
      begin
       uType := 255;
       exit;
      end;
     if xuStr[1] = '"' then
      begin
       delete(xuStr,1,1);
       delete(xuStr,length(xuStr),1);
      end;
     inStr := xuStr+'.'+inStr;
    end else
   inStr := GetValue(inStr,utype);
   if inStr[1] = '"' then delete(inStr,1,1);
   if inStr[Length(inStr)] = '"' then delete(inStr,length(inStr),1);
  end;
 Ostr := inStr;
 subIndex := false;
 if Pos('[',inStr) <> 0 then
  begin
   tmpStr := trim(GetHeadString(inStr,'['));
   indexCount := trim(GetHeadString(inStr,']'));
   indexCount := indexCount + ',';
   subIndex := True;
  end else
  tmpStr := inStr;
 uType := 0;
 for i := 0 to VarsCount - 1 do
  begin
   ok := Uppercase(tmpStr) = Uppercase(VarList[i].Name);
   if ok then break;
  end;
 if not ok then
  begin
   //error;
//   showMessage(' not found the identifier...' + OStr);
   uType := 255;
//   result := '';
//   stype := 255;
   exit;
  end;
 case VarList[i].sType of
  0 : begin
       if varthings(iValue) = 4 then
        VarList[i].Value := iValue else
        VarList[i].Value := GetValue(iValue,uByte);
      end;
  1 : begin
       if not subIndex then
        begin
         if varthings(iValue) = 0 then
          VarList[i].Value := iValue else
          VarList[i].Value := GetValue(iValue,uByte);
        end else
        begin
         t1 := trim(GetHeadString(indexCount,','));
         if varthings(t1) = 1 then
          j := StrToInt(t1) else
          j := StrToInt(GetValue(t1,uByte));
         delete(VarList[i].Value,1,1);
         delete(VarList[i].Value,Length(VarList[i].Value),1);
         VarList[i].Value[j] := iValue[2];
         VarList[i].Value := '"' + VarList[i].Value + '"';
        end;
      end;
  2 : begin
       if varthings(iValue) = 1 then
        VarList[i].Value := iValue else
        VarList[i].Value := GetValue(iValue,uByte);
      end;
  3 : begin
       if varthings(iValue) <= 2 then
        VarList[i].Value := iValue else
        VarList[i].Value := GetValue(iValue,uByte);
      end;
  4,5,6
    : begin
       if not subIndex then
        begin
         if VarList[i].sType = 4 then
          begin
           if Varthings(iValue) = 1 then
            m := StrToInt(iValue) else
            m := StrToInt(GetValue(iValue,uByte));
           for j := 0 to VarList[i].DLength - 1 do
            VarList[i].IntArray[j] := m;
          end else
         if VarList[i].sType = 5 then
          begin
           if Varthings(iValue) <= 2 then
            tmpReal := StrToFloat(iValue) else
            tmpReal := StrToFloat(GetValue(iValue,uByte));
           for j := 0 to VarList[i].DLength - 1 do
            VarList[i].RealArray[j] := tmpReal;
          end else
          begin
           if Varthings(iValue) = 0 then
            xuStr := iValue else
            xuStr := GetValue(iValue,uByte);
           for j := 0 to VarList[i].DLength - 1 do
            VarList[i].StrArray[j] := xuStr;
          end;
         exit;
        end;

       ts3 := VarList[i].DimensionCount;
       case VarList[i].Dimension of
        1 : begin
             t1 := trim(GetHeadString(indexCount,','));
             if varthings(t1) = 1 then
              j := StrToInt(t1) else
              j := StrToInt(GetValue(t1,uByte));
            end;
        2 : begin
             t1 := trim(GetHeadString(indexCount,','));
             if varthings(t1) = 1 then
              j := StrToInt(t1) else
              j := StrToInt(GetValue(t1,uByte));
             t1 := trim(GetHeadString(indexCount,','));
             if varthings(t1) = 1 then
              m := StrToInt(t1) else
              m := StrToInt(GetValue(t1,uByte));
             m := m*StrToInt(trim(GetHeadString(ts3,',')));
             j := j + m;
            end;
        3 : begin
             t1 := trim(GetHeadString(indexCount,','));
             if varthings(t1) = 1 then
              j := StrToInt(t1) else
              j := StrToInt(GetValue(t1,uByte));
             t1 := trim(GetHeadString(indexCount,','));
             if varthings(t1) = 1 then
              m := StrToInt(t1) else
              m := StrToInt(GetValue(t1,uByte));
             t1 := trim(GetHeadString(indexCount,','));
             if varthings(t1) = 1 then
              n := StrToInt(t1) else
              n := StrToInt(GetValue(t1,uByte));
             o := StrToInt(trim(GetHeadString(ts3,',')));
             p := strToInt(trim(GetHeadString(ts3,',')));
             m := m*o;
             n := n*p*o;
             j := n + m + j;
            end;
       end;

       if VarList[i].sType = 4 then
        begin
         if varthings(iValue) = 1 then
          VarList[i].IntArray[j] := StrToInt(iValue) else
          VarList[i].IntArray[j] := StrToInt(GetValue(iValue,uByte));
        end else
       if VarList[i].sType = 5 then
        begin
         if varthings(iValue) <= 2 then
          VarList[i].RealArray[j] := StrToFloat(iValue) else
          VarList[i].RealArray[j] := StrToFloat(GetValue(iValue,uByte));
        end else
        begin
         if varthings(iValue) = 0 then
          VarList[i].StrArray[j] := iValue else
          VarList[i].StrArray[j] := GetValue(iValue,uByte);
        end;
      end;
 end;
end;

Function TVars.EmunVar(index : integer; Var vName : String) : integer;
begin
 if VarsCount = 0 then
  begin
   result := -1;
   exit;
  end;
 if index >= VarsCount then
  begin
   result := -1;
   exit;
  end;
 vName := VarList[index].Name;
 result := VarList[index].sType;
end;

Function TVars.VarOut(index : integer) : TVar;
begin
 result.Name := VarList[index].Name;
 result.Value := VarList[index].Value;
 result.DimensionCount := VarList[index].DimensionCount;
 result.DLength := VarList[index].DLength;
 result.Dimension := VarList[index].Dimension;
 result.sType := VarList[index].sType;
 case result.sType of
  4 : begin
       setlength(result.intArray,result.DLength);
      end;
  5 : begin
       setlength(result.realArray,result.DLength);
      end;
  6 : begin
       setLength(result.StrArray,result.DLength);
      end;
 end;
end;

Procedure TVars.AddVar(inVar : TVar);
begin
 inc(VarsCount);
 setLength(VarList,VarsCount);
 VarList[VarsCount-1].Name := inVar.Name;
 VarList[VarsCount-1].Value := inVar.Value;
 VarList[VarsCount-1].IntArray := inVar.IntArray;
 VarList[VarsCount-1].RealArray := inVar.RealArray;
 VarList[VarsCount-1].StrArray := inVar.StrArray;
 VarList[VarsCount-1].DLength := inVar.DLength;
 VarList[VarsCount-1].Dimension := inVar.Dimension;
 VarList[VarsCount-1].DimensionCount := inVar.DimensionCount;
 VarList[VarsCount-1].sType := inVar.sType;
end;

Constructor TScript.create;
 begin
  selfVar := TVars.create;
  indexVar := TVars.create;
  gIndex := TVars.create;
  selfExp := TExp.create;
  SelfExp.OnGetValue := RequestValue;
  selfStack := TStatusStack.create;
  PointNumber := 0;
 end;

Destructor TScript.destroy;
 begin
  selfVar.destroy;
  selfExp.destroy;
  indexVar.destroy;
  gIndex.destroy;
  inherited destroy;
 end;

Procedure TScript.setfeedIn(inStr : String);
 begin
  feedIn := inStr;
  selfVar.OnLoadStream := OnLoadStream;
  selfExp.OnFunctionCall := OnFunctionCall;
//  compile;
 end;

Function TScript.GetFeedIn : String;
 begin
  result := feedIn;
 end;

Function SearchWord(inStr : String; findStr : String) : integer;
Var
 i,j,k : integer;
 tmpStr : String;
begin
 findStr := Uppercase(findStr);
 tmpStr := Uppercase(inStr);
 k := 0;
 repeat
  i := Pos(findStr,tmpStr);
  if i = 0 then
   begin
    result := i;
    exit;
   end;
  j := i + length(findStr) - 1;
  if j = Length(tmpStr) then
   begin
    result := k + i;
    exit;
   end;
  if not (tmpStr[j+1] in ['a'..'z','A'..'Z','0'..'9','_']) then
   begin
    result := k + i;
    exit;
   end;
  delete(tmpStr,1,j);
  k := k + j;
 until (tmpStr = '') or (i = 0);
 result := 0;
end;

Function SearchKeyWord(inStr : String; findStr : String) : integer;
Var
 i,j,k : integer;
 tmpStr : String;
 xtmpStr : string;
 l,m : integer;
begin
 findStr := Uppercase(findStr);
 tmpStr := Uppercase(inStr);
 k := 0;
 repeat
  i := Pos(findStr,tmpStr);
  if i = 0 then
   begin
    result := i;
    exit;
   end;
  l := Pos('"',tmpStr);
  if (l = 0) or (l > i) then
   begin
    j := i + length(findStr) - 1;
    if j = Length(tmpStr) then
     begin
      if not (tmpStr[i-1] in ['a'..'z','A'..'Z','0'..'9','_']) then
       result := k + i
      else
       result := 0;
      exit;
     end;
    if (not (tmpStr[j+1] in ['a'..'z','A'..'Z','0'..'9','_'])) and
       (not (tmpStr[i-1] in ['a'..'z','A'..'Z','0'..'9','_'])) then
     begin
      result := k + i;
      exit;
     end;
    delete(tmpStr,1,j);
    k := k + j;
   end else
   begin
    xtmpStr := tmpStr;
    xtmpStr[l] := '*';
    m := Pos('"',xtmpStr);
    if (m = 0) or (m < i) then
     begin
      j := i + length(findStr) - 1;
      if j = Length(tmpStr) then
       begin
        if not (tmpStr[i-1] in ['a'..'z','A'..'Z','0'..'9','_']) then
         result := k + i
        else
         result := 0;
        exit;
       end;
      if (not (tmpStr[j+1] in ['a'..'z','A'..'Z','0'..'9','_'])) and
         (not (tmpStr[i-1] in ['a'..'z','A'..'Z','0'..'9','_'])) then
       begin
        result := k + i;
        exit;
       end;
      delete(tmpStr,1,j);
      k := k + j;
     end else
     begin
      delete(tmpStr,1,m);
      k := k + m;
     end;
   end;
 until (tmpStr = '') or (i = 0);
 result := 0;
end;

Procedure  Search_and_Replace(Var inStr : String; findText,replaceText : String);
Var
 tmp1 : String;
 i : integer;
begin
 repeat
  i := searchWord(inStr,findText);
  if i <> 0 then
   begin
    tmp1 := copy(inStr,1,i-1);
    delete(inStr,1,i-1);
    delete(inStr,1,length(findText));
    inStr := tmp1 + replaceText + inStr;
   end;
 until i = 0;
end;

Procedure TScript.Replace_ExecStream(oStr,rStr : String);
Var
 i : integer;
 str1 : string;
begin
 if PointNumber = 0 then exit;
 for i := 0 to PointNumber-1 do
  begin
   str1 := ExecStream[i].left;
   if str1 <> '' then
    begin
     search_and_replace(str1,oStr,rStr);
     ExecStream[i].left := str1;
    end;
   str1 := ExecStream[i].right;
   if str1 <> '' then
    begin
     search_and_replace(str1,oStr,rStr);
     ExecStream[i].right := str1;
    end;
  end;
end;

Function TScript.ScriptL(Var sName, vIndex : string; Var scType : Byte) : integer;
begin
 sName := ScriptName;
 vIndex := VarIndex;
 scType := ScriptType;
 result := PointNumber;
end;

Function TScript.OutExecPoint(index : Integer) : ExecPoint;
begin
 if PointNumber = 0 then
  begin
   result.Command := 255;
   exit;
  end;
 if index >= PointNumber then
  begin
   result.Command := 255;
   exit;
  end;
 if index < PointNumber then
  begin
   result.Command := ExecStream[index].Command;
   result.C1 := ExecStream[index].C1;
   result.C2 := ExecStream[index].C2;
   result.left := ExecStream[index].left;
   result.right := ExecStream[index].right;
  end;
end;

Procedure TScript.AddExecPoint(inExecPoint : ExecPoint);
begin
 if inExecPoint.Command = 255 then
  begin
   exit;
  end;
 inc(PointNumber);
 setLength(ExecStream,PointNumber);
 ExecStream[PointNumber-1].Command := inExecPoint.Command;
 ExecStream[PointNumber-1].C1 := inExecPoint.C1;
 ExecStream[PointNumber-1].C2 := inExecPoint.C2;
 ExecStream[PointNumber-1].left := inExecPoint.left;
 ExecStream[PointNumber-1].right := inExecPoint.right;
end;

Function is__Assign(inStr : String) : Boolean;
Var
 i,j,k : integer;
begin
 if Pos(':=',inStr) = 0 then
  begin
   result := false;
   exit;
  end;
 if (Pos(':=',inStr) <> 0) and (Pos('"',inStr) = 0) then
  begin
   result := true;
   exit;
  end;
 i := Pos(':=',inStr);
 j := Pos('"',inStr);
 inStr[j] := ' ';
 k := Pos('"',inStr);
 if k = 0 then
  begin
   // jinsong showmessage('error! the " is not equilvent');
   result := false;
   exit;
  end;
 if i < j then
  begin
   result := true;
   exit;
  end;
end;

Function SentenceType(inStr : String) : Integer;
begin
 if is__Assign(inStr) then
  begin
   result := 0;
   exit;
  end;
end;

Function FirstWord(Var inStr : String) : String;
Var
 tmpStr : String;
 i,j : integer;
begin
 if Pos('"',inStr) = 1 then
  begin
   tmpStr := '"';
   delete(inStr,1,1);
   tmpStr := tmpStr + GetHeadString(inStr,'"') + '"';
   result := tmpStr;
   exit;
  end;
 tmpStr := '';
 while ((inStr <> '') and (inStr[1] in ['a'..'z','A'..'Z','0'..'9','_'])) do
  begin
   tmpStr := tmpStr + inStr[1];
   delete(inStr,1,1);
  end;
 if inStr <> '' then delete(inStr,1,1);
 if tmpStr <> '' then
  result := tmpStr else
  result := '';
end;

Procedure TScript.TreateVarBlock(inStr : String);
var
 t1,t2,t3 : string;
 m,i,j,k : integer;
 YesStr,NStr : String;
 part1 : string;
begin
    YesStr := inStr;
    if Pos(';',YesStr) = 0 then
     begin
      // jinsong showmessage('no var defined!, no :');
      exit;
     end else
     begin
      NStr := '';
      repeat
       t1 := GetHeadString(YesStr,#127);
       t1 := trim(t1);
       if Pos('//',t1) <> 0 then
       delete(t1,Pos('//',t1),length(t1)); //delete all comment things...
       if t1 = '' then begin end else
        begin
         NStr := NStr + t1;
        end;
      until Pos(#127,YesStr) = 0;  //above part delete all linefeed char...
      if YesStr <> '' then NStr := NStr + YesStr;
      while NStr <> '' do
       begin
        t1 := GetHeadString(YesStr,';');
        t1 := trim(t1);
        part1 := GetHeadString(t1,':');
        if part1 = '' then
         begin
          // jinsong showmessage('no :, can not understand it...'+t1);
          exit;
         end;
        t1 := Uppercase(t1);
        if Pos('ARRAY[',t1) <> 0 then
         begin
          if Pos(' INTEGER',t1) <> 0 then
           m := 4 else
          if Pos(' REAL',t1) <> 0 then
           m := 5 else
          if Pos(' STRING',t1) <> 0 then
           m := 6;
          GetHeadString(t1,'[');
          t2 := GetHeadString(t1,']');
          t2 := '['+t2+']';
         end else
         begin
          if Pos('BOOLEAN',t1) <> 0 then
           m := 0 else
          if Pos('STRING',t1) <> 0 then
           m := 1 else
          if Pos('INTEGER',t1) <> 0 then
           m := 2 else
          if Pos('REAL',t1) <> 0 then
           m := 3;
         end;
        part1 := part1 + ',';
        while part1 <> '' do
         begin
          t3 := GetHeadString(part1,',');
          if m > 3 then
           selfVar.DefineVar(t3+t2,m) else
           selfVar.DefineVar(t3,m);
         end;
       end;
     end;
end;

Procedure TScript.compile;
 Var
  t1,t2,t3 : string;
  tmpStr : string;
  Fword : String;
  i,j,k : integer;
  m,n,o,p : integer;
  YesStr : String;
  NStr : String;
  part1,part2 : String;
  tmpPoint : ExecPoint;
 begin
  tmpStr := feedIn;
  if tmpStr = '' then
   exit;
  t1 := '';
  while (t1 = '') and (tmpStr <> '') do
   begin
    t1 := GetHeadString(tmpStr,#127);
    t1 := trim(t1);
    if Pos('//',t1) <> 0 then
     delete(t1,Pos('//',t1),length(t1)); //delete all comment things...
   end;
  if tmpStr = '' then
   begin
    // jinsong showmessage('nothing can be compiled!');
    exit;
   end;

  FWord := FirstWord(t1);

  FWord := Uppercase(FWord);
  if FWord = 'VAR' then
   begin
    ScriptType := 0;
    if t1 <> '' then
     tmpStr := t1 + #127 + tmpStr;
    i := SearchWord(tmpStr,'begin');
    if i = 0 then
     begin
      // jinsong showmessage('no program block after key word VAR');
      exit;
     end;                    //get the var block to 'BEGIN'...
                             // and then treate this block seperatly...
    YesStr := Copy(tmpStr,1,i-1);
    delete(tmpStr,1,i-1);
    TreateVarBlock(YesStr);
    delete(tmpStr,1,length('begin'));
   end else
  if FWord = 'FUNCTION' then
   begin
   end else
  if FWord = 'PROCEDURE' then
   begin
   end else
  if FWord = 'BEGIN' then
   begin
    if t1 <> '' then
     tmpStr := t1 + #127 + tmpStr;
    ScriptType := 0;
   end else
   begin
    // jinsong showmessage('can not understand the indentifier!'+fword);
    exit;
   end;

// then, the tmpstr should have no _VAR Part_, if in normal condition,
// it should be ...
// begin
//  code block...
// end.
// so should get the begin...

  (*ExecPoint = record
   Command : Byte;  //0 : normal assign, that means assign right to left...
                    //1 : condition, if right is true goto c1, if false goto c2...
                    //2 : Null point, such as repeat cause it...
                    //3 : routine call such as movie5.startaction, etc...
                    //4 : jump, jump to c1 directly, the if then else can cause it...
   C1,C2 : integer;
   left : string;
   right : String;
  end;*)

   t1 := '';
   while (t1 = '') and (tmpStr <> '') do
    begin
     t1 := GetHeadString(tmpStr,#127);
     t1 := trim(t1);
     if Pos('//',t1) <> 0 then
      delete(t1,Pos('//',t1),length(t1)); //delete all comment things...
    end;
   while Pos(';',t1) <> 0 do
    begin
     t2 := GetHeadString(t1,';');
     if t2 <> '' then
      begin
       if is__assign(t2) then
        begin
        end else
        begin
         FWord := FirstWord(t2);

        end;
      end;
    end;

  while tmpStr <> '' do
   begin
    t1 := GetHeadString(tmpStr,#127);
    if Pos('//',t1) <> 0 then
     delete(t1,Pos('//',t1),length(t1)); //delete all comment things...
    t1 := trim(t1);
    while Pos(';',t1) <> 0 do
     begin
      t2 := GetHeadString(t1,';');
      if is__Assign(t2) then
       begin

       end else
       begin
        t2 := trim(t2);
        FWord := FirstWord(t2);
        if Uppercase(FWord) = 'VAR' then
         begin
         end else
         begin
         end;
       end;
     end;
   end;
 end;


Procedure TScript.compile_2;
Const
 BaseState = 1000;
 Blank     = BaseState + 0;
 is_Number = BaseState + 1;
 is_e_Number = BaseState + 2;
 is_Point_Number = BaseState + 3;
 is_e_Point_Number = BaseState + 4;
 Identifier = BaseState + 5;
 Point_Identifier = BaseState + 6;
 is_left_mI = BaseState + 7;
 is_right_mI = BaseState + 8;
 is_left_SQ = BaseState + 9;
 is_right_SQ = BaseState + 10;
 is_slash = BaseState + 11;
 is_13 = BaseState + 12;
 is_10 = BaseState + 13;
 is_127 = BaseState + 14;
 is_Space = BaseState + 15;
 is_Operator = BaseState + 16;
 is_at = BaseState + 17;
 is_suggest = BaseState + 18;
 is_equal = BaseState + 19;
 is_cut = BaseState + 20;
 is_plus = BaseState + 21;
 is_minus = BaseState + 22;
 is_multi = BaseState + 23;
 is_large = BaseState + 24;
 is_small = BaseState + 25;
 is_left_comment = BaseState + 26;
 is_right_comment = BaseState + 27;
 is_comma = BaseState + 28;
 is_Assign = BaseState + 29;
 is_Cword = BaseState + 100;

Const
 ReservedBase = 10000;
 is_Null = ReservedBase + 0;
 is_Program =  ReservedBase + 1;
 is_Var = ReservedBase + 2;
 is_Begin = ReservedBase + 3;
 is_End = ReservedBase + 4;
 is_if = ReservedBase + 5;
 is_then = ReservedBase + 6;
 is_else = ReservedBase + 7;
 is_repeat = ReservedBase + 8;
 is_until = ReservedBase + 9;
 is_for = ReservedBase + 10;
 is_to = ReservedBase + 11;
 is_downto = ReservedBase + 12;
 is_while = ReservedBase + 13;
 is_do = ReservedBase + 14;
 is_procedure = ReservedBase + 15;
 is_Function = ReservedBase + 16;
 is_integer = ReservedBase + 17;
 is_Boolean = ReservedBase + 18;
 is_String = ReservedBase + 19;
 is_Real = ReservedBase + 20;
 is_Array = ReservedBase + 21;
 is_Error = ReservedBase + 200;
 is_OK    = ReservedBase + 300;

Var
 tmpStr : String;
 CurrentPos : integer;
 CurrentToken : String;
 CurrentStatement  : String;
 CurrentState : integer;
 ReserveState : integer;
 Array_Open : Boolean;
 Comment_Open : Boolean;
 Comment_mI_Open : Boolean;
 Comment_Line_Open : Boolean;
 m_include_Open : Boolean;
 ErrorNo : integer;
 tkS     : String;
 tmps1,tmps2,tmps3 : string;
 Yes     : Boolean;
 ti1,ti5 : Byte;
 ti2,ti3,ti4 : integer;
 begin_end_count : integer;

 SingleLine : Boolean;

 Procedure ReadByte;
  Var
   tC : Char;
   debugStr : String;
  begin
   tC := tmpStr[CurrentPos];
   case tC of
    'a'..'z','A'..'Z','_'
      : begin
         case CurrentState of
          Blank : Begin
                   CurrentToken := CurrentToken + tC;
                   CurrentState := Identifier;
                  end;
          is_Number : begin
                       if (tc in ['e','E']) then
                        begin
                         CurrentToken := CurrentToken + tC;
                         CurrentState := is_e_Number;
                        end else
                        begin
                         // jinsong showMessage('wrong number leading identifier...');
                         ErrorNo := 1;
                         debugStr := Copy(tmpStr,CurrentPos,Length(tmpStr));
                         showMessage(debugStr);
                         showMessage(tmpStr);
                         exit;
                        end;
                      end;
          is_Point_Number : begin
                             if (tc in ['e','E']) then
                              begin
                               CurrentToken := CurrentToken + tC;
                               CurrentState := is_e_Point_Number;
                              end else
                               begin
                                // jinsong showMessage('wrong number leading identifier...');
                                ErrorNo := 2;
                                exit;
                              end;
                            end;
          is_e_Point_Number : begin
                                // jinsong showMessage('is_Point_e_Number:wrong number leading identifier...');
                                ErrorNo := 3;
                                exit;
                              end;
          identifier : begin
                        CurrentToken := CurrentToken + tC;
                        CurrentState := Identifier;
                       end;
          is_at      : begin
                        CurrentToken := CurrentToken + tC;
                        CurrentState := Identifier;
                       end;
          Point_identifier : begin
                              CurrentToken := CurrentToken + tC;
                              CurrentState := Identifier;
                             end;
          is_e_Number : begin
                         // jinsong showMessage('wrong number leading identifier...');
                         ErrorNo := 4;
                         exit;
                        end;
         end;
        end;
    '.' :
        begin
         case CurrentState of
          Blank : Begin
                   // jinsong showMessage('Can not understand the . leading');
                   ErrorNo := 5;
                   exit;
                  end;
          is_Number : begin
                         CurrentToken := CurrentToken + tC;
                         CurrentState := is_Point_Number;
                      end;
          is_e_Number : begin
                         // jinsong showMessage('can not use real power, is_e_number');
                         ErrorNo := 6;
                         exit;
                        end;
          is_Point_Number : begin
                             // jinsong showMessage('Point Number already...');
                             ErrorNo := 7;
                             exit;
                            end;
          is_e_Point_Number : begin
                               // jinsong showMessage('e Point Number already...');
                               ErrorNo := 8;
                               exit;
                              end;
          identifier : begin
                        CurrentToken := CurrentToken + tC;
                        CurrentState := Point_Identifier;
                       end;
          Point_identifier : begin
                              // jinsong showMessage('Point identifier already...');
                              ErrorNo := 9;
                              exit;
                             end;
         end;
        end;
    '0'..'9' :
        begin
         case CurrentState of
          Blank : Begin
                   CurrentToken := CurrentToken + tC;
                   CurrentState := is_Number;
                  end;
          is_Number : begin
                         CurrentToken := CurrentToken + tC;
                      end;
          is_e_Number : begin
                         CurrentToken := CurrentToken + tC;
                        end;
          is_Point_Number : begin
                             CurrentToken := CurrentToken + tC;
                            end;
          is_e_Point_Number : begin
                               CurrentToken := CurrentToken + tC;
                              end;
          identifier : begin
                        CurrentToken := CurrentToken + tC;
                       end;
          Point_identifier : begin
                              // jinsong showMessage('can not use number directly by the point');
                              ErrorNo := 10;
                              exit;
                             end;
         end;
        end;
    '(' : begin
           CurrentToken := CurrentToken + tC;
           CurrentState := is_left_mI;
          end;
    ')' : begin
           CurrentToken := CurrentToken + tC;
           CurrentState := is_right_mI;
          end;
    '[' : begin
           if (CurrentState = identifier) or (CurrentState = Blank) then
            begin
             CurrentToken := CurrentToken + tC;
             CurrentState := is_left_SQ;
            end else
            begin
             // jinsong showMessage('wrong place of [');
             ErrorNo := 12;
             exit;
            end;
          end;
    ']' : begin
           CurrentToken := CurrentToken + tC;
           CurrentState := is_right_SQ;
          end;
    #13 : begin
           CurrentState := is_13;
          end;
    #10 : begin
           CurrentState := is_10;
          end;
   #127 : begin
           CurrentState := is_127;
          end;
    ';' : begin
           CurrentState := is_Cut;
          end;
//    '"' : begin
//           CurrentState := is_Quota;
//          end;
    '=' : begin
//           CurrentToken := CurrentToken + tC;
           CurrentState := is_equal;
          end;
    ':' : begin
//           CurrentToken := CurrentToken + tC;
           CurrentState := is_suggest;
          end;
    '{' : begin
           CurrentState := is_left_comment;
          end;
    '}' : begin
           CurrentState := is_right_comment;
          end;
    '@' : begin
           CurrentState := is_at;
          end;
    '+' : begin
           CurrentState := is_Plus;
          end;
    '-' : begin
           CurrentState := is_minus;
          end;
    '*' : begin
           CurrentState := is_Multi;
          end;
    '/' : begin
           CurrentState := is_slash;
          end;
    ' ' : begin
           CurrentState := is_Space;
          end;
    ',' : begin
           CurrentState := is_Comma;
          end;
   end;
   inc(CurrentPos);
  end;

 Procedure ReadToken;
  Var
   ok : Boolean;
   PreState : integer;
  begin
   ErrorNo := 0;
   if CurrentPos >= Length(tmpStr) then exit;
   ok := false;
   CurrentToken := '';
   PreState := Blank;
   repeat
    ReadByte;
    if ErrorNo <> 0 then exit;
    case currentstate of
     identifier, Point_identifier : begin
                                      PreState := Currentstate;
                                    end;
     is_Comma : begin
                 if PreState = identifier then
                  begin
                   CurrentStatement := CurrentToken;
                   CurrentState := is_CWord;
                   OK := True;
                  end else
                 if (PreState = Blank) or (PreState = is_Space) or
                    (PreState = is_10) or (PreState = is_13) or
                    (PreState = is_Cut) then
                 begin
                  CurrentStatement := '';
                  CurrentToken := '';
                  CurrentState := is_CWord;
                  ok := True;
                 end else
                 begin
                  ErrorNo := 102;
                  CurrentStatement := CurrentToken;
                  // jinsong showmessage('unkown identifier before comma');
                  exit;
                 end;
                end;
     is_Space, is_10, is_13, is_Cut, is_127
              : begin
                 if (PreState = identifier) or (PreState = Point_identifier) then
                  begin
                   CurrentStatement := CurrentToken;
                   CurrentState := is_CWord;
                   ok := true;
                  end else
                 if (PreState = Blank) or (PreState = is_Space) or
                    (PreState = is_10) or (PreState = is_13) or
                    (PreState = is_Cut) then
                 begin
                  CurrentStatement := '';
                  CurrentToken := '';
                  CurrentState := is_CWord;
                  ok := True;
                 end else
                 begin
                  ErrorNo := 101;
                  CurrentStatement := CurrentToken;
                  // jinsong showmessage('unkown identifier before space');
                  exit;
                 end;
                end;
     is_suggest:begin
                 CurrentStatement := CurrentToken;
                 CurrentState := is_suggest;
                 ok := true;
                end;
     is_at     :begin
                 ok := true;
                end;
//     is_Quota  :begin
//                 ok := true;
//                 CurrentStatement := CurrentToken;
//                 CurrentState := is_Quota;
//                end;
     is_left_SQ:begin
                 CurrentStatement := CurrentToken;
                 CurrentState := is_left_SQ;
                 ok := true;
                end;
     is_Equal : begin
                 if PreState = is_suggest then
                  begin
                   CurrentState := is_Assign;
                   CurrentStatement := CurrentToken;
                   OK := True;
                  end else
                  begin
                   OK := True;
                  end;
                end;
     is_slash : begin
                 if PreState = Blank then Prestate := is_slash else
                 if PreState = is_slash then
                  begin
                   Comment_Line_Open := True;
                   ok := True;
                  end else
                  begin
                   ErrorNo := 102;
                   CurrentStatement := CurrentToken;
                   // jinsong showmessage('unkown identifier before slash');
                   exit;
                  end;
                end;
     is_left_Comment :
                begin
                 Comment_Open := True;
                 ok := True;
                end;
     is_left_mI :
                begin
                 if PreState = identifier then
                  begin
                   CurrentStatement := CurrentToken;
                   CurrentState := is_left_mI;
                   ok := true;
                  end else
                 PreState := is_left_mI;
                end;
     is_multi  :
                begin
                 if PreState = is_left_mI then
                  begin
                   Comment_mI_Open := True;
                   ok := True;
                  end else
                  begin
                   ErrorNo := 103;
                   CurrentStatement := CurrentToken;
                   // jinsong showmessage('unkown identifier before *');
                   exit;
                  end;
                end;
    end;
   until ok or (CurrentPos > length(tmpStr));
  end;


 procedure skipCommentLine;
  Var
   i : integer;
   cT : Char;
  begin
   i := CurrentPos;
   repeat
    inc(i);
    cT := tmpStr[i];
   until (cT in [#10,#13,#127]);
   CurrentPos := i;
   repeat
    inc(i);
    cT := tmpStr[i];
   until (not (cT in [#10,#13,#127])) or (i >= length(tmpStr));
   CurrentPos := i;
  end;

 procedure skipComment;
  Var
   i : integer;
   cT : Char;
  begin
   i := CurrentPos;
   repeat
    inc(i);
    cT := tmpStr[i];
   until (cT ='}') or (i >= length(tmpStr));
   CurrentPos := i;
   inc(CurrentPos);
  end;

 procedure skipmIComment;
  Var
   i : integer;
   k : integer;
   uStr : string;
  begin
   uStr := tmpStr;
   i := CurrentPos;
   delete(uStr,1,i-1);
   k := Pos('*)',uStr);
   CurrentPos := i + k + 1;
  end;

 Procedure Read_to_RightSQ;
 Var
  i,j : integer;
  uKStr : String;
  xC : Char;
 begin
  i := CurrentPos;
  j := 1;
  uKStr := '';
  repeat
   xC := tmpStr[i];
   if not (xC in [#10,#13,#127]) then
   uKStr := uKStr + xC else
   uKStr := uKStr + ' ';
   if xC = '[' then inc(j);
   if xC = ']' then dec(j);
   inc(i);
  until (j = 0) or (i > Length(tmpStr));
  if i > Length(tmpStr) then
   begin
    // jinsong showMessage('[ is not properly neted!');
   end else
   begin
    CurrentStatement := CurrentStatement + uKStr;
    CurrentPos := i;
   end;
 end;

// procedure ReadQuota;

 Procedure Read_to_RightmI;
 Var
  i,j : integer;
  uKStr : String;
  xC : Char;
 begin
  i := CurrentPos;
  j := 1;
  uKStr := '';
  repeat
   xC := tmpStr[i];
   if not (xC in [#10,#13,#127]) then
   uKStr := uKStr + xC else
   uKStr := uKStr + ' ';
   if xC = '(' then inc(j);
   if xC = ')' then dec(j);
   inc(i);
  until (j = 0) or (i > Length(tmpStr));
  if i > Length(tmpStr) then
   begin
    // jinsong showMessage('( is not properly neted!');
   end else
   begin
    CurrentStatement := CurrentStatement + uKStr;
    CurrentPos := i;
   end;
 end;

 Function Read_to_SE : string;
 Var
  i,j,k : integer;
  uKStr : String;
  xC : Char;
  uk1 : String;
  QuotaCount : boolean;

 begin
  i := CurrentPos;
  uk1 := tmpStr;
  delete(uk1,1,i-1);
  j := SearchKeyWord(uk1,'else');
  if j = 0 then j := 1000000;
  k := SearchKeyWord(uk1,'end');
  if k = 0 then k := 1000000;
  j := i + j - 1;
  k := i + k - 1;
  uKStr := '';
  QuotaCount := false;
  repeat
   xC := tmpStr[i];
   if (xC = '"') and (not QuotaCount) then
    QuotaCount := true else
   if (xC = '"') and QuotaCount then
    QuotaCount := false;
   if not (xC in [#10,#13,#127]) then
   uKStr := uKStr + xC else
   uKStr := uKStr + ' ';
   inc(i);
  until ((xC = ';') and (not QuotaCount)) or (i >= j) or (i >= k) or (i > Length(tmpStr));
  if i > Length(tmpStr) then
   begin
    // jinsong showMessage('too long line for treate!');
    result := '';
   end else
  if xC <> ';' then
   begin
    if ukStr[length(ukStr)] = ';' then
     delete(ukStr,length(ukStr),1);
    result := uKStr {+ ';'};
    CurrentPos := i;
   end else
   begin
    if ukStr[length(ukStr)] = ';' then
     delete(ukStr,length(ukStr),1);
    result := uKStr;
    CurrentPos := i;
   end;
 end;

 Function Read_to_Then : String;
 Var
  i, j, k : integer;
  uKStr : String;
  xC : Char;
  uk1 : string;
 begin
  uk1 := tmpStr;
  i := CurrentPos;
  delete(uk1,1,i-1);
  j := SearchKeyWord(uk1,'then');
  if j = 0 then
   begin
    // jinsong showMessage('Then expected!');
    result := '';
    exit;
   end;
  uKStr := Copy(uk1,1,j-1);
  Result := uKStr;
  CurrentPos := i+j+4-1;
 end;

 Function Read_to_Do : String;
 Var
  i, j, k : integer;
  uKStr : String;
  xC : Char;
  uk1 : string;
 begin
  uk1 := tmpStr;
  i := CurrentPos;
  delete(uk1,1,i-1);
  j := SearchKeyWord(uk1,'do');
  if j = 0 then
   begin
    // jinsong showMessage('Do expected!');
    result := '';
    exit;
   end;
  uKStr := Copy(uk1,1,j-1);
  Result := uKStr;
  CurrentPos := i+j+2-1;
 end;

 Function NextToken : String;
  Var
   at_ok : byte;

  begin
   CurrentState := blank;
   Comment_Line_Open := false;
   Comment_Open := false;
   Comment_mI_Open := false;
   tmpStr := FeedIn;
   Yes := false;
   at_ok := 0;
   CurrentStatement := '';
   repeat
    ReadToken;
    if Comment_Line_Open then
     begin
      skipCommentLine;
      if assigned(FOnshowString) then
      OnShowString(IntToStr(CurrentPos));
      Comment_Line_Open := false;
      CurrentState := blank;
      at_ok := 0;
     end else
    if Comment_Open then
     begin
      skipComment;
      if assigned(FOnshowString) then
      OnShowString(IntToStr(CurrentPos));
      Comment_Open := false;
      CurrentState := blank;
      at_ok := 0;
     end else
    if Comment_mI_Open then
     begin
      skipmIComment;
      if assigned(FOnshowString) then
      OnShowString(IntToStr(CurrentPos));
      Comment_mI_Open := false;
      CurrentState := blank;
      at_ok := 0;
     end else
     begin
      if CurrentStatement <> '' then
       begin
        Yes := True;
//        at_ok := 0;
       end;
      if CurrentState = is_suggest then
       begin
        Yes := True;
//        at_ok := 0;
       end else
      if CurrentState = is_left_SQ then
       begin
        Yes := True;
        Read_to_RightSQ;
        at_ok := 0;
       end else
      if CurrentState = is_left_mI then
       begin
        Yes := True;
        Read_to_RightmI;
        //at_ok := 0;
       end else
      if CurrentState = is_at then
       begin
        at_ok := 9;
       end else
      if CurrentState = is_cWord then
       begin
        CurrentState := Blank;
//        at_ok := 0;
       end;
     end;
   until Yes or (CurrentPos >= Length(tmpStr));
   if not Yes then
    begin
     // jinsong showmessage('nothing can be compiled!');
     result := '';
    end else
    begin
     if at_ok = 9 then
      result := '@'+CurrentStatement
     else
      result := CurrentStatement;

    end;
  end;

  procedure Treate_PF_Vars(inStr : String);
   Var
    i , k : integer;
    uStr : String;
    ttks : String;
    aCount : string;
    t3,t4 : String;
    m : integer;
    uuk : Byte;
    varCounti : integer;
   begin
    if inStr = '' then exit;
    varCounti := 0;
    VarIndex := '';
    inStr := inStr + ';';
    while inStr <> '' do
     begin
      ttks := GetHeadString(inStr,';');
      i := SearchKeyWord(ttks,'var');
      if i = 0 then
       begin
        uuk := 0;
       end else
       begin
        ttks := trim(ttks);
        GetHeadString(ttks,' ');
        uuk := 1;
       end;
      uStr := GetHeadString(ttks,':');
      uStr := uStr + ',';
      ttks := trim(Uppercase(ttks));
      if Pos('ARRAY[',ttks) <> 0 then
        begin
         GetHeadString(ttks,'[');
         aCount := GetHeadString(ttks,']');
         aCount := '['+aCount+']';
         if Pos('OF ',ttks) = 0 then
          begin
           // jinsong showMessage(' of expected!');
           exit;
          end;
         ttks := trim(ttks);
         GetHeadString(ttks,' ');
         ttks := trim(ttks);
         if ttks = 'INTEGER' then
          m := 4 else
         if ttks = 'REAL' then
          m := 5 else
         if ttks = 'STRING' then
          m := 6 else
         begin
          // jinsong showMessage('Unkonw Array type!');
          exit;
         end;
        end else
        begin
         if ttks = 'BOOLEAN' then
          m := 0 else
         if ttks = 'STRING' then
          m := 1 else
         if ttks = 'INTEGER' then
          m := 2 else
         if ttks = 'REAL' then
          m := 3;
        end;
      while uStr <> '' do
       begin
        inc(varCounti);
        t3 := trim(GetHeadString(uStr,','));
//        t3 := 'U__'+intToStr(varCounti)+'__'+t4+'__'+intToStr(varcounti)+'__U';
//        search_and_rePlace(tmpStr,t4,t3);
        if m > 3 then
         begin
          selfVar.DefineVar(t3+aCount,m);
          if uuk = 0 then
           begin
            indexVar.DefineVar(t3+aCount,m);
            VarIndex := VarIndex + 'L;'+t3+aCount+';';
           end else
           begin
            GIndex.DefineVar(t3+aCount,m);
            VarIndex := VarIndex + 'G;'+t3+aCount+';';
           end;
         end else
         begin
          selfVar.DefineVar(t3,m);
          if uuk = 0 then
           begin
            indexVar.DefineVar(t3,m);
            VarIndex := VarIndex + 'L;'+t3+aCount+';';
           end else
           begin
            GIndex.DefineVar(t3,m);
            VarIndex := VarIndex + 'G;'+t3+aCount+';';
           end;
         end;
       end;
     end;
   end;

  procedure TreateVars;
   label over_over;
   Var
    i , k : integer;
    uStr : String;
    ttks : String;
    aCount : string;
    t3 : String;
    over : boolean;
    m : integer;
   begin
    over := false;
    repeat
     uStr := '';
     repeat
      ttks := '';
      ttks := NextToken;
      if ttks = '' then begin end else
      if Uppercase(ttks) = 'BEGIN' then over := true else
      uStr := uStr + ttks + ',';
     until (CurrentState = is_suggest) or (CurrentPos >= Length(tmpStr)) or over;
     if over then goto over_over;
     if CurrentPos >= Length(tmpStr) then
      begin
       // jinsong showMessage('Var Error!');
       exit;
      end;
     CurrentState := Blank;
     ttks := NextToken;
     ttks := Uppercase(ttks);
     if Pos('ARRAY[',ttks) <> 0 then
      begin
       GetHeadString(ttks,'[');
       aCount := GetHeadString(ttks,']');
       aCount := '['+aCount+']';
       ttks := NextToken;
       if Uppercase(ttks) <> 'OF' then
        begin
         // jinsong showMessage(' of expected!');
         exit;
        end else
        begin
         ttks := NextToken;
         ttks := Uppercase(ttks);
         if ttks = 'INTEGER' then
          m := 4 else
         if ttks = 'REAL' then
          m := 5 else
         if ttks = 'STRING' then
          m := 6 else
         begin
          // jinsong showMessage('Unkonw Array type!');
          exit;
         end;
        end;
      end else
      begin
       if ttks = 'BOOLEAN' then
        m := 0 else
       if ttks = 'STRING' then
        m := 1 else
       if ttks = 'INTEGER' then
        m := 2 else
       if ttks = 'REAL' then
        m := 3;
      end;
     while uStr <> '' do
      begin
       t3 := trim(GetHeadString(uStr,','));
       if m > 3 then
       selfVar.DefineVar(t3+aCount,m) else
       selfVar.DefineVar(t3,m);
      end;
over_over :

    until over or (CurrentPos >Length(tmpStr));
   end;

  Function in_Function(inStr : String) : Boolean;
   Var
    uStr : String;
    ok : Boolean;
   begin
    if Pos('(',inStr) <> 0 then
     begin
      uStr := GetHeadString(inStr,'(');
      uStr := Uppercase(uStr);
      if (uStr = 'INC') or (uStr = 'DEC') or
         (uStr = 'TRIM') or (uStr = 'DELETE') or (uStr = 'LOADFROMFILE') or
         (uStr = 'SAVETOFILE') or (uStr = 'ARRAYX') or (uStr = 'ARRAYY') or
         (uStr = 'PLAYSOUND') or (uStr = 'EXTRALOADFROMFILE') or
         (uStr = 'EXTRASAVETOFILE') or (uStr = 'SYSLOADFILE') or
         (uStr = 'SYSSAVEFILE') or (uStr = 'SYSLOADSTRINGS') or
         (uStr = 'SYSSAVESTRINGS') or (uStr = 'SHOWMESSAGE') then
       begin
        result := True;
        exit;
       end;
     end else
    if Uppercase(inStr) = 'EXIT' then
     begin
      result := True;
     end else
    if Uppercase(inStr) = 'CLOSE' then
     begin
      result := True;
     end else
    if Uppercase(inStr) = 'GOHOME' then
     begin
      result := True;
     end else
    if Uppercase(inStr) = 'INVALIDATE' then
     begin
      result := True;
     end else
     begin
      ok := false;
     end;
    if not ok then
     if Assigned(On_isFunction) then
      ok := On_isFunction(uStr);
    result := ok;
   end;

  Function in_Var(inStr : String) : Boolean;
   Var
    ok : Boolean;
   begin
    if Pos('@',inStr)= 1 then
     begin
      result := true;
      exit;
     end;
    ok := selfVar._isVar(inStr);
    if not ok then
     if Assigned(On_isVar) then
      ok := On_isVar(inStr);
    Result := ok;
   end;

begin
 CurrentPos := 1;
 PointNumber := 0;
(* CurrentState := blank;
 Comment_Line_Open := false;
 Comment_Open := false;
 Comment_mI_Open := false;
 tmpStr := FeedIn;
 Yes := false; *)
 begin_end_count := 0;

 tks := NextToken;
 tks := Uppercase(tks);
 if tks = 'PROGRAM' then
  begin ReserveState := is_Program; end;
 if tks = 'VAR' then
  begin ReserveState := is_Var; end else
 if tks = 'PROCEDURE' then
  begin ReserveState := is_Procedure; end else
 if tks = 'FUNCTION' then
  begin ReserveState := is_Function; end else
 if tks = 'BEGIN' then
  begin ReserveState := is_Begin; end else
  begin ReserveState := is_Error; end;

 repeat
 case ReserveState of
  is_Program : begin
                tks := NextToken;
                if tks = '' then
                 begin
                  // jinsong showMessage('program name needed!');
                  exit;
                 end;
                ScriptName := tks;
                ScriptType := 0;
                tks := NextToken;
                tks := Uppercase(tks);
                if tks = 'VAR' then
                 begin
                  ReserveState := is_Var;
                 end else
                if tks = 'BEGIN' then
                 begin
                  ReserveState := is_Begin;
                 end else
                 begin
                  // jinsong showMessage('Begin needed, but identifier found');
                  ReserveState := is_Error;
                 end;
               end;
  is_Var     : begin
                TreateVars;
                inc(begin_end_count);
                ReserveState := is_OK;
               end;
  is_Begin   : begin
                ReserveState := is_OK;
                inc(begin_end_count);
               end;
  is_procedure
             : begin
                tks := NextToken;

                if tks = '' then
                 begin
                  // jinsong showMessage('Procedure Name needed!');
                  exit;
                 end;
                tmps1 := tks;
                if Pos('(',tmps1) <> 0 then
                 begin
                  tmps2 := GetHeadString(tmps1,'(');
                  ScriptName := tmps2;
                  ScriptType := 1;
                  tmps2 := GetHeadString(tmps1,')');
                  treate_PF_Vars(tmps2);
                 end else
                 begin
                  ScriptName := tks;
                  ScriptType := 1;
                 end;
                  repeat
                   tks := NextToken;
                  until (CurrentPos >= Length(tmpStr)) or (tks <> '');
                  tks := Uppercase(tks);
                  if tks = 'VAR' then
                   ReserveState := is_Var else
                  if tks = 'BEGIN' then
                   ReserveState := is_Begin;
               end;
  is_Function: begin
                tks := NextToken;
                if tks = '' then
                 begin
                  // jinsong showMessage('Procedure Name needed!');
                  exit;
                 end;
                tmps1 := tks;
                if Pos('(',tmps1) <> 0 then
                 begin
                  tmps2 := GetHeadString(tmps1,'(');
                  ScriptName := tmps2;
                  ScriptType := 1;
                  tmps2 := GetHeadString(tmps1,')');
                  treate_PF_Vars(tmps2);
                 end else
                 begin
                  ScriptName := tks;
                  ScriptType := 1;
                 end;
                repeat
                 tks := NextToken;
                until (CurrentPos >= Length(tmpStr)) or (tks <> '');
                if tks = '' then
                 begin
                  // jinsong showMessage('function type not identified!');
                  exit;
                 end;

                tks := Uppercase(tks);
                if tks = 'BOOLEAN' then
                 begin
                  ScriptType := 20;
                  selfVar.DefineVar('result',0);
                 end else
                if tks = 'INTEGER' then
                 begin
                  ScriptType := 21;
                  selfVar.DefineVar('result',2);
                 end else
                if tks = 'REAL' then
                 begin
                  ScriptType := 22;
                  selfVar.DefineVar('result',3);
                 end else
                if tks = 'STRING' then
                 begin
                  ScriptType := 23;
                  selfVar.DefineVar('result',1);
                 end else
                 begin
                  // jinsong showMessage('unknow function type!');
                  exit;
                 end;
                  repeat
                   tks := NextToken;
                  until (CurrentPos >= Length(tmpStr)) or (tks <> '');
                  tks := Uppercase(tks);
                  if tks = 'VAR' then
                   ReserveState := is_Var else
                  if tks = 'BEGIN' then
                   ReserveState := is_Begin;
               end;
 end;
 until (ReserveState = is_OK) or (ReserveState = is_Error);
 if ReserveState = is_Error then exit;

(*************************************************************
   ExecPoint = record
   Command : Byte;  //0 : normal assign, that means assign right to left...
                    //1 : condition, if right is true goto c1, if false goto c2...
                    //2 : Null point, such as repeat cause it...
                    //3 : routine call such as movie5.startaction, etc...
                    //4 : jump, jump to c1 directly, the if then else can cause it...
   C1,C2 : integer;
   left : string;
   right : String;
  end;
**************************************************************)
   (**************************)
   (**)SingleLine := false;(**)
   (**************************)
//  begin_end_count := 1;

  repeat
   tks := NextToken;


   //if Pos('ITEM1X',Uppercase(tks)) <> 0 then
   // showMessage(tks);
   if Uppercase(tks) = 'END.' then
    begin
    end else
   if in_Function(tks) then
    begin
     //find out the function or procedure list to match the line...
     inc(PointNumber);
     setLength(ExecStream,PointNumber);
     ExecStream[PointNumber-1].Command := 3;
     ExecStream[PointNumber-1].left := tks;
     if SelfStack._isControl = 1 then
      begin
       // if for single line, notify the next process to find out whether these is
       // an else statement...
       // do nothing here...
       if SingleLine then
        begin
         SingleLine := false;
         // there is no else part...
         // so pop up the if point
         SelfStack.Pop(ti1,ti2);
         ExecStream[ti2-1].C2 := PointNumber;
         while (SelfStack._isControl = 7) or ( SelfStack._isControl = 4) or
               (SelfStack._isControl = 14) do
          begin
           // that means the previous is else block
           // so, should pop out the else and pop out the end of true block...
           if SelfStack._isControl = 7 then
            SelfStack.Pop(ti1,ti2);{ else //else
           if SelfStack._isControl = 14 then
            begin
             SelfStack.Pop(ti1,ti2);
//             SelfStack.Pop(ti1,ti2);
            end;                  }
           SelfStack.Pop(ti1,ti2); //end of true block...
           ExecStream[ti2-1].C1 := PointNumber;
           SelfStack.Pop(ti1,ti2); // pop the if point and trash it, end of if-else block
          end;
        end else
        begin
         SingleLine := True;
         // Pop up if point and assign current PointNumber to C1
         SelfStack.Pop(ti1,ti2);
         ExecStream[ti2-1].C1 := PointNumber;
         SelfStack.Push(ti1,ti2);
         // for if ... then ......
        end;
      end else
     if SelfStack._isControl = 7 then
      begin
       // is_else...
       // for single line of the else block, if ... then ... else ...
       // the else have treate the false condition's jump
       // here, just need to create new null point for the true block's direct jump...
       SelfStack.Pop(ti1,ti2); //else
       SelfStack.Pop(ti1,ti2); //end of true block...
       inc(PointNumber);  // create new null point for true block's jump...
       setLength(ExecStream,PointNumber);
       ExecStream[PointNumber-1].Command := 2;
       ExecStream[ti2-1].C1 := PointNumber;
       SelfStack.Pop(ti1,ti2); // pop the if point and trash it, end of if-else block
       SingleLine := False;
       while (SelfStack._isControl = 7) or (SelfStack._isControl = 4) or
             (SelfStack._isControl = 14) do
        begin
         // that means the previous is else block
         // so, should pop out the else and pop out the end of true block...
         if SelfStack._isControl = 7 then
          SelfStack.Pop(ti1,ti2);{ else //else
         if SelfStack._isControl = 14 then
          begin
           SelfStack.Pop(ti1,ti2);
//           SelfStack.Pop(ti1,ti2);
          end;                    }
         SelfStack.Pop(ti1,ti2); //end of true block...
         ExecStream[ti2-1].C1 := PointNumber;
         SelfStack.Pop(ti1,ti2); // pop the if point and trash it, end of if-else block
        end;
      end else
     if SelfStack._isControl = 6 then
      begin
       // is_while...
       SingleLine := True;
      end else
     if SelfStack._isControl = 14 then
      begin
       // if... then begin... end;
       // pop up end... pop up begin... pop up if
       SelfStack.Pop(ti1,ti2);
       SelfStack.Pop(ti1,ti2);
       SelfStack.Pop(ti1,ti2);
       ExecStream[ti2-1].C2 := PointNumber;
       while (SelfStack._isControl = 7) or (SelfStack._isControl = 4) or
             (SelfStack._isControl = 14) do
        begin
         // that means the previous is else block
         // so, should pop out the else and pop out the end of true block...
         if SelfStack._isControl = 7 then
          SelfStack.Pop(ti1,ti2);{ else //else
         if SelfStack._isControl = 14 then
          begin
           SelfStack.Pop(ti1,ti2);
//           SelfStack.Pop(ti1,ti2);
          end;                      }
         SelfStack.Pop(ti1,ti2); //end of true block...
         ExecStream[ti2-1].C1 := PointNumber;
         SelfStack.Pop(ti1,ti2); // pop the if point and trash it, end of if-else block
        end;
      end;
    end else
   if in_Var(tks) then
    begin
     repeat
      tmps1 := NextToken;
      
     until (CurrentState = is_suggest) or (CurrentPos >= Length(tmpStr));
     if CurrentState <> is_suggest then
      begin
       // jinsong showMessage(':= needed, but not found!');
       exit;
      end;
     if tmpStr[CurrentPos] <> '=' then
      begin
       // jinsong showMessage('= expected!');
       exit;
      end;
     inc(CurrentPos);
     tmps2 := Read_to_SE;
//     tmps1 := GetHeadString(tmps2,';');
     inc(PointNumber);
     setLength(ExecStream,PointNumber);
     ExecStream[PointNumber-1].Command := 0;
     ExecStream[PointNumber-1].left := tks;
     ExecStream[PointNumber-1].right := tmps2;
     if SelfStack._isControl = 1 then
      begin
       // if for single line, notify the next process to find out whether these is
       // an else statement...
       // do nothing here...
       if SingleLine then
        begin
         SingleLine := false;
         // there is no else part...
         // so pop up the if point
         SelfStack.Pop(ti1,ti2);
         ExecStream[ti2-1].C2 := PointNumber;
         while (SelfStack._isControl = 7) or ( SelfStack._isControl = 4) or
               (SelfStack._isControl = 14) do
          begin
           // that means the previous is else block
           // so, should pop out the else and pop out the end of true block...
           if SelfStack._isControl = 7 then
            SelfStack.Pop(ti1,ti2);{ else //else
           if SelfStack._isControl = 14 then
            begin
             SelfStack.Pop(ti1,ti2);
//             SelfStack.Pop(ti1,ti2);
            end;                  }
           SelfStack.Pop(ti1,ti2); //end of true block...
           ExecStream[ti2-1].C1 := PointNumber;
           SelfStack.Pop(ti1,ti2); // pop the if point and trash it, end of if-else block
          end;
        end else
        begin
         SingleLine := True;
         // Pop up if point and assign current PointNumber to C1
         SelfStack.Pop(ti1,ti2);
         ExecStream[ti2-1].C1 := PointNumber;
         SelfStack.Push(ti1,ti2);
         // for if ... then ......
        end;
      end else
     if SelfStack._isControl = 7 then
      begin
       // is_else...
       // for single line of the else block, if ... then ... else ...
       // the else have treate the false condition's jump
       // here, just need to create new null point for the true block's direct jump...
       SelfStack.Pop(ti1,ti2); //else
       SelfStack.Pop(ti1,ti2); //end of true block...
       inc(PointNumber);  // create new null point for true block's jump...
       setLength(ExecStream,PointNumber);
       ExecStream[PointNumber-1].Command := 2;
       {if (((ti2-1) < 0) or ((ti2-1) >= PointNumber)) then
        showMessage(IntToStr(ti2));}
       ExecStream[ti2-1].C1 := PointNumber;
       SelfStack.Pop(ti1,ti2); // pop the if point and trash it, end of if-else block
       SingleLine := False;
       while (SelfStack._isControl = 7) or (SelfStack._isControl = 4) or
             (SelfStack._isControl = 14) do
        begin
         // that means the previous is else block
         // so, should pop out the else and pop out the end of true block...
         if SelfStack._isControl = 7 then
          SelfStack.Pop(ti1,ti2);{ else //else
         if SelfStack._isControl = 14 then
          begin
//           SelfStack.Pop(ti1,ti2);
           SelfStack.Pop(ti1,ti2);
          end;                    }
         SelfStack.Pop(ti1,ti2); //end of true block...
         ExecStream[ti2-1].C1 := PointNumber;
         SelfStack.Pop(ti1,ti2); // pop the if point and trash it, end of if-else block
        end;
      end else
     if SelfStack._isControl = 6 then
      begin
       // is_while...
       SingleLine := True;
      end else
     if SelfStack._isControl = 14 then
      begin
       // if... then begin... end;
       // pop up end... pop up begin... pop up if
       SelfStack.Pop(ti1,ti2);
       SelfStack.Pop(ti1,ti2);
       SelfStack.Pop(ti1,ti2);
       {if (((ti2-1) < 0) or ((ti2-1) >= PointNumber)) then
        showMessage(IntToStr(ti2)+ ' ' + IntToStr(PointNumber));}
       ExecStream[ti2-1].C2 := PointNumber;
       while (SelfStack._isControl = 7) or (SelfStack._isControl = 4) or
             (SelfStack._isControl = 14) do
        begin
         // that means the previous is else block
         // so, should pop out the else and pop out the end of true block...
         if SelfStack._isControl = 7 then
          SelfStack.Pop(ti1,ti2);{ else //else
         if SelfStack._isControl = 14 then
          begin
//           SelfStack.Pop(ti1,ti2);
           SelfStack.Pop(ti1,ti2);
          end;                    }
         SelfStack.Pop(ti1,ti2); //end of true block...
         ExecStream[ti2-1].C1 := PointNumber;
         SelfStack.Pop(ti1,ti2); // pop the if point and trash it, end of if-else block
        end;
      end;
    end else
    begin
     //
     tks := Uppercase(tks);
     if tks = 'IF' then ReserveState := is_if else
     if tks = 'REPEAT' then ReserveState := is_repeat else
     if tks = 'WHILE' then ReserveState := is_while else
     if tks = 'FOR' then ReserveState := is_for else
     if tks = 'BEGIN' then ReserveState := is_Begin else
     if tks = 'END' then ReserveState := is_End else
     if tks = 'ELSE' then ReserveState := is_Else else
     if tks = 'UNTIL' then ReserveState := is_Until else
     begin ReserveState := is_Error; end;
     if ReserveState = is_Error then
      begin
       // jinsong ShowMessage('We meet error! the identifier is:'+tks+' Current Pos is:'+IntToStr(CurrentPos));
       exit;
      end;

     case ReserveState of
      is_if : begin
               if SingleLine then SingleLine := False;
               tmps1 := Read_to_Then;
               //SelfStack._isControl := 1;
               inc(PointNumber);
               setLength(ExecStream,PointNumber);
               ExecStream[PointNumber-1].Command := 1;
               ExecStream[PointNumber-1].left := tmps1;
               SelfStack.Push(1,PointNumber);
              end;
      is_else : begin
                  // we may meet two condition...
                  // the first is if ... then begin ... end else ...
                  // the second is if ... then ... else ...
                  // so, for the first condition , current _isControl should equal 4
                  // then we pop the end, record it
                  // and pop the begin and then pop the if point
                  // and assign the current pointnumber to c2, then push the end point back...
                  // else the _isControl should equal 1...
                  // just pop it up and assign the c2 to current pointnumber...
                  // and create a jump point and push it to stack for jump over the else block...
                  // then a null point indicate the start of the else block...


                  if SelfStack._isControl = 4 then
                   begin
                    inc(PointNumber);
                    setLength(ExecStream,PointNumber);
                    ExecStream[PointNumber-1].Command := 2;
                    SelfStack.Pop(ti1,ti2); // the end point...
                    ti3 := ti2; // record the line number to ti3...
                    SelfStack.Pop(ti1,ti2); // the begin point...
                    SelfStack.Pop(ti1,ti2); // the if point...
                    ExecStream[ti2-1].C2 := PointNumber;
                    //SelfStack.Push(ti1,ti2); //if point???
                    SelfStack.Push(4,ti3);  // push back the end point for jump over the else block
                   end else
                  if SelfStack._isControl = 14 then
                   begin
                    // pop end and record it
                    // pop begin and record it
                    // pop if and record it
                    // and create a null point then assign pointnumber to if false block
                    inc(PointNumber);
                    setLength(ExecStream,PointNumber);
                    ExecStream[PointNumber-1].Command := 2;
                    SelfStack.Pop(ti1,ti2); // the end point...
                    ti3 := ti2; // record the line number to ti3...
                    SelfStack.Pop(ti1,ti2); // the begin point...
                    ti5 := ti1; ti4 := ti2;
                    SelfStack.Pop(ti1,ti2); // the if point...
                    ExecStream[ti2-1].C2 := PointNumber;
                    SelfStack.Push(ti1,ti2); // push back the if point
//                    SelfStack.Push(ti5,ti4); // push back the begin point
                    SelfStack.Push(14,ti3);  // push back the end point for jump over the else block
                   end else
                   begin
                    inc(PointNumber);
                    setLength(ExecStream,PointNumber);
                    ExecStream[PointNumber-1].Command := 4;
                    ti3 := PointNumber;
                    inc(PointNumber);
                    setLength(ExecStream,PointNumber);
                    ExecStream[PointNumber-1].Command := 2;
                    SelfStack.Pop(ti1,ti2);
                    ExecStream[ti2-1].C2 := PointNumber;
                    SelfStack.Push(ti1,ti2);  // if point???
                    SelfStack.Push(4,ti3);
                   end;
                  SelfStack.Push(7,PointNumber);
                end;
      is_Begin : begin
                  ti3 := 0;
                  inc(begin_end_count);
                  inc(PointNumber);
                  setLength(ExecStream,PointNumber);
                  ExecStream[PointNumber-1].Command := 2;
                  if SelfStack._isControl = 1 then //if ....
                   begin
                    // if the if condition is true, then execute current point...
                    // so the c1 of the if point is assigned to the current pointnumber...
                    SelfStack.Pop(ti1,ti2);
                    ExecStream[ti2-1].C1 := PointNumber;
                    SelfStack.Push(ti1,ti2);
                    ti3 := 20;
                   end else
                  if SelfStack._isControl = 5 then //for ...
                   begin
                    ti3 := 30;
                   end else
                  if SelfStack._isControl = 6 then //while ...
                   begin
                    SelfStack.Pop(ti1,ti2);
                    ExecStream[ti2-1].C1 := PointNumber;
                    SelfStack.Push(ti1,ti2);
                    ti3 := 40;
                   end else
                  if SelfStack._isControl = 7 then //else ...
                   begin
                    ti3 := 50;
                   end;
//                  ExecStream[PointNumber-1].left := tmps1;
                  SelfStack.Push(ti3+2,PointNumber);
                 end;
      is_repeat : begin
                   inc(PointNumber);
                   setLength(ExecStream,PointNumber);
                   ExecStream[PointNumber-1].Command := 2;
                   //ExecStream[PointNumber-1].left := tmps1;
                   SelfStack.Push(8,PointNumber);
                  end;
      is_Until  : begin
                   tmps1 := Read_to_SE;
                   //tmps2 := GetHeadString(tmps1,';');
                   SelfStack.Pop(ti1,ti2);
                   inc(PointNumber);
                   setLength(ExecStream,PointNumber);
                   ExecStream[PointNumber-1].Command := 1;
                   ExecStream[PointNumber-1].C2 := ti2;
                   ExecStream[PointNumber-1].left := tmps1;
                   ti3 := PointNumber;
                   inc(PointNumber);
                   setLength(ExecStream,PointNumber);
                   ExecStream[PointNumber-1].Command := 2;
                   ExecStream[ti3-1].C1 := PointNumber;
                  end;
      is_while : begin
                  tmps1 := Read_to_Do;
                  //SelfStack._isControl := 1;
                  inc(PointNumber);
                  setLength(ExecStream,PointNumber);
                  ExecStream[PointNumber-1].Command := 6;
                  ExecStream[PointNumber-1].left := tmps1;
                  SelfStack.Push(6,PointNumber);
                 end;
      is_for : begin
               end;
      is_end : begin
                dec(begin_end_count);
                SelfStack.Pop(ti1,ti2);
                case ti1 of
                  22 : begin
                        //if... then begin ... end...
                        //that's mean the first condition of the if block is finished...
                        //but we can not know whether there is else block, so push
                        //the record to stack and wait for the jump point number...
                        //and first, we push the begin position back to the stack
                        SelfStack.Push(ti1,ti2);
                        //create the run point for jump...
                        inc(PointNumber);
                        setLength(ExecStream,PointNumber);
                        ExecStream[PointNumber-1].Command := 4; //jump over the else block
                        SelfStack.Push(14,PointNumber);
                       end;
                  32 : begin
                        //for ...
                       end;
                  42 : begin
                        //while...
                        // cause we have pop out the begin record, then
                        // the previous stack record should the while record...
                        // the c1 for if while condition is true, and the c2 should the next
                        // line of the execstream, and the current execstream point
                        // should jump directly to the while condition, so we get...
                        SelfStack.Pop(ti1,ti2); //this get the while record...
                        inc(PointNumber);
                        setLength(ExecStream,PointNumber);
                        ExecStream[PointNumber-1].Command := 4; //wait for the c1 to jump...
                        ExecStream[PointNumber-1].C1 := ti2; // jump directly to while condition...

                        inc(PointNumber);
                        setLength(ExecStream,PointNumber);
                        ExecStream[PointNumber-1].Command := 2; //Null Point for while finished...

                        ExecStream[ti2-1].C2 := PointNumber; //after while, then continue...
                       end;
                  52 : begin
                        //else
                        // that means ... else begin end...
                        // so, the begin point is poped up
                        // we should pop up the else point, then the previous end point
                        // and assign current pointnumber to the c1...
                        SelfStack.Pop(ti1,ti2); // else point...
                        SelfStack.Pop(ti1,ti2); // previous end point...
                        inc(PointNumber);
                        setLength(ExecStream,PointNumber);
                        ExecStream[PointNumber-1].Command := 2; //Null Point for else block finished...
                        ExecStream[ti2-1].C1 := PointNumber;
                        SelfStack.Pop(ti1,ti2); // trash the if point...
                        while (SelfStack._isControl = 4) or (SelfStack._isControl = 7) or
                              (SelfStack._isControl = 14) do
                         begin
                          if SelfStack._isControl = 7 then
                           SelfStack.Pop(ti1,ti2);{ else //else
                          if SelfStack._isControl = 14 then
                           begin
                            SelfStack.Pop(ti1,ti2);
//                            SelfStack.Pop(ti1,ti2);
                           end;                    }
                          SelfStack.Pop(ti1,ti2); //end of true block...
                          ExecStream[ti2-1].C1 := PointNumber;
                          SelfStack.Pop(ti1,ti2); // pop the if point and trash it, end of if-else block
                         end;
                       end;
                  else  begin
                          //other...
                         end;
                end;
               end;
      else
               begin
                // jinsong showMessage('Unknow identifier!');
                exit;
               end;
     end;
    end;
  until (begin_end_count = 0) or(CurrentPos >= Length(tmpStr)) or (tks = 'end.');
 // SaveToFile('c:\t1.script');
//  run;
end;

Procedure TScript.SaveToFile(FileName : String);
Var
 t1 : String;
 i : integer;
 tmpList : TStringList;
begin
 if PointNumber = 0 then exit;
 tmpList := TStringList.Create;
 for i := 0 to PointNumber - 1 do
  begin
   t1 := IntToStr(ExecStream[i].Command)+'^'+IntToStr(ExecStream[i].C1)+'^'+
         IntToStr(ExecStream[i].C2)+'^'+ExecStream[i].left +'^'+ExecStream[i].right;
   tmpList.Add(t1);
  end;
 tmpList.SaveToFile(FileName);
 tmpList.Destroy;
end;

Procedure TScript.RequestValue(inStr : String; Var OutStr : String; Var OType : Byte);
begin
 OutStr := SelfVar.GetValue(inStr, OType);
 if OType = 255 then
  if Assigned(FOutSideVar) then
   OnOutSideVar(inStr,OutStr,OType);
end;

Function TScript.FunctionCall(inStr : String) : Boolean;
Var
 t1,t2,t3,t4,t5 : String;
 ok : Boolean;
 sType : Byte;
 ti : integer;
 n : byte;
 r,g,b : Byte;
 H,M,S,MS : Word;
 tmpColor : TColor;
 objName : string;
begin
 t3 := trim(inStr);
 objName := '';
 if t3[1] = '@' then
  begin
   delete(t3,1,1);
   t4 := '';
   if Pos('.',t3) <> 0 then
    begin
     t4 := t3;
     t3 := Copy(t3,1,Pos('.',t3)-1);
     delete(t4,1,Pos('.',t4));
    end;
    objName := t3;
    requestValue(t3,t5,n);
    //t3 := selfVar.GetValue(t3,n);
    if n <> 255 then
     begin
      if t5[1] = '"' then
       begin
        delete(t5,1,1);
        delete(t5,length(t5),1);
       end;
     end;
   if t4 <> '' then
   t2 := t5 + '.' + t4 else
   t2 := t5;
  end else
  t2 := inStr;
 if Pos('(',t2 )<> 0 then
  begin
   t1 := trim(Uppercase(GetHeadString(t2,'(')));
   if t1 = 'INC' then
    begin
     t1 := GetHeadString(t2,')');
     requestValue(t1,t2,sType);
     t2 := IntToStr(StrToInt(t2)+1);
     SelfVar.SetValue(t1,t2,sType);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       OnSetValue(t1,t2);
     ok := true;
    end else
   if t1 = 'DEC' then
    begin
     t1 := GetHeadString(t2,')');
     requestValue(t1,t2,sType);
     t2 := IntToStr(StrToInt(t2)-1);
     SelfVar.SetValue(t1,t2,sType);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       OnSetValue(t1,t2);
     ok := true;
    end else
   if t1 = 'DELETE' then
    begin
     t1 := GetHeadString(t2,')'); //t1 = inStr,1,5
     t2 := t1;
     t1 := GetHeadString(t2,','); //t1 = inStr... t2 = 1,5...
     requestValue(t1,t3,stype);
     if t3[1] = '"' then delete(t3,1,1); if t3[length(t3)] = '"' then delete(t3,length(t3),1);
     t4 := GetHeadString(t2,','); //t4 = 1... t2 = 5...
     requestValue(t4,t4,stype);
     requestValue(t2,t2,stype);
     delete(t3,StrtoInt(t4),StrToInt(t2));
     t3 := '"'+t3+'"';
     selfVar.SetValue(t1,t3,stype);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       OnSetValue(t1,t3);
     ok := true;
    end else
   if t1 = 'DECODENOWTOTIME' then
    begin
     t1 := GetHeadString(t2,')'); //t1 = H, M, S, MS
     DecodeTime(Now,H,M,S,MS);
     t2 := GetHeadString(t1,','); //t2 = h, t1=m,s,ms
     t3 := IntToStr(H);
     selfVar.SetValue(t2,t3,stype);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       FOnSetValue(t2,t3);
     t2 := GetHeadString(t1,','); //t2 = m, t1=s,ms
     t3 := IntToStr(M);
     selfVar.SetValue(t2,t3,stype);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       FOnSetValue(t2,t3);
     t2 := GetHeadString(t1,','); //t2 = s, t1=ms
     t3 := IntToStr(S);
     selfVar.SetValue(t2,t3,stype);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       FOnSetValue(t2,t3);
     t2 := t1;
     t3 := IntToStr(MS);
     selfVar.SetValue(t2,t3,stype);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       FOnSetValue(t2,t3);
    end else
   if t1 = 'DECODENOWTODATE' then
    begin
     t1 := GetHeadString(t2,')'); //t1 = H, M, S
     DecodeDate(Now,H,M,S);
     t2 := GetHeadString(t1,','); //t2 = h, t1=m,s
     t3 := IntToStr(H);
     selfVar.SetValue(t2,t3,stype);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       FOnSetValue(t2,t3);
     t2 := GetHeadString(t1,','); //t2 = m, t1=s
     t3 := IntToStr(M);
     selfVar.SetValue(t2,t3,stype);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       FOnSetValue(t2,t3);
     t2 := t1;
     t3 := IntToStr(S);
     selfVar.SetValue(t2,t3,stype);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       FOnSetValue(t2,t3);
    end else
   if t1 = 'COLORTORGB' then
    begin
     t1 := GetHeadString(t2,')'); //t1 = inStr,R,G,B
     t2 := t1;
     t1 := GetHeadString(t2,','); //t1 = inStr t2 = R,G,B
     requestValue(t1,t3,stype);
     if t3[1] = '"' then delete(t3,1,1); if t3[length(t3)] = '"' then delete(t3,length(t3),1);
     while Pos('#',t3) <> 0 do
      t3[Pos('#',t3)] := '$';
     tmpColor := StringToColor(t3);
     R := (tmpColor and $FF0000) shr 16;
     G := (tmpColor and $00FF00) shr 8;
     B := (tmpColor and $0000FF);
     t1 := GetHeadString(t2,',');  // get the r....
     t3 := IntToStr(r);
     selfVar.SetValue(t1,t3,stype);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       OnSetValue(t1,t3);
     t1 := GetHeadString(t2,',');  // get the g....
     t3 := IntToStr(g);
     selfVar.SetValue(t1,t3,stype);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       OnSetValue(t1,t3);
     t1 := t2;                    // the t2 is b now...
     t3 := IntToStr(b);
     selfVar.SetValue(t1,t3,stype);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       OnSetValue(t1,t3);
    end else
   if t1 = 'FILLARRAY' then
    begin
     t1 := GetHeadString(t2,')');
     t2 := GetHeadString(t1,',');
     SelfVar.SetValue(t2,t1,sType);
     if sType = 255 then
      if Assigned(FOnSetValue) then
       OnSetValue(t1,t2);
     ok := true;
    end else
   (*if t1 = 'PLAYSOUND' then
    begin
     t1 := GetHeadString(t2,')');
     requestValue(t1,t2,sType);
     if t2[1] = '"' then delete(t2,1,1); if t2[length(t2)] = '"' then delete(t2,length(t2),1);
     if Assigned(FOnPlaySound) then
      begin
       OnPlaySound(t2);
      end;
//     sndPlaySound(@t2[1],snd_aSync);
    end else *)
   if t1 = 'LOADFROMFILE' then
    begin
     t3 := GetHeadString(t2,')');
     t2 := GetHeadString(t3,',');
     requestValue(t3,t4,stype);
     if t4[1] = '"' then delete(t4,1,1); if t4[length(t4)] = '"' then delete(t4,length(t4),1);
     SelfVar.LoadFromFile(t2,t4,sType);
     if sType = 255 then
      begin
       if Assigned(FOnFunctionCall) then
        begin
         t2 := t2 + ',' + t3;
         OnFunctionCall(t1,t2);
        end;
      end;
    end else
   if t1 = 'SAVETOFILE' then
    begin
     t3 := GetHeadString(t2,')');
     t2 := GetHeadString(t3,',');
     requestValue(t3,t4,stype);
     if t4[1] = '"' then delete(t4,1,1); if t4[length(t4)] = '"' then delete(t4,length(t4),1);
     SelfVar.SaveToFile(t2,t4,sType);
     if sType = 255 then
      begin
       if Assigned(FOnFunctionCall) then
        begin
         t2 := t2 + ',' + t3;
         OnFunctionCall(t1,t2);
        end;
      end;
    end else
   if t1 = 'SYSLOADSTRINGS' then
    begin
     t3 := GetHeadString(t2,')');
     t2 := GetHeadString(t3,',');
     requestValue(t3,t4,stype);
     if t4[1] = '"' then delete(t4,1,1); if t4[length(t4)] = '"' then delete(t4,length(t4),1);
     SelfVar.sysLoadStrings(t2,t4,sType);
     if sType = 255 then
      begin
       if Assigned(FOnFunctionCall) then
        begin
         t2 := t2 + ',' + t3;
         OnFunctionCall(t1,t2);
        end;
      end;
    end else
   if t1 = 'SYSSAVESTRINGS' then
    begin
     t3 := GetHeadString(t2,')');
     t2 := GetHeadString(t3,',');
     requestValue(t3,t4,stype);
     if t4[1] = '"' then delete(t4,1,1); if t4[length(t4)] = '"' then delete(t4,length(t4),1);
     SelfVar.sysSaveStrings(t2,t4,sType);
     if sType = 255 then
      begin
       if Assigned(FOnFunctionCall) then
        begin
         t2 := t2 + ',' + t3;
         OnFunctionCall(t1,t2);
        end;
      end;
    end else
   if t1 = 'SYSLOADFILE' then
    begin
     t3 := GetHeadString(t2,')');
     //t2 := GetHeadString(t3,',');
     //requestValue(t3,t4,stype);
     //if t4[1] = '"' then delete(t4,1,1); if t4[length(t4)] = '"' then delete(t4,length(t4),1);
     SelfVar.sysLoadFile(t3,sType);
     //SelfVar.ExtraLoadFromFile(t2,t4,sType);
     if sType = 255 then
      begin
       if Assigned(FOnFunctionCall) then
        begin
         t2 := t3;
         //t2 := t2 + ',' + t3;
         OnFunctionCall(t1,t2);
        end;
      end;
    end else
   if t1 = 'SYSSAVEFILE' then
    begin
     t3 := GetHeadString(t2,')');
     //t2 := GetHeadString(t3,',');
     //requestValue(t3,t4,stype);
     //if t4[1] = '"' then delete(t4,1,1); if t4[length(t4)] = '"' then delete(t4,length(t4),1);
     SelfVar.sysSaveFile(t3,sType);
     //SelfVar.ExtraSaveToFile(t2,t4,sType);
     if sType = 255 then
      begin
       if Assigned(FOnFunctionCall) then
        begin
         t2 := t3;
         //t2 := t2 + ',' + t3;
         OnFunctionCall(t1,t2);
        end;
      end;
    end else
   if t1 = 'EXTRALOADFROMFILE' then
    begin
     t3 := GetHeadString(t2,')');
     t2 := GetHeadString(t3,',');
     requestValue(t3,t4,stype);
     if t4[1] = '"' then delete(t4,1,1); if t4[length(t4)] = '"' then delete(t4,length(t4),1);
     SelfVar.ExtraLoadFromFile(t2,t4,sType);
     if sType = 255 then
      begin
       if Assigned(FOnFunctionCall) then
        begin
         t2 := t2 + ',' + t3;
         OnFunctionCall(t1,t2);
        end;
      end;
    end else
   if t1 = 'EXTRASAVETOFILE' then
    begin
     t3 := GetHeadString(t2,')');
     t2 := GetHeadString(t3,',');
     requestValue(t3,t4,stype);
     if t4[1] = '"' then delete(t4,1,1); if t4[length(t4)] = '"' then delete(t4,length(t4),1);
     SelfVar.ExtraSaveToFile(t2,t4,sType);
     if sType = 255 then
      begin
       if Assigned(FOnFunctionCall) then
        begin
         t2 := t2 + ',' + t3;
         OnFunctionCall(t1,t2);
        end;
      end;
    end else
   if t1 = 'SHOWMESSAGE' then
    begin
     t3 := GetHeadString(t2,')');
     requestValue(t3,t2,sType);
     if t2 = '' then begin end else
     begin
      if t2[1] = '"' then delete(t2,1,1);
      if t2 = '' then begin end else
      begin
       if t2[length(t2)] = '"' then
        delete(t2,length(t2),1);
      end;
     end;
     showmessage(t2);
    end else
   if t1 = 'ARRAYX' then
    begin
     t3 := GetHeadString(t2,')');
     t2 := GetHeadString(t3,',');
     ti := SelfVar.arrayx(t2);
     if ti <> -1 then
      begin
       t2 := IntToStr(ti);
       SelfVar.SetValue(t3,t2,sType);
       if sType = 255 then
        if Assigned(FOnSetValue) then
         OnSetValue(t3,t2);
      end else
      begin
       if Assigned(FOnFunctionCall) then
        begin
         t2 := t2 + ',' + t3;
         t2 := OnFunctionCall(t1,t2);
         SelfVar.SetValue(t3,t2,sType);
        end;
      end;
    end else
   if t1 = 'ARRAYY' then
    begin
     t3 := GetHeadString(t2,')');
     t2 := GetHeadString(t3,',');
     ti := SelfVar.arrayy(t2);
     if ti <> -1 then
      begin
       t2 := IntToStr(ti);
       SelfVar.SetValue(t3,t2,sType);
       if sType = 255 then
        if Assigned(FOnSetValue) then
         OnSetValue(t3,t2);
      end else
      begin
       if Assigned(FOnFunctionCall) then
        begin
         t2 := t2 + ',' + t3;
         t2 := OnFunctionCall(t1,t2);
         SelfVar.SetValue(t3,t2,sType);
        end;
      end;
    end else
   begin
    if Assigned(FOnFunctionCall) then
     begin
      t3 := GetHeadString(t2,')');
      t3 := t3 + ',';
      t5 := '';
      while t3 <> '' do
       begin
        t2 := GetHeadString(t3,',');
        requestValue(t2,t4,stype);
        t5 := t5 + t4 + ',';
       end;
      //if stype <> 255 then
      //t3 := t2 + ',' else
      //t3 := t3 + ',';
      if objName <> '' then
       t1 := '@'+objName + t1;
      OnFunctionCall(t1,t5);
      ok := True;
     end else
    ok := false;
   end
  end else
  begin
   if Assigned(FOnFunctionCall) then
    begin
     if objName <> '' then
      t2 := '@'+objName+t2;
     OnFunctionCall(t2,'');
     ok := true;
    end else
   ok := false;
  end;
 result := ok;
end;

Procedure TScript.Run;
 Var
  i : integer;
  j,k,n : Byte;
  ut1,ut2 : String;
 begin
  i := 0;
  //if scriptName = '' then
  //savetofile('c:\t1.script')
  //else
  //savetofile('c:\'+scriptName+'.script');
//  if scriptname = 'tz' then
//   showMessage('tz');
  repeat
    if ExecStream = nil then exit;
    j := ExecStream[i].Command;
    case j of
     0 : begin
          // normal assign
          ut1 := trim(ExecStream[i].left);

          ut2 := trim(ExecStream[i].right);
          if Pos('INDEXVAR',Uppercase(ut2)) <> 0 then
           begin
            ut2 := ut2;
           end;
          //SelfExp.setContent(ut1);
//          if Pos('oriitem',ut2) <> 0 then
//           showmessage('fjdslfsl');
          ut1 := SelfExp.SmartString(ut1);
//          if (Pos('k',ut1) <> 0) and (Pos('Zs(',ut2) <> 0) then
//           begin
//            n := n + 1;
//           end;
          SelfExp.CalcSubIndex(ut2);
          ut2 := SelfExp.GetResult;
          SelfVar.SetValue(ut1,ut2,n);
          if n = 255 then
           if Assigned(FOnSetValue) then
            OnSetValue(ut1,ut2);
          if assigned(FOnshowString) then
          OnShowString('assign '+ut2+' to '+ut1);
          inc(i);
         end;
     1 : begin
          ut1 := ExecStream[i].left;
          SelfExp.CalcSubIndex(ut1);
          ut2 := Uppercase(SelfExp.GetResult);
          if ut2 = 'TRUE' then
           begin
            i := ExecStream[i].C1-1;
            if assigned(FOnshowString) then
            OnShowString(ut1 + ' is true then goto ' + IntToStr(i));
           end else
           begin
            i := ExecStream[i].C2-1;
            if assigned(FOnshowString) then
            OnShowString(ut1 + ' is false then goto ' + IntToStr(i));
           end;
         end;
     2 : begin
          if assigned(FOnshowString) then
          OnShowString('Null Point, continue');
          inc(i);
         end;
     3 : begin
          ut1 := ExecStream[i].left;
          //ut1 := SelfExp.SmartString(ut1);
          //SelfExp.CalcSubIndex(ut1);
          if trim(Uppercase(ut1)) = 'EXIT' then
           begin
            if assigned(FOnshowString) then
            OnShowString('Exit from this program!');
            i := PointNumber;
           end else
           begin
//            if Pos('changename',ut1) <> 0 then
//             begin
//              showMessage('fdsjkfs');
//             end;
            FunctionCall(ut1);
            if assigned(FOnshowString) then
            OnShowString('Function call '+ut1);
            inc(i);
           end;
         end;
     4 : begin
          if (ExecStream[i].C1 + ExecStream[i].C2) = 0 then
           begin
            if assigned(FOnshowString) then
            OnShowString('c1 and c2 are zero, continue!');
            inc(i);
           end else
           begin
            i := ExecStream[i].C1-1;
            if assigned(FOnshowString) then
            OnShowString('Directly go to '+ IntToStr(i));
           end;
         end;
     else begin
           if assigned(FOnshowString) then
           OnShowString('Unknow command '+IntToStr(j)+' Continue!');
           inc(i);
          end;
    end;
  until i >= PointNumber;
  if ScriptType >= 20 then
   begin
    ReturnResult := selfVar.GetValue('result',k);
    if assigned(FOnshowString) then
    OnShowString(ReturnResult);
   end;
  if assigned(FOnshowString) then
  OnShowString('Finished!');
 end;


constructor TProgramBody.create;
 begin
  GVars := TVars.create;
  Compiled := false;
  MainScript := TScript.create;
  MainScript.OnOutSideVar := GetOutVar;
  MainScript.OnSetValue := SetOutVar;
  FPCount := 0;
  ESCount := 0;
  Running := false;
 end;

destructor TProgramBody.destroy;
 Var
  i : integer;
 begin
//  if running then showMessage('something not finished!--script');
  GVars.free;
  MainScript.free;
  if FPCount > 0 then
  begin
   for i := 0 to FPCount - 1 do
    F_and_P[i].destroy;
  end;
  F_and_P := Nil;
  if ESCount > 0 then
   Event_Source := Nil;
  inherited destroy;
 end;

Procedure TProgramBody.SetOutVar(inStr : String; Var OutStr : String);
 Var
  n : Byte;
  tmpStr1 : string;
 begin
  if (inStr[1] = '@') and (Pos('.',instr)<>0) then
   begin
    delete(inStr,1,1);
    tmpStr1 := GetHeadString(inStr,'.');
    tmpStr1 := MainScript.selfVar.GetValue(tmpStr1,n);
    if n <> 255 then
     begin
      if tmpStr1[1] = '"' then
       begin
        delete(tmpStr1,1,1);
        delete(tmpStr1,length(tmpStr1),1);
       end;
     end else
     exit;
    inStr := tmpStr1 + '.' + inStr;
   end;
//  GVars.SetValue(inStr,OutStr,n);
//  if n <> 255 then
//   begin
    MainScript.selfVar.SetValue(inStr,OutStr,n);
    if n = 255 then
     begin
      if Assigned(FOnSetValue) then
       OnSetValue(inStr,OutStr);
      GVars.SetValue(inStr,OutStr,n);
     end;
//   end else
//  if n = 255 then
//   begin
//    MainScript.selfVar.SetValue(inStr,OutStr,n);
//    if n = 255 then
//     showMessage('set value failed!');
//   end;
 end;

Function TProgramBody._isVar(inStr : String) : Boolean;
 Var
  ok : Boolean;
 begin
  ok := MainScript.selfVar._isVar(inStr);
  if not ok then
   Result := GVars._isVar(inStr) else
   Result := ok;
 end;

Function TProgramBody._isFunction(inStr : String) : Boolean;
 Var
  i : integer;
  ok : Boolean;
 begin
  ok := false;
  inStr := trim(Uppercase(inStr));
  if FPCount > 0 then
   begin
    ok := false;
    for i := 0 to FPCount - 1 do
     begin
      ok := trim(Uppercase(F_and_P[i].ScriptName)) = inStr;
      if ok then break;
     end;
   end;
  if ok then
   begin
    result := true;
    exit;
   end else
   begin
    if Pos('.STARTACTION',inStr) <> 0 then
     ok := true else
    if Pos('.CLICK',inStr) <> 0 then
     ok := true else
    if Pos('.VCLIP',inStr) <> 0 then
     ok := true else
    if Pos('.HCLIP',inStr) <> 0 then
     ok := true else
    if Pos('PLAYSOUND',inStr) <> 0 then
     ok := True else
    if Pos('BACKMUSIC',inStr) <> 0 then
     ok := true else
    if Pos('STOPACTION',inStr) <> 0 then
     ok := true else
    if Pos('DUPITEM',inStr) <> 0 then
     ok := true else
    if Pos('CREATETIMER',inStr) <> 0 then
     ok := true else
    if Pos('DELETETIMER',inStr) <> 0 then
     ok := true else
    if Pos('ACTIVETIMER',inStr) <> 0 then
     ok := true else
    if Pos('DEACTIVETIMER',inStr) <> 0 then
     ok := True else
    if Pos('CREATEITEM',inStr) <> 0 then
     ok := true else
    ok := false;
   end;
  result := ok;
 end;

Procedure TProgramBody.FP_Filter(Var inStr : String);
 Var
  i,j,k,l : integer;
  str1,str2,str3 : string;
  oriStr : String;
  ticker : integer;
 begin
  oriStr := '';
  repeat
   i := SearchKeyWord(inStr,'function');
   if i = 0 then begin end else
   begin
    oriStr := OriStr + Copy(inStr,1,i-1);
    delete(inStr,1,i-1);
    str1 := '';
    j := SearchKeyWord(inStr,'begin');
    str1 := Copy(inStr,1,j+4);
    delete(inStr,1,j+4);
    ticker := 1;
    repeat
     k := SearchKeyWord(inStr,'end');
     l := SearchKeyWord(inStr,'begin');
     if ((k < l) or (l = 0)) and (ticker >= 1) then
      begin
       str1 := str1 + Copy(inStr,1,k+3);
       delete(inStr,1,k+3);
       ticker := ticker - 1;
       if ticker = 0 then
        begin
         setFP(str1);
         str1 := '';
        end;
      end else
     if (k < l) and (ticker > 1) then
      begin
       ticker := ticker - 1;
       str1 := str1 + Copy(inStr,1,k+2);
       delete(inStr,1,k+2);
      end else
     if (k > l) and (l <> 0) then
      begin
       ticker := ticker + 1;
       str1 := str1 + Copy(inStr,1,l+4);
       delete(inStr,1,l+4);
      end;
    until ticker = 0;
   end;
  until i = 0;
  OriStr := OriStr + inStr;
  inStr := OriStr;

  oriStr := '';
  repeat
   i := SearchKeyWord(inStr,'procedure');
   if i = 0 then begin end else
   begin
    oriStr := OriStr + Copy(inStr,1,i-1);
    delete(inStr,1,i-1);
    str1 := '';
    j := SearchKeyWord(inStr,'begin');
    str1 := Copy(inStr,1,j+4);
    delete(inStr,1,j+4);
    ticker := 1;
    repeat
     k := SearchKeyWord(inStr,'end');
     l := SearchKeyWord(inStr,'begin');
     if ((k < l) or (l = 0)) and (ticker >= 1) then
      begin
       str1 := str1 + Copy(inStr,1,k+3);
       delete(inStr,1,k+3);
       ticker := ticker - 1;
       if ticker = 0 then
        begin
         setFP(str1);
         str1 := '';
        end;
      end else
     if (k < l) and (ticker > 1) then
      begin
       ticker := ticker - 1;
       str1 := str1 + Copy(inStr,1,k+2);
       delete(inStr,1,k+2);
      end else
     if (k > l) and (l <> 0) then
      begin
       ticker := ticker + 1;
       str1 := str1 + Copy(inStr,1,l+4);
       delete(inStr,1,l+4);
      end;
    until ticker = 0;
   end;
  until i = 0;
  OriStr := OriStr + inStr;
  inStr := OriStr;

 end;

Procedure TProgramBody.setMain(inStr : String);
 begin
  MainScript.destroy;
  MainScript := TScript.create;
  MainScript.OnOutSideVar := GetOutVar;
  MainScript.OnSetValue := SetOutVar;
  MainScript.OnFunctionCall := FunctionCall;
  MainScript.OnLoadStream := OnLoadStream;
  MainScript.OnPlaySound := OnPlaySound;
  MainScript.setfeedIn(inStr);
  MainScript.OnShowString := OnShowString;
  MainScript.On_isVar := _isVar;
  MainScript.On_isFunction := _isFunction;

//  MainScript.compile_2;
 end;

Procedure TProgramBody.setEvent(inStr : String);
 Var
  tS1 : String;
  i : integer;
  ok : boolean;
  EventScript : TScript;
  jk,lm : integer;
  tByte : Byte;
  str3,str4 : String;
  tNumber : integer;
  vName : String;
 begin
  ok := false;
  if ESCount > 0 then
   begin
    for i := 0 to ESCount - 1 do
     begin
      ok := inStr = Event_Source[i].GetFeedIn;
      if ok then break;
     end;
    if ok then
     begin
        EventScript := TScript.create;
        EventScript.OnOutSideVar := GetOutVar;
        EventScript.OnFunctionCall := FunctionCall;
        EventScript.OnLoadStream := OnLoadStream;
        EventScript.OnPlaySound := OnPlaySound;
        EventScript.setfeedIn(inStr);
        EventScript.OnShowString := OnShowString;
        EventScript.On_isVar := _isVar;
        EventScript.On_isFunction := _isFunction;
        EventScript.OnSetValue := setOutVar;

        jk := 0;
        repeat
         lm := Event_Source[i].selfVar.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           EventScript.selfVar.AddVar(Event_Source[i].selfVar.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        jk := 0;
        repeat
         lm := Event_Source[i].indexVar.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           EventScript.indexVar.AddVar(Event_Source[i].indexVar.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        jk := 0;
        repeat
         lm := Event_Source[i].Gindex.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           EventScript.Gindex.AddVar(Event_Source[i].Gindex.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        tNumber := Event_Source[i].ScriptL(str3,str4,tByte);
        EventScript.VarIndex := str4;
        EventScript.ScriptName := str3;
        EventScript.ScriptType := tByte;
        for jk := 0 to tNumber-1 do
         EventScript.AddExecPoint(Event_Source[i].OutExecPoint(jk));

//        EventScript.compile_2;
        EventScript.Run;
//        if RunningScript.ScriptType >= 20 then
//         u := RunningScript.ReturnResult else
//         u := '';
        EventScript.destroy;
     end else
     begin
      inc(ESCount);
      setLength(Event_Source,ESCount);
      Event_Source[ESCount-1] := TScript.create;
      Event_Source[ESCount-1].OnOutSideVar := GetOutVar;
      Event_Source[ESCount-1].OnFunctionCall := FunctionCall;
      Event_Source[EsCount-1].OnLoadStream := OnLoadStream;
      Event_Source[EsCount-1].OnPlaySound := OnPlaySound;
      Event_Source[ESCount-1].setfeedIn(inStr);
      Event_Source[ESCount-1].OnShowString := OnShowString;
      Event_Source[ESCount-1].On_isVar := _isVar;
      Event_Source[ESCount-1].On_isFunction := _isFunction;
      Event_Source[ESCount-1].OnSetValue := setOutVar;
      Event_Source[ESCount-1].compile_2;
        EventScript := TScript.create;
        EventScript.OnOutSideVar := GetOutVar;
        EventScript.OnFunctionCall := FunctionCall;
        EventScript.OnLoadStream := OnLoadStream;
        EventScript.OnPlaySound := OnPlaySound;
        EventScript.setfeedIn(inStr);
        EventScript.OnShowString := OnShowString;
        EventScript.On_isVar := _isVar;
        EventScript.On_isFunction := _isFunction;
        EventScript.OnSetValue := setOutVar;

        jk := 0;
        repeat
         lm := Event_Source[ESCount-1].selfVar.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           EventScript.selfVar.AddVar(Event_Source[ESCount-1].selfVar.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        jk := 0;
        repeat
         lm := Event_Source[ESCount-1].indexVar.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           EventScript.indexVar.AddVar(Event_Source[ESCount-1].indexVar.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        jk := 0;
        repeat
         lm := Event_Source[ESCount-1].Gindex.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           EventScript.Gindex.AddVar(Event_Source[ESCount-1].Gindex.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        tNumber := Event_Source[ESCount-1].ScriptL(str3,str4,tByte);
        EventScript.VarIndex := str4;
        EventScript.ScriptName := str3;
        EventScript.ScriptType := tByte;
        for jk := 0 to tNumber-1 do
         EventScript.AddExecPoint(Event_Source[ESCount-1].OutExecPoint(jk));

//        EventScript.compile_2;
        EventScript.Run;
//        if RunningScript.ScriptType >= 20 then
//         u := RunningScript.ReturnResult else
//         u := '';
        EventScript.destroy;
     end;
   end else
   begin
    inc(ESCount);
    setLength(Event_Source,ESCount);
    Event_Source[ESCount-1] := TScript.create;
      Event_Source[ESCount-1].OnOutSideVar := GetOutVar;
      Event_Source[ESCount-1].OnFunctionCall := FunctionCall;
      Event_Source[ESCount-1].OnLoadStream := OnLoadStream;
      Event_Source[EsCount-1].OnPlaySound := OnPlaySound;
      Event_Source[ESCount-1].setfeedIn(inStr);
      Event_Source[ESCount-1].OnShowString := OnShowString;
      Event_Source[ESCount-1].On_isVar := _isVar;
      Event_Source[ESCount-1].On_isFunction := _isFunction;
      Event_Source[ESCount-1].OnSetValue := setOutVar;
      Event_Source[ESCount-1].compile_2;
        EventScript := TScript.create;
        EventScript.OnOutSideVar := GetOutVar;
        EventScript.OnFunctionCall := FunctionCall;
        EventScript.OnLoadStream := OnLoadStream;
        EventScript.OnPlaySound := OnPlaySound;
        EventScript.setfeedIn(inStr);
        EventScript.OnShowString := OnShowString;
        EventScript.On_isVar := _isVar;
        EventScript.On_isFunction := _isFunction;
        EventScript.OnSetValue := setOutVar;

        jk := 0;
        repeat
         lm := Event_Source[ESCount-1].selfVar.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           EventScript.selfVar.AddVar(Event_Source[ESCount-1].selfVar.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        jk := 0;
        repeat
         lm := Event_Source[ESCount-1].indexVar.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           EventScript.indexVar.AddVar(Event_Source[ESCount-1].indexVar.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        jk := 0;
        repeat
         lm := Event_Source[ESCount-1].Gindex.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           EventScript.Gindex.AddVar(Event_Source[ESCount-1].Gindex.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        tNumber := Event_Source[ESCount-1].ScriptL(str3,str4,tByte);
        EventScript.VarIndex := str4;
        EventScript.ScriptName := str3;
        EventScript.ScriptType := tByte;
        for jk := 0 to tNumber-1 do
         EventScript.AddExecPoint(Event_Source[ESCount-1].OutExecPoint(jk));

//        EventScript.compile_2;
        EventScript.Run;
//        if RunningScript.ScriptType >= 20 then
//         u := RunningScript.ReturnResult else
//         u := '';
        EventScript.destroy;
   end;
 end;

Procedure TProgramBody.setFP(inStr : String);
 begin
  inc(FPCount);
  setLength(F_and_P,FPCount);
  F_and_P[FPCount-1] := TScript.create;
  F_and_P[FPCount-1].OnOutSideVar := GetOutVar;
  F_and_P[FPCount-1].OnFunctionCall := FunctionCall;
  F_and_P[FPCount-1].OnLoadStream := OnLoadStream;
  F_and_P[FPCount-1].OnPlaySound := OnPlaySound;
  F_and_P[FPCount-1].setfeedIn(inStr);
  F_and_P[FPCount-1].OnShowString := OnShowString;
  F_and_P[FPCount-1].On_isVar := _isVar;
  F_and_P[FPCount-1].On_isFunction := _isFunction;
  F_and_P[FPCount-1].OnSetValue := setOutVar;
 end;

Procedure TProgramBody.RuntmpEvent(inStr : String);
 Var
  EventScript : TScript;
begin
        Running := true;
        EventScript := TScript.create;
        EventScript.OnOutSideVar := GetOutVar;
        EventScript.OnFunctionCall := FunctionCall;
        EventScript.OnLoadStream := OnLoadStream;
        EventScript.OnPlaySound := OnPlaySound;
        EventScript.setfeedIn(inStr);
        EventScript.OnShowString := OnShowString;
        EventScript.On_isVar := _isVar;
        EventScript.On_isFunction := _isFunction;
        EventScript.OnSetValue := setOutVar;
        EventScript.compile_2;
        EventScript.Run;
        //EventScript.ReturnResult
//        if RunningScript.ScriptType >= 20 then
//         u := RunningScript.ReturnResult else
//         u := '';
        EventScript.destroy;
        Running := false;
end;

Procedure TProgramBody.RunEvent(inName : String);
 Var
  i : integer;
  ok : Boolean;
  EventScript : TScript;
 begin
  {if ESCount = 0 then exit;
  ok := false;
  inName := Trim(Uppercase(inName));
  for i := 0 to ESCount - 1 do
   begin
    ok := inName = Event_Source[i].sName;
    if ok then break;
   end;
  if not ok then exit;

        EventScript := TScript.create;
        EventScript.OnOutSideVar := GetOutVar;
        EventScript.OnFunctionCall := FunctionCall;
        EventScript.setfeedIn(Event_Source[i].sSource);
        EventScript.OnShowString := OnShowString;
        EventScript.On_isVar := _isVar;
        EventScript.On_isFunction := _isFunction;
        EventScript.OnSetValue := setOutVar;
        EventScript.compile_2;
        EventScript.Run;
//        if RunningScript.ScriptType >= 20 then
//         u := RunningScript.ReturnResult else
//         u := '';
        EventScript.destroy;}
 end;

Function TProgramBody.FunctionCall(str1,str2 : String) : String;
 Var
  i : integer;
  jk,lm : integer;
  ok : Boolean;
  tmpStr : String;
  u : String;
  tmpExp : TExp;
  str3,str4,str5,t : string;
  tByte : Byte;
  FunctionScript : TScript;
  tmpVar : TVar;
  vName : String;
  tNumber : integer;
 begin
  tmpExp := TExp.create;
  tmpExp.OnGetValue := MainScript.RequestValue;
  tmpExp.OnFunctionCall := MainScript.OnFunctionCall;
  tmpStr := trim(Uppercase(str1));
  if tmpStr = 'LOADFROMFILE' then
   begin
    str3 := GetHeadString(str2,',');
    MainScript.RequestValue(str2,str4,tbyte);
    if str4[1] = '"' then delete(str4,1,1); if str4[length(str4)] = '"' then delete(str4,length(str4),1);
    MainScript.selfVar.LoadFromFile(str3,str4,tByte);
    if tByte = 255 then
     begin
      if assigned(FOnLoadStream) then
       GVars.OnLoadStream := FOnLoadStream;
      GVars.LoadFromFile(str3,str4,tByte);
     end;
    result := '';
    exit;
   end else
  if tmpStr = 'SAVETOFILE' then
   begin
    str3 := GetHeadString(str2,',');
    MainScript.RequestValue(str2,str4,tbyte);
    if str4[1] = '"' then delete(str4,1,1); if str4[length(str4)] = '"' then delete(str4,length(str4),1);
    MainScript.selfVar.SaveToFile(str3,str4,tByte);
    result := '';
    exit;
   end else
  if tmpStr = 'SYSLOADSTRINGS' then
   begin
    str3 := GetHeadString(str2,',');
    MainScript.RequestValue(str2,str4,tbyte);
    if str4[1] = '"' then delete(str4,1,1); if str4[length(str4)] = '"' then delete(str4,length(str4),1);
    MainScript.selfVar.sysLoadStrings(str3,str4,tByte);
    if tByte = 255 then
     begin
      if assigned(FOnLoadStream) then
       GVars.OnLoadStream := FOnLoadStream;
      GVars.sysLoadStrings(str3,str4,tByte);
     end;
    result := '';
    exit;
   end else
  if tmpStr = 'SYSSAVESTRINGS' then
   begin
    str3 := GetHeadString(str2,',');
    MainScript.RequestValue(str2,str4,tbyte);
    if str4[1] = '"' then delete(str4,1,1); if str4[length(str4)] = '"' then delete(str4,length(str4),1);
    MainScript.selfVar.sysSaveStrings(str3,str4,tByte);
    if tByte = 255 then
     begin
      if assigned(FOnLoadStream) then
       GVars.OnLoadStream := FOnLoadStream;
      GVars.sysSaveStrings(str3,str4,tByte);
     end;
    result := '';
    exit;
   end else
  if tmpStr = 'SYSLOADFILE' then
   begin
    //str3 := GetHeadString(str2,',');
    //MainScript.RequestValue(str2,str4,tbyte);
    //if str4[1] = '"' then delete(str4,1,1); if str4[length(str4)] = '"' then delete(str4,length(str4),1);
    MainScript.selfVar.sysLoadFile(str2,tByte);
    if tByte = 255 then
     begin
      if assigned(FOnLoadStream) then
       GVars.OnLoadStream := FOnLoadStream;
      GVars.sysLoadFile(str2,tByte);
     end;
    result := '';
    exit;
   end else
  if tmpStr = 'SYSSAVEFILE' then
   begin
    //str3 := GetHeadString(str2,',');
    //MainScript.RequestValue(str2,str4,tbyte);
    //if str4[1] = '"' then delete(str4,1,1); if str4[length(str4)] = '"' then delete(str4,length(str4),1);
    MainScript.selfVar.sysSaveFile(str2,tByte);
    if tByte = 255 then
     begin
      GVars.sysSaveFile(str2,tByte);
     end;
    result := '';
    exit;
   end else
  if tmpStr = 'EXTRALOADFROMFILE' then
   begin
    str3 := GetHeadString(str2,',');
    MainScript.RequestValue(str2,str4,tbyte);
    if str4[1] = '"' then delete(str4,1,1); if str4[length(str4)] = '"' then delete(str4,length(str4),1);
    MainScript.selfVar.ExtraLoadFromFile(str3,str4,tByte);
    if tByte = 255 then
     begin
      if assigned(FOnLoadStream) then
       GVars.OnLoadStream := FOnLoadStream;
      GVars.ExtraLoadFromFile(str3,str4,tByte);
     end;
    result := '';
    exit;
   end else
  if tmpStr = 'EXTRASAVETOFILE' then
   begin
    str3 := GetHeadString(str2,',');
    MainScript.RequestValue(str2,str4,tbyte);
    if str4[1] = '"' then delete(str4,1,1); if str4[length(str4)] = '"' then delete(str4,length(str4),1);
    MainScript.selfVar.ExtraSaveToFile(str3,str4,tByte);
    if tByte = 255 then
     begin
      GVars.ExtraSaveToFile(str3,str4,tByte);
     end;
    result := '';
    exit;
   end else
  if tmpStr = 'ARRAYX' then
   begin
    str3 := GetHeadString(str2,',');
    //i := GVars.ArrayX(str3);
    i := MainScript.selfVar.ArrayX(str3);
    if i = -1 then
     begin
      i := GVars.ArrayX(str3);
     end;
    str4 := IntToStr(i);
    MainScript.selfVar.SetValue(str2,str4,tByte);
    if tByte = 255 then
     GVars.SetValue(str2,str4,tByte);
    result := str4;
    exit;
   end else
  if tmpStr = 'ARRAYY' then
   begin
    str3 := GetHeadString(str2,',');
    i := MainScript.selfVar.ArrayY(str3);
    if i = -1 then
     begin
      i := gVars.ArrayY(str3);
     end;
    str4 := IntToStr(i);
    MainScript.selfVar.SetValue(str2,str4,tByte);
    if tByte = 255 then
     GVars.SetValue(str2,str4,tByte);
    result := str4;
    exit;
   end;
  if FPCount = 0 then
   begin
    if Assigned(FOnFunctionCall) then
     u := OnFunctionCall(str1,str2) else
     u := 'Nothing';
   end else
   begin
    ok := false;
    for i := 0 to FPCount - 1 do
     begin
      ok := tmpStr = trim(Uppercase(F_and_P[i].ScriptName));
      if ok then break;
     end;
    if ok then
     begin
      if str2 = '' then
       begin
        // if the str2 is blank, means there are no parameters feed into this function
        // or procedure...
        // the action maybe cause some global variables change, and change will be done
        // by the function/procedure itself. so just should do...

        //F_and_P[i].Run;
        //if F_and_P[i].ScriptType >= 20 then
        // u := F_and_P[i].ReturnResult else
        // u := '';

        //**** Ya, must remember it is a temporary method, in fact,
        // we can not use the F_and_P directly, it is the only original
        // copy of compiled things,
        // we should make a copy of the F_and_P and then run the copy
        // this will give us a way to support the iteration calling of function/procedure
        //**** will make modification in the future version...
        //haha... we can solve this problem at once...!

        FunctionScript := TScript.create;
        FunctionScript.OnOutSideVar := GetOutVar;
        FunctionScript.OnFunctionCall := FunctionCall;
        FunctionScript.OnLoadStream := OnLoadStream;
        FunctionScript.OnPlaySound := OnPlaySound;
        FunctionScript.setfeedIn(F_and_P[i].GetFeedIn);

        jk := 0;
        repeat
         lm := F_and_P[i].selfVar.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           FunctionScript.selfVar.AddVar(F_and_P[i].selfVar.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        jk := 0;
        repeat
         lm := F_and_P[i].indexVar.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           FunctionScript.indexVar.AddVar(F_and_P[i].indexVar.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        jk := 0;
        repeat
         lm := F_and_P[i].Gindex.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           FunctionScript.Gindex.AddVar(F_and_P[i].Gindex.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        FunctionScript.OnShowString := OnShowString;
        FunctionScript.On_isVar := _isVar;
        FunctionScript.On_isFunction := _isFunction;
        FunctionScript.OnSetValue := setOutVar;
        tNumber := F_and_P[i].ScriptL(str3,str4,tByte);
        FunctionScript.VarIndex := str4;
        FunctionScript.ScriptName := str3;
        FunctionScript.ScriptType := tByte;
        for jk := 0 to tNumber-1 do
         FunctionScript.AddExecPoint(F_and_P[i].OutExecPoint(jk));
//        FunctionScript.compile_2;
        FunctionScript.Run;
        if FunctionScript.ScriptType >= 20 then
         u := FunctionScript.ReturnResult else
         u := '';
        FunctionScript.destroy;
       end else
       begin
        // it is really difficult to treate... :(
        // the simple way just like xxxx(i,j,1.0) or something...
        // but we may meet something like xxx(i+j, sin(x),iByte)...
        // if we meet this condition, should use the TExp to calculate the value
        // of these expressions...
        FunctionScript := TScript.create;
        FunctionScript.OnOutSideVar := GetOutVar;
        FunctionScript.OnFunctionCall := FunctionCall;
        FunctionScript.OnLoadStream := OnLoadStream;
        FunctionScript.OnPlaySound := OnPlaySound;
        FunctionScript.setfeedIn(F_and_P[i].GetFeedIn);

        jk := 0;
        repeat
         lm := F_and_P[i].selfVar.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           FunctionScript.selfVar.AddVar(F_and_P[i].selfVar.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        jk := 0;
        repeat
         lm := F_and_P[i].indexVar.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           FunctionScript.indexVar.AddVar(F_and_P[i].indexVar.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        jk := 0;
        repeat
         lm := F_and_P[i].Gindex.EmunVar(jk,vName);
         if lm <> - 1 then
          begin
           FunctionScript.Gindex.AddVar(F_and_P[i].Gindex.VarOut(jk));
          end;
         inc(jk);
        until lm = -1;

        FunctionScript.OnShowString := OnShowString;
        FunctionScript.On_isVar := _isVar;
        FunctionScript.On_isFunction := _isFunction;
        FunctionScript.OnSetValue := setOutVar;
        tNumber := F_and_P[i].ScriptL(str3,str4,tByte);
        FunctionScript.VarIndex := str4;
        FunctionScript.ScriptName := str3;
        FunctionScript.ScriptType := tByte;
        for jk := 0 to tNumber - 1 do
         FunctionScript.AddExecPoint(F_and_P[i].OutExecPoint(jk));

        //FunctionScript.compile_2;
        //str2 := str2 + ',';
        str4 := FunctionScript.VarIndex;
        while str2 <> '' do
         begin
          str3 := trim(GetHeadString(str2,','));
          t := GetHeadString(str4,';');
          str5 := trim(GetHeadString(str4,';'));
          if t = 'L' then
           begin
//            tmpExp.OnGetValue := FunctionScript.RequestValue;
            tmpExp.CalcSubIndex(str3);    // jinsong modified the things that the string constant can not be a parameter...
            str3 := tmpExp.GetResult;     // who knows??? hahahaha.....

            FunctionScript.selfVar.SetValue(str5,str3,tByte);
//            RunningScript.Replace_ExecStream(str5,str3);
           end else
           begin
            if str5 <> str3 then
            FunctionScript.Replace_ExecStream(str5,str3);
           end;
         end;
        FunctionScript.Run;
        if FunctionScript.ScriptType >= 20 then
         u := FunctionScript.ReturnResult else
         u := '';
        FunctionScript.destroy;
       end;
     end else
     begin
      if Assigned(FOnFunctionCall) then
       u := OnFunctionCall(str1,str2) else
       u := 'Nothing';
     end;
   end;
  tmpExp.destroy;
  result := u;
 end;

Procedure TProgramBody.defineVar(inStr : String; oType : Byte);
 begin
  GVars.DefineVar(inStr,oType);
 end;

Procedure TProgramBody.setVarValue(inStr : String; iValue : String);
 Var
  n : Byte;
 begin
  GVars.SetValue(inStr,iValue,n);
  if n = 255 then
   begin
    // jinsong showMessage('set value failed!'+' '+inStr);
   end;
 end;

Function TProgramBody.GetVarValue(inStr : String; Var oType : Byte) : String;
 Var
  txt : String;
  ustr : String;
 begin
  txt := GVars.GetValue(inStr,oType);
  if oType = 255 then
  begin
  txt := MainScript.selfVar.GetValue(inStr,oType);
  if oType = 255 then
   begin
    if Assigned(FOnGetValue) then
     FOnGetValue(inStr,uStr,OType);
    Result := uStr;
//    Result := GVars.GetValue(inStr,oType);
   end else
  Result := txt;
  end else
  result := txt;
 end;

Procedure TProgramBody.Compile;
 Var
  i : integer;
 begin
  //if compiled then exit;
  compiled := True;
  MainScript.compile_2;
  if FPCount > 0 then
   for i := 0 to FPCount - 1 do
    F_and_P[i].compile_2;

 end;

Procedure TProgramBody.GetOutVar(inStr : String; Var OutStr : String; Var OType : Byte);
 Var
  n : Byte;
  tmpStr1 : string;
 begin
  if (inStr[1] = '@') and (Pos('.',instr)<>0) then
   begin
    delete(inStr,1,1);
    tmpStr1 := GetHeadString(inStr,'.');
    tmpStr1 := MainScript.selfVar.GetValue(tmpStr1,n);
    if n <> 255 then
     begin
      if tmpStr1[1] = '"' then
       begin
        delete(tmpStr1,1,1);
        delete(tmpStr1,length(tmpStr1),1);
       end;
     end else
     exit;
    inStr := tmpStr1 + '.' + inStr;
   end;
 OutStr := MainScript.selfVar.GetValue(inStr,OType);
 if OType = 255 then
  begin
   OutStr := GVars.GetValue(inStr,OType);
   if OType = 255 then
    begin
     if assigned(FOnGetValue) then
      OnGetValue(inStr,OutStr,OType);
    end;
  end else
  begin
  end;

  //if OType = 255 then
  //OutStr := MainScript.selfVar.GetValue(inStr,OType);
 end;

Procedure TProgramBody.Run;
 begin
  Running := true;
  MainScript.Run;
  Running := false;
 end;

end.
