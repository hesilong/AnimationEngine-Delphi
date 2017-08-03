unit uEngineAnimation;
{$ZEROBASEDSTRINGS OFF}
{
      引擎中基础的动画类....
      以T2DAnimation为基础，对具体的动画进行扩展....
      这里的动画，实际上主要的功能就是根据时间计算出当前的值....
}

interface
uses
  System.Classes,System.UITypes, FMX.Types,FMX.Objects, System.JSon,
  System.SysUtils, System.Types, uEngineUtils, Math,RTTI;

Type
  TAnimationFinish = Procedure(AnimationName : String) Of Object;

Type
  T2DAnimation = Class
  Private
    FOwner : TObject; //Pointer;         // 这个动画的Parent...

    FTimeDur : Integer;       // 整个引擎的Timer的时间间隔...
    FCounter : Integer;       // 当前的计数器的值...
    FAnimationName : String;  // Animation的名称，方便后面直接通过名称来激活这个Animation...
    FEnabled : Boolean;       // 是否处于激活状态....
    FLoop : Boolean;    // 是否循环播放...
    FFreeOnFinish : Boolean;  // 执行完成后自动销毁...
    //FOnFinish : TAnimationFinish;  // 动画执行完成后的函数...
    FOnFinish : TProc<String>;  // 动画执行完成后的函数...

  protected
    FOwnerClass : TClass;

    procedure SetOwner(value : TObject);
  Public

    
    Constructor Create;
    Destructor Destroy; override;
    Procedure Start; virtual;abstract;   // 开始动画...
    Procedure Pause; virtual;abstract;    // 暂停动画...
    Procedure Stop; virtual;abstract;    // 结束动画...Stop的时候会将一些变量初始化一下,而Pause的时候不需要...
    Procedure DoAnimation(inT : Integer); virtual; abstract;  // 执行一次动画,然后改变下Owner的某一些值...
    
    property Owner : TObject read FOwner write SetOwner;
    property TimeDur : Integer Read FTimeDur Write FTimeDur;
    property Counter : Integer Read FCounter Write FCounter;
    Property Name : String Read FAnimationName Write FAnimationName;
    Property Enabled : Boolean Read FEnabled Write FEnabled;
    Property Loop : Boolean Read FLoop Write FLoop;
    Property FreeOnFinish : Boolean Read FFreeOnFinish Write FFreeOnFinish;
//    Property OnFinish : TAnimationFinish Read FOnFinish Write FOnFinish;
    property OnFinish : TProc<String> read FOnFinish write FOnFinish;
  End;

// 旋转动画...  
Type
  T2DRotationAnimation = Class(T2DAnimation)
  Private
    FSpeed : Single;   // 旋转的速度...每秒多少度....
    FStartValue : Single;  // 旋转的起始角度....
    FStopValue : Single;   // 旋转的结束角度....
    FCurrentValue : Single;  // 当前的值...
    FInitRotationPoint : TPointF;

  Public
    Constructor Create;
    Destructor Destroy; override;
    Procedure Start; override;
    Procedure Pause; Override;
    Procedure Stop; Override;
    Procedure DoAnimation(inT : Integer); Override;
    Procedure ReadFromJSON(inJObj : TJSONObject);

    Property Speed : Single Read FSpeed Write FSpeed;
    Property StartValue : Single Read FStartValue Write FStartValue;
    Property StopValue : Single Read FStopValue Write FStopValue;
    property InitRotationPoint : TPointF read FInitRotationPoint write FInitRotationPoint;
  End;

