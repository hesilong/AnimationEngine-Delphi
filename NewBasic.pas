unit NewBasic;

interface
uses
  Windows, Messages, SysUtils, UITypes,Classes, vcl.Graphics, fmx.Controls, fmx.Forms, fmx.Dialogs,
  fmx.StdCtrls, fmx.ExtCtrls,  {CoolGraphButton, VerticalListContainer, BasicClass,}
  ShellAPI, fmx.Menus{, BookM, GifImage, VGShap};

type
  TNewAlignStyle = (asNone,asLeft,asRight,asCenter,asLeftRight);
  TLineAlign = (laTop, laBottom, laCenter);
  TLineAlignMethod = (lamLeft, lamRight, lamCenter, lamBoth);

  TLoadStream = Procedure(inStr : String; Var DataStored : TMemoryStream; stype : Byte) of Object;
  TPlaySound = Procedure(inStr : String) of Object;
  TSendOut = procedure (Var Msg : String) of Object;
  TSendMessage = procedure (Var Msg : String ) of Object;
  TCallDraw    = procedure of Object;
  TGetInteger = procedure (Var OutInteger : integer) of Object;
  TGetImage = Procedure(TheP : TBitMap; theLink : String) of Object;
  TGetCanvas = Procedure(Var theCanvas : TBitMap) of Object;
  TSendMapMsg = Procedure(MapName : String; Msgtype : Byte; Msg : String) of Object;
  TCreateInput = Procedure(formname : string; Var name : String; Left,Top,Width,Height : integer; stype : Byte; value : String) of Object;
  TGetStream = Procedure(inStr : String; theStream : TMemoryStream) of Object;
  TRequestObject = Procedure(ObjType : Byte; Var Obj : Pointer) of Object;
  TRequestMap = Procedure(MapName : String; Var theMap : Pointer) of Object;
  TRequestStyle = Procedure(StyleName : String; Var theStyle : Pointer) of Object;
  // 0 : TMemo, 1 : PopUpMenu, 2 : TTimer, 3 : TEdit, 4 ... other...

  TOnObjectChange = Procedure( Sender : TObject; Var ObjectDes : Pointer; ChangeIndex : Byte; sOType : Byte) of Object;
  TOnLeftString = Procedure(Sender : TObject; LeftString : String) of Object;

type
  TAttributeNode = Class
  private

  public
   Name : String;
   Value : String;
   sType : Byte;
   Constructor create(inStr : String);
   Destructor Destroy; override;
 end;

 TAttributeList = class(TStringList)
  private
  public
   Destructor destroy; override;
   Procedure Clear; override;
   Procedure SetContent(inStr : String; Seperator : Char);
   Function GetValueByName(inName : String) : String;
 end;

Function GetHeadString(Var inStr : String; Seperator : Char) : string;
Function myPos(SubStr : String; inStr : String; cPos : integer) : integer;
Function LeftTagPos(SubStr,inStr : String; cPos : integer) : integer;
Function myPairPos(str1,str2 : String; inStr : String; cPos : Integer) : integer;

implementation

Function GetHeadString(Var inStr : String; Seperator : Char) : string;
 var
  tempstr : String;
 begin
  inStr := trim(inStr);
  if inStr = '' then
   begin
    result := '';
    exit;
   end;
  if Pos(Seperator,inStr) = 0 then
   begin
    result := inStr;
    inStr := '';
    exit;
   end;
  if inStr[1] = '"' then
   begin
    delete(inStr,1,1);
    tempstr := Copy(inStr,1,Pos('"',inStr));
    tempstr := '"' + tempstr;
    delete(inStr,1,Pos('"',inStr));
   end else
    tempstr := copy(inStr,1,Pos(Seperator,inStr)-1);
  delete(inStr,1,Pos(Seperator,inStr));
  result := tempstr;
 end;

Function myPos(SubStr : String; inStr : String; cPos : integer) : integer;
Var
 t : integer;
begin
 delete(inStr,1,cPos-1);
 t := Pos(SubStr,inStr);
 if t = 0 then result := 0 else
 result := cPos + t - 1;
end;

Function LeftTagPos(SubStr,inStr : String; cPos : integer) : integer;
Var
 i : integer;
 xPos : integer;
 c : char;
