unit uEngineUtils;
{$ZEROBASEDSTRINGS OFF}
// **************************************************
// 关于缩放的计算Unit....
// 这里我们自己定义了一些不常见, 但是我们会用到的一些对齐方式....

interface
uses
  FMX.Types, Math, uGeometryClasses, System.SysUtils, IOUTILS,
  System.Types, System.UITypes, System.Classes, System.Variants;

Type
  TObjectAlign = (oaNone, oaTop, oaLeft, oaRight, oaScale, oaScaleMin, oaScaleMax, oaScaleMinCenter, oaScaleMaxCenter, oaClient, oaCenter, oaScaleHorzCenter, oaScaleRightBottom);

  Type
    TResizeHelper = class
      private
        class var FRefWidth : Integer;
        class var FRefHeight : Integer;
//        class procedure TreateAlignScale(var AObj : TEngine2DObject);
//        class Procedure TreateAlignClient(Var AObj : TEngine2DObject);
      public
//        class procedure ResizeObject(const RefWidth,RefHeight:Integer;AObj : TEngine2DObject);
        class Procedure DoResize(inAlign : TObjectAlign; Var inPPosition, inPosition : T2DPosition);
        class procedure DoTextResize(inAlign : TObjectAlign; Var inPPosition, inPosition : T2DPosition;var AFontSize : Integer);
    end;


   Function GetAlign(inStr : String) : TAlignLayout;
   Function GetAlignNew(inStr : String) : TObjectAlign;
   Function GetHeadString(Var inStr : String; Seperator : Char) : string;
   Procedure WriteLog(inStr : String);
   Function SplitString(const Source ,ch : String): TStringList;

 Var
   LogList : TStringList;

implementation

{ TResizeHelper }
 {
class procedure TResizeHelper.ResizeObject(const RefWidth, RefHeight: Integer;
  AObj: TEngine2DObject);
begin
  FRefWidth := RefWidth;
  FRefHeight := RefHeight;
  case AObj.Align of

    TAlignLayout.None: exit;
    TAlignLayout.Top: ;
    TAlignLayout.Left: ;
    TAlignLayout.Right: ;
    TAlignLayout.Bottom: ;
    TAlignLayout.MostTop: ;
    TAlignLayout.MostBottom: ;
    TAlignLayout.MostLeft: ;
    TAlignLayout.MostRight: ;
    TAlignLayout.Client: TreateAlignClient(AObj);
    TAlignLayout.Contents: ;
    TAlignLayout.Center: ;
    TAlignLayout.VertCenter: ;
    TAlignLayout.HorzCenter: ;
    TAlignLayout.Horizontal: ;
    TAlignLayout.Vertical: ;
    TAlignLayout.Scale: TreateAlignScale(AObj);
    TAlignLayout.Fit: ;
    TAlignLayout.FitLeft: ;
    TAlignLayout.FitRight: ;
  end;
end;   }

// 按照我们自己定义的模式来进行缩放, 调整下大小和位置...
class procedure TResizeHelper.DoResize(inAlign: TObjectAlign;  Var inPPosition, inPosition : T2DPosition);
var
  SX, SY : Single;
  NS : Single;
begin
  SX := inPPosition.Width/inPPosition.InitWidth;
  SY := inPPosition.Height/inPPosition.InitHeight;
  if inAlign = oaNone then // 0
  begin

  end else
  if inAlign = oaTop then // 1
  begin

  end else
  if inAlign = oaLeft then  //2
  begin

  end else
  if inAlign = oaRight then  //3
  begin

  end else
  if inAlign = oaScale then  //4
  begin
    inPosition.Width := inPosition.InitWidth*SX;
    inPosition.Height := inPosition.InitHeight*SY;
    inPosition.X := inPosition.InitX*SX;
    inPosition.Y := inPosition.InitY*SY;
  end else
  if inAlign = oaScaleMin then  //5
  begin

  end else
  if inAlign = oaScaleMax then     //6
  begin

  end else
  if inAlign = oaScaleMinCenter then  //7
  begin
//    SX := inPPosition.Width/inPPosition.InitWidth;
//    SY := inPPosition.Height/inPPosition.InitHeight;
    NS := min(SX, SY);
    inPosition.Width := inPosition.InitWidth*NS;
    inPosition.Height := inPosition.InitHeight*NS;
    inPosition.X := (inPosition.InitX + inPosition.InitWidth/2)*SX - inPosition.Width/2;
    inPosition.Y := (inPosition.InitY + inPosition.InitHeight/2)*SY - inPosition.Height/2;
  end else
  if inAlign = oaScaleMaxCenter then  //8
  begin

  end else
  if inAlign = oaClient then        /// 9
  begin
    InPosition.X := 0;
    inPosition.Y := 0;
    inPosition.Width := inPPosition.Width;
    inPosition.Height := inPPosition.Height;
  end else
  if inAlign = oaCenter then      // 10
  begin

  end else
  if inAlign = oaScaleHorzCenter then     //11
  begin
//    SX := inPPosition.Width/inPPosition.InitWidth;
//    SY := inPPosition.Height/inPPosition.InitHeight;
    NS := min(SX, SY);
    inPosition.Width := inPosition.InitWidth*NS;
    inPosition.Height := inPosition.InitHeight*NS;
    inPosition.X := (inPosition.InitX + inPosition.InitWidth/2)*SX - inPosition.Width/2;
    inPosition.Y := inPosition.InitY * SY;
  end else
  if inAlign = oaScaleRightBottom then   //12
  begin
    NS := min(SX, SY);
    inPosition.Width := inPosition.InitWidth*NS;
    inPosition.Height := inPosition.InitHeight*NS;
    inPosition.X := (inPosition.InitX + inPosition.InitWidth)*SX - inPosition.Width;
    inPosition.Y := (inPosition.InitY + inPosition.InitHeight)*SY - inPosition.Height;
  end;