// 位移动画...  
Type
  T2DPathAnimation = Class(T2DAnimation)  
  Private
    FStart : TPointF;     // 动画的起始点...
    FStop : TPointF;      // 动画的结束点...
    FCurrentPoint : TPointF;  // 动画当前的位置...
    FSpeed : Single;  // 位移的速度...每秒位移的像素...
    FMovePoints : Array Of TPointF;   // 所有的移动的点的数组...
    FTotalLength : Single;    // 整个位移的总长度....
    FCurrentLength : Single;  // 当前的位移长度...用于计算下当前的点...

    Procedure ReadAllPoints(inStr : String);
  public
    Constructor Create;
    Destructor Destroy; override;
    Procedure Start; override;
    Procedure Pause; Override;
    Procedure Stop; Override;
    Procedure DoAnimation(inT : Integer); Override;
    Procedure ReadFromJSON(inJObj : TJSONObject);
    Procedure AddAPoint(X, Y : Single);

    Property Speed : Single Read FSpeed Write FSpeed;
    Property StartValue : TPointF Read FStart Write FStart;
    Property StopValue : TPointF Read FStop Write FStop;
  End;
  
implementation
uses
  uEngine2DSprite,uEngine2DExtend,uEngine2DObject,uGeometryClasses;

{T2DAnimation}
Constructor T2DAnimation.Create;
begin
  FTimeDur := 10;
  FCounter := 0;
  FEnabled := False;
  FLoop := False;
end;

Destructor T2DAnimation.Destroy;
begin
  Inherited;
end;

procedure T2DAnimation.SetOwner(value: TObject);
var
  LContext : TRttiContext;
  LClass : TRttiInstanceType;
begin
  FOwner := value;
  FOwnerClass := value.ClassType;
end;

{T2DRotationAnimation}
Constructor T2DRotationAnimation.Create;
begin
  Inherited;
  FInitRotationPoint := PointF(0,0);
end;

DEstructor T2DRotationAnimation.Destroy;
begin
  Inherited;
end;

Procedure T2DRotationAnimation.Start;
begin
  if not Enabled then
  begin
    Enabled := true;
  end;
end;

Procedure T2DRotationAnimation.Pause;
begin
  if Enabled then
  begin
    Enabled := False;
  end;
end;

Procedure T2DRotationAnimation.Stop;
begin
  if Enabled then
  begin
    Enabled := False;
    Counter := 0;
    FCurrentValue := FStartValue;
  end;
end;

Procedure T2DRotationAnimation.ReadFromJSON(inJObj: TJSONObject);
var
  tmpValue : TJSONValue;
  II : Integer;
begin
  tmpValue := inJObj.Values['Name'];
  if tmpValue <> nil then
  begin
    self.Name := tmpValue.Value;
  end;
  tmpValue := inJObj.Values['StartValue'];
  if tmpValue <> nil then
  begin
    try
      II := StrToInt(tmpValue.Value);
    except
      II := 0;
    end;
    Self.FStartValue := II;
  end;
  tmpValue := inJObj.Values['StopValue'];
  if tmpValue <> nil then
  begin
    try
      II := StrToInt(tmpValue.Value);
    except
      II := 0;
    end;
    Self.FStopValue := II;
  end;
  tmpValue := inJObj.Values['Speed'];
  if tmpValue <> nil then
  begin
    try
      II := StrToInt(tmpValue.Value);
    except
      II := 0;
    end;
    Self.FSpeed := II;
  end;
  tmpValue := inJObj.Values['Enabled'];
  if tmpValue <> nil then
  begin
    Self.Enabled := UpperCase(tmpValue.Value) = 'TRUE';
  end;
  tmpValue := inJObj.Values['Loop'];
  if tmpValue <> nil then
  begin
    Self.Loop := UpperCase(tmpValue.Value) = 'TRUE';
  end;
  tmpValue := inJObj.Values['RotationX'];
  if tmpValue <> nil then
  begin
    try
      FInitRotationPoint.X := StrToFloat(tmpValue.Value);
    except
      FInitRotationPoint.X := 0;
    end;
  end;
  tmpValue := inJObj.Values['RotationY'];
  if tmpValue <> nil then
  begin
    try
      FInitRotationPoint.Y := StrToFloat(tmpValue.Value);
    except
      FInitRotationPoint.Y := 0;
    end;
  end;
end;

Procedure T2DRotationAnimation.DoAnimation(inT : Integer ) ;
var
  PSprite : TEngine2DSprite;
