unit uEngineAnimation;
{$ZEROBASEDSTRINGS OFF}
{
      �����л����Ķ�����....
      ��T2DAnimationΪ�������Ծ���Ķ���������չ....
      ����Ķ�����ʵ������Ҫ�Ĺ��ܾ��Ǹ���ʱ��������ǰ��ֵ....
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
    FOwner : TObject; //Pointer;         // ���������Parent...

    FTimeDur : Integer;       // ���������Timer��ʱ����...
    FCounter : Integer;       // ��ǰ�ļ�������ֵ...
    FAnimationName : String;  // Animation�����ƣ��������ֱ��ͨ���������������Animation...
    FEnabled : Boolean;       // �Ƿ��ڼ���״̬....
    FLoop : Boolean;    // �Ƿ�ѭ������...
    FFreeOnFinish : Boolean;  // ִ����ɺ��Զ�����...
    //FOnFinish : TAnimationFinish;  // ����ִ����ɺ�ĺ���...
    FOnFinish : TProc<String>;  // ����ִ����ɺ�ĺ���...

  protected
    FOwnerClass : TClass;

    procedure SetOwner(value : TObject);
  Public

    
    Constructor Create;
    Destructor Destroy; override;
    Procedure Start; virtual;abstract;   // ��ʼ����...
    Procedure Pause; virtual;abstract;    // ��ͣ����...
    Procedure Stop; virtual;abstract;    // ��������...Stop��ʱ��ὫһЩ������ʼ��һ��,��Pause��ʱ����Ҫ...
    Procedure DoAnimation(inT : Integer); virtual; abstract;  // ִ��һ�ζ���,Ȼ��ı���Owner��ĳһЩֵ...
    
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

// ��ת����...  
Type
  T2DRotationAnimation = Class(T2DAnimation)
  Private
    FSpeed : Single;   // ��ת���ٶ�...ÿ����ٶ�....
    FStartValue : Single;  // ��ת����ʼ�Ƕ�....
    FStopValue : Single;   // ��ת�Ľ����Ƕ�....
    FCurrentValue : Single;  // ��ǰ��ֵ...
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

// λ�ƶ���...  
Type
  T2DPathAnimation = Class(T2DAnimation)  
  Private
    FStart : TPointF;     // ��������ʼ��...
    FStop : TPointF;      // �����Ľ�����...
    FCurrentPoint : TPointF;  // ������ǰ��λ��...
    FSpeed : Single;  // λ�Ƶ��ٶ�...ÿ��λ�Ƶ�����...
    FMovePoints : Array Of TPointF;   // ���е��ƶ��ĵ������...
    FTotalLength : Single;    // ����λ�Ƶ��ܳ���....
    FCurrentLength : Single;  // ��ǰ��λ�Ƴ���...���ڼ����µ�ǰ�ĵ�...

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
      // ���������ˣ�����OnFinish�¼�....
      if Assigned(FOnFinish) then
      begin
        FOnFinish(Self.Name);
      end;
    end;
  end;
  // ��������ת�ĵ�...
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
  // �������ܳ���...
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

  // ��ʼ�����µ�ǰ��λ����....
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
  // ���ݵ�ǰ��λ����������Ӧ��λ��...
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
      // �ҵ��˵�ǰ�ĵ�....
      CX := FMovePoints[I-1].X + ((FCurrentLength - TL)/DL)*(FMovePoints[i].X - FMovePoints[i-1].X);
      CY := FMovePoints[I-1].Y + ((FCurrentLength - TL)/DL)*(FMovePoints[i].Y - FMovePoints[i-1].Y);
      Break;
    end;
    TL := TL + DL;
  end;
  // ͨ��CX, CY �������µ�ǰ��ʵ�ʵ������...
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