begin
 // this function return the position of string that should be <xx xxxx xxx> or <xx>,
 // so the subStr maybe "<xx", and I must find out the first position that "<xx " or "<xx>"
 // appears...
 xPos := 0;
 delete(inStr,1,cPos);
 repeat
  i := Pos(SubStr,inStr);
  if i = 0 then
   begin
    result := 0;
    exit;
   end;
  if (i + length(subStr)) >= length(inStr) then
   begin
    result := i + xPos + cPos;
    exit;
   end;
  c := inStr[i+length(SubStr)];
  if not(c in [' ','>',#13,#10,#9]) then
   begin
    xPos := xPos + i + length(SubStr);
    delete(inStr,1,i + length(SubStr));
   end else
   begin
    result := i + xPos + cPos;
    exit;
   end;
 until (i = 0) or (inStr = '');
 result := 0;
end;

Function myPairPos(Str1, Str2 : string; inStr : String; cPos : integer) : integer;
Var
 i,j : integer;
 counter : integer;

begin

 counter := 1;
 delete(inStr,1,cPos-1);
 repeat
  i := LeftTagPos(str1,inStr,0);
  j := pos(str2,inStr);
  if i = 0 then
   begin
    if j = 0 then
     begin
      result := 0; exit;
     end else
     begin
      if counter = 0 then
       begin
        result := cPos + j-1;
        exit;
       end else
       begin
        counter := counter - 1;
        if counter = 0 then
         begin
          result := cPos + j-1;
          exit;
         end;
        delete(instr,1,j + length(str2)-1);
        cPos := cPos + j + length(str2) - 1;
       end;
     end;
   end else
  if j < i then
   begin
    if counter = 0 then
     begin
      result := cPos + j-1 ;
      exit;
     end else
     begin
      counter := counter - 1;
      if counter = 0 then
       begin
        result := cPos + j -1;
        exit;
       end;
      delete(inStr,1,j+length(str2)-1);
      cpos := cPos + j + length(str2)-1;
     end;
   end else
   begin
    counter := counter + 1;
    delete(inStr,1,i + length(str1)-1);
    cpos := cpos + i + length(str1)-1;
   end;
 until counter = 0;
 result := 0;
end;

Destructor TAttributeList.destroy;
 Var
  i : integer;
 begin
  if Count = 0 then begin end else
   for I := 0 to Count - 1 do
     TAttributeNode(Objects[i]).DisposeOf;
  inherited;
 end;

Procedure TAttributeList.Clear;
 Var
  i : integer;
  tmpItem : TAttributeNode;
 begin
  for i := 0 to Count - 1 do
   begin
    tmpItem := TAttributeNode(Objects[i]);
    tmpItem.DisposeOf;
   end;
  inherited;
 end;

Procedure TAttributeList.SetContent(inStr : String; Seperator : Char);
 Var
  s1,s2 : string;
  tmpItem : TAttributeNode;
 begin
  if inStr = '' then exit;
  if Pos('=',inStr) = 0 then exit;
  repeat
   s1 := trim(GetHeadString(inStr,'='));
   inStr := trim(inStr);
   //if (s1 <> '') and (Pos('=',inStr) = 0) then
   // begin
   //  s2 := inStr;
   //  inStr := '';
   // end else
   s2 := trim(GetHeadString(inStr,Seperator));
   inStr := trim(inStr);
   if s2[1] = '"' then system.delete(s2,1,1);
   if s2[Length(s2)] = '"' then system.delete(s2,Length(s2),1);
   tmpItem := TAttributeNode.create(s1);
   AddObject('',tmpItem);
   tmpItem.Name := s1;
   tmpItem.Value := s2;
  until inStr = '';
 end;

Function TAttributeList.GetValueByName(inName : String) : String;
 Var
  s1 : string;
  tmpNode : TAttributeNode;
  i : integer;
  ok : Boolean;
 begin
  if Count = 0 then begin result := ''; exit; end;
  ok := false;
  inName := Uppercase(inName);
  for i := 0 to Count - 1 do
   begin
    tmpNode := TAttributeNode(Objects[i]);
    ok := inName = Uppercase(tmpNode.Name);
    if ok then break;
   end;
  if ok then result := tmpNode.Value else
  result := '';
 end;

Constructor TAttributeNode.create(inStr : String);
 begin
  inherited create;
  if inStr = '' then
   begin
    Name := '';
    Value := '';
    sType := 255;
   end else
  if Pos('=',inStr) = 0 then
   begin
    Name := '';
    Value := '';
    sType := 255;
   end else
   begin
    inStr := trim(inStr);
    Name := trim(GetHeadString(inStr,'='));
    Value := trim(inStr);
    sType := 0;
   end;
 end;

Destructor TAttributeNode.Destroy;
 begin
  inherited;
 end;

end.