begin
  Counter := Counter + 1;
  if Owner = nil then
    exit;
  PSprite := TEngine2DSprite(Owner);
  PSprite.RotationAngle := PSprite.RotationAngle +(FSpeed*inT)/1000*(pi/180);
  if Loop then
  begin
    if PSprite.RotationAngle >= FStopValue*pi/180 then
    begin
      PSprite.RotationAngle := PSprite.RotationAngle - FStopValue*pi/180;
    end;
  end else
  begin
    if PSprite.RotationAngle >= FStopValue*pi/180 then
    begin
      PSprite.RotationAngle := FStopValue*pi/180;
      Enabled := False;
      // 动画结束了，调用OnFinish事件....
      if Assigned(FOnFinish) then
      begin
        FOnFinish(Self.Name);
      end;
    end;
  end;
  // 计算下旋转的点...
  PSprite.RotationPoint := PointF((PSprite.Position.Width/PSprite.Position.InitWidth)*Self.FInitRotationPoint.X,
                                   (PSprite.Position.Height/PSprite.Position.InitHeight)*Self.FInitRotationPoint.Y);
end;

{T2DPathAnimation}
Constructor T2DPathAnimation.Create;
begin
  Inherited;
  SetLength(FMovePoints, 0);
end;

Destructor T2DPathAnimation.Destroy;
begin
  SetLength(FMovePoints, 0);
  Inherited;
end;

Procedure T2DPathAnimation.Start;
begin
  if not Enabled then
  begin
    Enabled := true;
  end;
end;

Procedure T2DPathAnimation.Pause;
begin
  if Enabled then
  begin
    Enabled := false;
  end;
end;

Procedure T2DPathAnimation.Stop;
begin
  if Enabled then
  begin
    Enabled := False;
    FCurrentPoint := FStart;
    Counter := 0;
  end;
end;

Procedure T2DPathAnimation.ReadFromJSON(inJObj: TJSONObject);
var
  tmpValue : TJSONValue;
  II : Integer;
begin
  tmpValue := inJObj.Values['Name'];
  if tmpValue <> nil then
  begin
    self.Name := tmpValue.Value;
  end;
  tmpValue := inJObj.Values['Loop'];
  if tmpValue <> nil then
  begin
    self.Loop := UpperCase(tmpValue.Value) = 'TRUE';
  end;
  tmpValue := inJObj.Values['Enabled'];
  if tmpValue <> nil then
  begin
    self.Enabled := UpperCase(tmpValue.Value) = 'TRUE';
  end;
  tmpValue := inJObj.Values['Speed'];
  if tmpValue <> nil then
  begin
    try
      II := StrToInt(tmpValue.Value);
    except

    end;
    Self.Speed := II;
  end;
  tmpValue := inJObj.Values['MovePoints'];
  if tmpValue <> nil then
  begin
    ReadAllPoints(tmpValue.Value);
  end;
end;

Procedure T2DPathAnimation.AddAPoint(X: Single; Y: Single);
Var
  _Len : Integer;
  I : Integer;
begin
  _Len := Length(FMovePoints);
  SetLength(FMovePoints, _Len + 1);
  FMovePoints[_Len] := PointF(X,Y);
  if length(FMovePoints) <= 1 then
  begin
    Self.FTotalLength := 0;
  end;
  FTotalLength := 0;
  for i := 1 to High(FMovePoints) do
  begin
    FTotalLength := FTotalLength + sqrt(power(FMovePoints[I].X - FMovePoints[I-1].X, 2) + Power(FMovePoints[I].Y - FMovePoints[I-1].Y, 2));
  end;
end;

Procedure T2DPathAnimation.ReadAllPoints(inStr: string);
var
  S, S1 : String;
  P1, P2 : Single;
  _Len : Integer;
  I : Integer;