end;

class procedure TResizeHelper.DoTextResize(inAlign: TObjectAlign;
  var inPPosition, inPosition: T2DPosition;var AFontSize: Integer);
var
  LX,LY,LMIN : Single;
begin
  DoResize(inAlign,inPPosition,inPosition);
  LX := inPPosition.Width / inPPosition.InitWidth;
  LY := inPPosition.Height / inPPosition.InitHeight;
  case inAlign of

    oaNone: ;
    oaTop: ;
    oaLeft: ;
    oaRight: ;
    oaScale: begin

      AFontSize := trunc(AFontSize * LX);

    end;
    oaScaleMin: ;
    oaScaleMax: ;
    oaScaleMinCenter: begin
      LMin := min(LX,LY);
      AFontSize := trunc(AFontSize * LMin);
    end;
    oaScaleMaxCenter: ;
    oaClient: ;
    oaCenter: ;
    oaScaleHorzCenter: ;
    oaScaleRightBottom: ;
  end;
end;

   {
class procedure TResizeHelper.TreateAlignScale(var AObj: TEngine2DObject);
begin
  AObj.X := AObj.InitX * (FRefWidth / AObj.InitParentWidth);
  AObj.Y := AObj.InitY * (FRefHeight / AObj.InitParentHeight);
  AObj.Width := AObj.InitWidth * (FRefWidth / AObj.InitParentWidth);
  AObj.Height := AObj.InitHeight * (FRefHeight / AObj.InitParentHeight);
end;

Class Procedure TResizeHelper.TreateAlignClient(var AObj: TEngine2DObject);
begin
  AObj.X := 0;
  AObj.Y := 0;
  AObj.Width := FRefWidth;
  AObj.Height := FRefHeight;
end;
     }
{}
Function GetAlign(inStr : String) : TAlignLayout;
begin
  if inStr = '0' then
  begin
    result := TALignLayout.None;
  end else
  if inStr = '1' then
  begin
    Result := TAlignLayout.Top;
  end else
  if inStr = '2' then
  begin
    Result := TAlignLayout.Left;
  end else
  if inStr = '3' then
  begin
    Result := TAlignLayout.Right;
  end else
  if inStr = '4' then
  begin
    Result := TAlignLayout.Scale;
  end else
  if inStr = '9' then
  begin
    Result := TALignLayout.Client;
  end else
  if inStr = '10' then
  begin
    Result := TAlignLayout.Contents;
  end else
  begin
    Result := TAlignLayout.None;
  end;
end;

Function GetAlignNew(inStr : String) : TObjectAlign;
var
  LIndex : Integer;
begin
  LIndex := StrToIntDef(inStr,0);
  if LIndex <= 12 then
    result := TObjectAlign(LIndex) else
    result := TObjectAlign(0);
//  if inStr = '0' then
//  begin
//    result := oaNone;
//  end else
//  if inStr = '1' then
//  begin
//    Result := oaTop;
//  end else
//  if inStr = '2' then
//  begin
//    Result := oaLeft;
//  end else
//  if inStr = '3' then
//  begin
//    Result := oaRight;
//  end else
//  if inStr = '4' then
//  begin
//    Result := oaScale;
//  end else
//  if inStr = '5' then
//  begin
//    Result := oaScaleMin;
//  end else
//  if inStr = '6' then
//  begin
//    Result := oaScaleMax;
//  end else
//  if inStr = '7' then
//  begin
//    Result := oaScaleMinCenter;
//  end else
//  if inStr = '8' then
//  begin
//    Result := oaScaleMaxCenter;
//  end else
//  if inStr = '9' then
//  begin
//    Result := oaClient;
//  end else
//  if inStr = '10' then
//  begin
//    Result := oaCenter;
//  end else
//  if inStr = '11' then
//  begin
//    Result := oaScaleHorzCenter;
//  end else
//  if inStr = '12' then
//  begin
//
//  end else
//  begin
//    Result := oaNone;
//  end;
end;

Function GetHeadString(Var inStr : String; Seperator : Char) : string;
 var
  tempstr : String;
 begin
  try
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
  tempstr := copy(inStr,1,Pos(Seperator,inStr)-1);
  delete(inStr,1,Pos(Seperator,inStr));
  result := trim(tempstr);
  except

  end;
 end;

Procedure WriteLog(inStr : String);
begin
  if not Assigned(LogList) then
  begin
    LogList := TStringList.Create;
  end;
  LogList.Add(inStr);
  {$IFDEF MSWINDOWS}

  {$ELSE}
  LogList.SaveToFile(TPath.GetPublicPath + PathDelim + 'log.txt');
  {$ENDIF}
end;

Function SplitString(const Source , ch :String) : TStringList;
var
  temp :String;
  i : Integer;
begin
  result := TStringList.Create;
  if Source = '' then exit;
  temp := Source;
  i := Pos(ch,temp);
  while i<>0 do
   begin
     result.Add(Copy(temp,1,i-1));
     Delete(temp,1,i);
     i := Pos(ch,temp);
   end;
  result.Add(temp);

end;

end.