begin
  SetLength(Self.FMovePoints,0);
  while inStr <> '' do
  begin
    GetHeadString(inStr,'(');
    S := GetHeadString(inStr,')');
    try
      S1 := GetHeadString(S,',');
      P1 := StrToFloat(S1);
      P2 := StrToFloat(S);
    except
      Continue;
    end;
    _Len := Length(FMovePoints);
    _Len := _Len + 1;
    SetLength(FMovePoints, _Len);
    FMovePoints[_Len-1] := PointF(P1, P2);
  end;
  // 计算下总长度...
  if length(FMovePoints) <= 1 then
  begin
    Self.FTotalLength := 0;
  end;
  FTotalLength := 0;
  for i := 1 to High(FMovePoints) do
  begin
    FTotalLength := FTotalLength + sqrt(power(FMovePoints[I].X - FMovePoints[I-1].X, 2) + Power(FMovePoints[I].Y - FMovePoints[I-1].Y, 2));
  end;
end;

Procedure T2DPathAnimation.DoAnimation(inT : Integer);
var
  I : Integer;
  DL, TL : Single;
  CX, CY : Single;
  PSprite : TEngine2DSprite;
  PImage : TEngine2DImage;
  T : TRttiType;
  P : TRttiProperty;
  R : TValue;
  LPosition : T2DPosition;
  LX,LY : Single;
  LRPosition : TValue;
begin
  if Owner = nil then
    exit;
  if not Enabled then
    exit;

  // 开始计算下当前的位移量....
  Counter := Counter + 1;
  FCurrentLength := FCurrentLength + Speed*inT/1000;
  if FCurrentLength >= FTotalLength then
  begin
    if Loop then
    begin
      while FCurrentLength > FTotalLength do
      begin
        FCurrentLength := FCurrentLength - FTotalLength;
      end;
    end else
    begin
      FCurrentLength := FTotalLength;
      Enabled := False;
      if Assigned(FOnFinish) then
      begin
        FOnFinish(Self.Name);
      end;
    end;
  end;
  // 根据当前的位移来计算相应的位置...
  TL := 0;
  CX := 0;
  CY := 0;
  for i := 1 to High(FMovePoints) do
  begin
    DL := sqrt(Power(FMovePoints[i].X - FMovePoints[i-1].X, 2) + Power(FMovePoints[i].Y - FMovePoints[i-1].Y, 2));
    if DL = 0 then
    begin
      if not Enabled then
      begin
        Enabled := False;
        if Assigned(FOnFinish) then
        begin
          FOnFinish(Self.Name);
        end;
      end;
      exit;
    end;
    if TL + DL >= FCurrentLength then
    begin
      // 找到了当前的点....
      CX := FMovePoints[I-1].X + ((FCurrentLength - TL)/DL)*(FMovePoints[i].X - FMovePoints[i-1].X);
      CY := FMovePoints[I-1].Y + ((FCurrentLength - TL)/DL)*(FMovePoints[i].Y - FMovePoints[i-1].Y);
      Break;
    end;
    TL := TL + DL;
  end;
  // 通过CX, CY 来计算下当前的实际的坐标点...
  T := TRttiContext.Create.GetType(FOwnerClass);
  P := T.GetProperty('Position');
  R := P.GetValue(FOwner);
  if R.TryAsType(LPosition) then
    begin
      LX := (LPosition.Width / LPosition.InitWidth) * CX;
      LY := (LPosition.Height / LPosition.InitHeight) * CY;
      LPosition.X := LX;
      LPosition.Y := LY;
      TValue.Make(@LPosition,TypeInfo(T2DPosition),LRPosition);
      P.SetValue(FOwner,LRPosition);
    end;

//  if Owner.ClassName.Equals('TEngine2DSprite') then
//    begin
//      PSprite := TEngine2DSprite(Owner);
//      PSprite.X := (PSprite.Position.Width/ PSprite.Position.InitWidth)*CX;
//      PSprite.Y := (PSprite.Position.Height/PSprite.Position.InitHeight)*CY;
//    end else
//  if Owner.ClassName.Equals('TEngine2DImage') then
//    begin
//      PImage := TEngine2DImage(Owner);
//      PImage.X := (PImage.Position.Width/ PImage.Position.InitWidth)*CX;
//      PImage.Y := (PImage.Position.Height/PImage.Position.InitHeight)*CY;
//    end;

end;

end.
