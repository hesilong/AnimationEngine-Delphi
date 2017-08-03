unit uEngine2DSprite;
{$DEFINE TEST}
{$ZEROBASEDSTRINGS OFF}
interface
uses
  FMX.Objects,System.Math.Vectors,FMX.Types,uEngine2DObject,uEngine2DExtend, uEngine2DClasses,
  System.JSON, System.SysUtils, FMX.Dialogs, uEngineResource, FMX.Graphics,
  System.Types, uEngineUtils, uGeometryClasses, uEngineAnimation, uEngineConfig,
  System.Classes, System.UITypes, Math, uEngine2DInvade, NewScript;

{TEngine2DSprite �ฺ�𶯻��߼��Ľ�����������Դ�ļ��أ��������ݵĹ���}
Type
  TEngine2DSprite = class

    private
      FImage : TBitmap;
      FSpriteName : String;
//      FEngineObject : TEngine2DObject;
      FVisible : Boolean;
      FScaleX : Single;
      FScaleY : Single;
      BackDrawBuffer : TBitmap;   // �������Sprite�Ļ���....
      FHitTest : Boolean;
      FRotationAngle : Single;   // ��ת�ĽǶ�....
      FRotationPoint : TPointF;  // ��ת���ĵ�...
      FChildren : T2DNameList<TEngine2DObject>;
      FAnimation : T2DNameList<T2DAnimation>;
      FResManager : TEngineResManager;
      FAlign : TObjectAlign;    // ����ķ�ʽ....
      FPosition : T2DPosition;   // ��ǰ���Sprite�Ĵ�С��λ��....
      FParentPosition : T2DPosition;  // ���Sprite��Parent(��������Ļ����Ĵ�С��λ��(λ��Ϊ0��0))...
      FOnMouseDown,FOnMouseUp : TMouseEvent;
      FOnMouseMove : TMouseMoveEvent;
      FOnMouseEnter,FOnMouseLeave : TNotifyEvent;
      FDrag : Boolean;   // ���Sprite�Ƿ���Ա���ק....
      FAutoReset : Boolean;  // �������ק���ܵ�ʱ���Ƿ����Զ���λ�Ĺ���...
      FMouseIsDown : Boolean;  // �Ƿ���갴����...
      FInitPosition : TPointF;  // Ϊ����ק��Ч������¼�³�ʼ��...
      FMouseDownPoint : TPointF;  // ���Down��ʱ��ĵ�....
      FAnimationFinishList : TStringList;  // ִ�����˵Ķ����������б�....
      FInvadeManager : T2DInvadeManager;   // ���ּ���Manager,�������Engine������,����ֻ������...
      FIsMouseEnter : boolean;     // �������Ƿ����

      Procedure SetWidth(AWidth : Single);
      Procedure SetHeight(AHeight : Single);
      Function CreateAName(inType : Integer) : String;
      Procedure AnimationFinish(inName : String);   // һ������ִ����Ϻ�Ļص�����...


    public
      Constructor Create(AImage :TBitmap);
      Destructor Destroy;override;

      Procedure Repaint(TimeDur : Integer);
      Procedure Resize(AWidth, AHeight : Single);
      Procedure ReadFromJSON(Var inJObject : TJSONObject);
      Procedure SetParentSize(AWidth, AHeight : Single);
      Procedure ClearOldStatus;
      procedure UpdateSpriteBackground;
      Function GetConvexPoints : TPointsCollection;

      function IsMouseMove(Shift: TShiftState; InX,InY: Single) : Boolean;
      function IsMouseUp(Button: TMouseButton; Shift: TShiftState; InX, InY: Single) : Boolean;
      function IsMouseDown(Button: TMouseButton; Shift: TShiftState; InX, InY: Single) : Boolean;
      Function IsInSquare(InX, InY : Single) : Boolean;
      Procedure DrawMousePosition(InX, InY : Single);
      procedure BringToFront(Sender : TObject);

      Procedure CreateResetAnimation;   // �������Ը�λ�Ķ���...
      procedure CreateRotateAnimation(AStartValue,AStopValue:Integer;ALoop:boolean;ASpeed:Integer;ARotate : TPointF);  // ������ת�Ķ���...
      procedure CreateMoveAnimation(AStartPos, AEndPos : TPointF; AFinishProc : TProc);  // ����λ�ƶ���������������ͬһ����ϵ��

      Property Name : String Read FSpriteName write FSpriteName;
      Property Visible : Boolean read FVisible Write FVisible;
      Property Width : Single Read FPosition.Width Write SetWidth;
      Property Height : Single Read FPosition.Height Write SetHeight;
      Property ScaleX : Single Read FScaleX Write FScaleY;
      Property ScaleY : Single Read FScaleY Write FScaleY;
      Property X : Single Read FPosition.X Write FPosition.X;
      Property Y : Single Read FPosition.Y Write FPosition.Y;
      property InitX : Single read FPosition.InitX write FPosition.InitX;
      property InitY : Single read FPosition.InitY write FPosition.InitY;
      property InitWidth : Single read FPosition.InitWidth write FPosition.InitWidth;
      property InitHeight : Single read FPosition.InitHeight write FPosition.InitHeight;
      Property HitTest : Boolean Read FHitTest Write FHitTest;
      Property RotationAngle : Single Read FRotationAngle Write FRotationAngle;
      Property RotationPoint :TPointF Read FRotationPoint Write FRotationPoint;
      Property Image : TBitmap Read FImage Write FImage;
      Property ResManager : TEngineResManager Read FResManager Write FResManager;
      Property Position : T2DPosition Read FPosition write FPosition;
      Property ParentPosition : T2DPosition Read FParentPosition;
      property InitPosition : TPointF read FInitPosition write FInitPosition;
      property MouseDownPoint : TPointF read FMouseDownPoint write FMouseDownPoint;
      property Align : TObjectAlign read FAlign write FAlign;
      property MouseIsDown : boolean read FMouseIsDown write FMouseIsDown;
      property OnMouseDown : TMouseEvent read FOnMouseDown write FOnMouseDown;
      property OnMouseUp   : TMouseEvent read FOnMouseUp write FOnMouseUp;
      property OnMouseMove : TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
      property OnMouseEnter : TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
      property OnMouseLeave : TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
      Property Drag : Boolean Read FDrag Write FDrag;
      Property InvadeManager : T2DInvadeManager Read FInvadeManager Write FInvadeManager;
      property Children : T2DNameList<TEngine2DObject> read FChildren;
      property BackDrawCanvas : TBitmap read BackDrawBuffer;  // ����
  end;

implementation
uses
  uPublic;

{ TEngine2DSprite }

constructor TEngine2DSprite.Create(AImage: TBitmap);
begin
  FImage := AImage;
  FScaleX := 1;
  FScaleY := 1;
  FRotationAngle := 0;
  FChildren := T2DNameList<TEngine2DObject>.Create;
  FAnimation := T2DNameList<T2DAnimation>.Create(true);
  BackDrawBuffer := TBitmap.Create;
  FPosition.Zero;
  FParentPosition.Zero;
  FDrag := False;
  FMouseIsDown := False;
  FIsMouseEnter := false;
  FAnimationFinishList := TStringList.Create;
end;

destructor TEngine2DSprite.Destroy;
begin
//  if Assigned(FEngineObject) then
//    FEngineObject.DisposeOf;
  FChildren.DisposeOf;
  FAnimation.DisposeOf;
  BackDrawBuffer.DisposeOf;
  FAnimationFinishList.DisposeOf;
  inherited;
end;

Procedure TEngine2DSprite.Repaint(TimeDur : Integer);
Var
  I : Integer;
  tmpObj : TEngine2DObject;
  WW, Hh : Integer;
  S : String;
  tmpAnimation : T2DAnimation;
  Matrix : TMatrix;
begin
  // �����ִ������˶���...
  if FAnimationFinishList.Count > 0 then
  begin
    for I := 0 to FAnimationFinishList.Count - 1 do
    begin
      S := FAnimationFinishList.Strings[i];
      tmpAnimation := FAnimation.Has(S);
      if tmpAnimation <> nil then
      begin
        if tmpAnimation.FreeOnFinish then
        begin
          // �����������Զ����ٵĻ�����ô������ֱ�ӽ�������...
          FAnimation.Remove(S);
        end;
      end;
    end;
    FAnimationFinishList.Clear;
  end;
  // ����¶���...
  for I := 0 to FAnimation.ItemCount - 1 do
  begin
    if FAnimation.Items[i].Enabled then
    begin
      FAnimation.Items[i].DoAnimation(TimeDur);
    end;
  end;
  //��ͼ����任
  Matrix := TMatrix.CreateTranslation(-1*(FPosition.X + FRotationPoint.X), -1*(FPosition.Y + FRotationPoint.Y))*
            TMatrix.CreateRotation(FRotationAngle)*
            TMatrix.CreateScaling(FScaleX, FScaleY)*
            TMatrix.CreateTranslation(FPosition.X + FRotationPoint.X, FPosition.Y + FRotationPoint.Y);
  FImage.Canvas.SetMatrix(Matrix);
  // ���Ƚ�Sprite�е����е�Children�����ڻ�����...
  BackDrawBuffer.Canvas.BeginScene();
  try
    {$IFDEF MSWINDOWS}
    BackDrawBuffer.Canvas.Clear($00000000);
    {$ELSE}
    BackDrawBuffer.Canvas.Clear($00000000);
    {$ENDIF}
    if Self.FChildren.ItemCount > 0 then
    begin
      for I := 0 to Self.FChildren.ItemCount - 1 do
      begin
        tmpObj := Self.FChildren.Items[i];
        if tmpObj.Visible then
        begin
          tmpObj.Repaint;
        end;
      end;
    end;
  Finally
    BackDrawBuffer.Canvas.EndScene;
  end;
  FImage.Canvas.DrawBitmap(BackDrawBuffer, RectF(0,0,BackDrawBuffer.Width, BackDrawBuffer.Height), RectF(FPosition.X, FPosition.Y, FPosition.X + FPosition.Width, FPosition.Y + FPosition.Height),1, true);
end;

Procedure TEngine2DSprite.Resize(AWidth, AHeight : Single);
Var
  SX, SY : Single;
  I : Integer;
  tmpObject : TEngine2DObject;
begin
  // ���ݵ�ǰ�Ķ��䷽ʽ�������µ�ǰ�Ĵ�С��λ��....
  FParentPosition.Width := AWidth;
  FParentPosition.Height := AHeight;
  TResizeHelper.DoResize(Self.FAlign, FParentPosition, FPosition);

  // ��BackDrawBuffer�Ĵ�С�ı���...
  BackDrawBuffer.Width := Round(FPosition.Width);
  BackDrawBuffer.Height := Round(FPosition.Height);
  // Ȼ������µ�ǰ���е�Children��Resize�¼�....
  for i := 0 to FChildren.ItemCount - 1 do
  begin
    tmpObject := FChildren.Items[i];
    if tmpObject <> nil then
    begin
      tmpObject.Resize(FPosition);
    end;
  end;
end;

//��һ��JSON Object�л�ȡ���Sprite��Ҫ�����е�Ԫ��....
Procedure TEngine2DSprite.ReadFromJSON(var inJObject: TJSONObject);
const
 ss = 'var s : string; begin s := "Q1"; @self.setopa(s,1); end;';
 ss1 = 'var s : string; begin s := "Q1"; @self.setopa(s,0.8); end;';

var
  tmpValue : TJSONValue;
  tmpArray : TJSONArray;
  I : Integer;
  tmpObject : TJSONObject;
  tmpImage : TEngine2DImage;
  LText : TEngine2DText;
  tmpRAnimation  : T2DRotationAnimation;
  tmpPAnimation : T2DPathAnimation;

begin
  // ���ȶ�ȡ��Sprite�Ļ�����Ϣ...

  tmpValue := inJObject.Values['SpriteName'];

  if tmpValue <> nil then
  begin
    Self.FSpriteName := tmpValue.Value;
  end;

  tmpValue := inJObject.Values['Width'] ;
  if tmpValue <> nil then
  begin
    Self.FPosition.InitWidth := StrToIntDef(tmpValue.Value,50);
  end;

  tmpValue := inJObject.Values['Height'];
  if tmpValue <> nil then
  begin
    Self.FPosition.InitHeight := StrToIntDef(tmpValue.Value,50);
  end;

  BackDrawBuffer.Width := Round(FPosition.Width);
  BackDrawBuffer.Height := Round(FPosition.Height);

  tmpValue := inJObject.Values['PositionX'];
  if tmpValue <> nil then
  begin
    FPosition.InitX := StrToIntDef(tmpValue.Value,0);
  end;

  tmpValue := inJObject.Values['PositionY'];
  if tmpValue <> nil then
  begin
    FPosition.InitY := StrToIntDef(tmpValue.Value,0);
  end;

  tmpValue := inJObject.Values['Visible'];
  if tmpValue <> nil then
  begin
    FVisible := UpperCase(tmpValue.Value) = 'TRUE';
  end;

  tmpValue := inJObject.Values['HitTest'];
  if tmpValue <> nil then
  begin
    FHitTest := UpperCase(tmpValue.Value) = 'TRUE';
  end;

  tmpValue := inJObject.Values['Align'];
  if tmpValue <> nil then
  begin
    FAlign := GetAlignNew(tmpValue.Value);
  end;

  tmpValue := inJObject.Values['Drag'];
  if tmpValue <> nil then
  begin
    FDrag := UpperCase(tmpValue.Value) = 'TRUE';
  end;

  tmpValue := inJObject.Values['AutoReset'];
  if tmpValue <> nil then
  begin
    FAutoReset := UpperCase(tmpValue.Value) = 'TRUE';
  end;

  tmpValue := inJObject.Values['OnMouseDown'];
  if tmpValue <> nil then
  begin
    FOnMouseDown := G_CurrentLogic.MouseDownHandler;
  end;

  tmpValue := inJObject.Values['OnMouseMove'];
  if tmpValue <> nil then
  begin
    FOnMouseMove := G_CurrentLogic.MouseMoveHandler;
  end;

  tmpValue := inJObject.Values['OnMouseUp'];
  if tmpValue <> nil then
  begin
    FOnMouseUp := G_CurrentLogic.MouseUpHandler;
  end;

  tmpValue := inJObject.Values['OnMouseEnter'];
  if tmpValue <> nil then
  begin
    FOnMouseEnter := G_CurrentLogic.MouseEnterHandler;
  end;

  tmpValue := inJObject.Values['OnMouseLeave'];
  if tmpValue <> nil then
  begin
    FOnMouseLeave := G_CurrentLogic.MouseLeaveHandler;
  end;

  // ����������ȡChildren�Ļ�����Ϣ....
  tmpArray := TJSONArray(inJObject.Values['Children']);
  if tmpArray <> nil then
  begin
    for i := 0 to tmpArray.Size - 1 do
    begin
      tmpObject := TJSONObject(tmpArray.Get(i));
      if tmpObject <> nil then
      begin
        tmpValue := tmpObject.Values['Type'];
        if tmpValue <> nil then
        begin
          if tmpValue.Value = 'Image' then
          begin
            tmpImage := TEngine2DImage.Create(Self.BackDrawBuffer);
            tmpImage.ResManager := Self.FResManager;
            tmpImage.InvadeManager := Self.InvadeManager;
            tmpImage.ReadFromJSONObject(tmpObject);
            Self.FChildren.Add(tmpImage.SpriteName, tmpImage);
          end else
          if tmpValue.Value = 'Text' then
          begin
             LText := TEngine2DText.Create(Self.BackDrawBuffer);
             LText.ReadFromJSONObject(tmpObject);
             Self.FChildren.Add(LText.SpriteName,LText);
          end;
        end;
      end;
    end;
  end;

  // ��ȡ��Animaton  ...
  tmpArray := TJSONArray(inJObject.Values['Animation']);
  if tmpArray <> nil then
  begin
    for i := 0 to tmpArray.Size-1 do
    begin
      tmpObject := TJSONObject(tmpArray.Get(i));
      if tmpObject <> nil then
      begin
        tmpValue := tmpObject.Values['Type'];
        if tmpValue <> nil then
        begin
          if tmpValue.Value = 'Rotation' then
          begin
            tmpRAnimation := T2DRotationAnimation.Create;
            tmpRAnimation.ReadFromJSON(tmpObject);
            tmpRAnimation.TimeDur := DRAW_INTERVAL;
            tmpRAnimation.Owner := Self;
            FAnimation.Add(tmpRAnimation.Name, tmpRAnimation);
          end else
          if tmpValue.Value = 'Path' then
          begin
            tmpPAnimation := T2DPathAnimation.Create;
            tmpPAnimation.ReadFromJSON(tmpObject);
            tmpPAnimation.TimeDur := Draw_INTERVAL;
            tmpPAnimation.Owner := Self;
            FAnimation.Add(tmpPAnimation.Name, tmpPAnimation);
          end;
        end;
      end;
    end;
  end;

end;

Procedure TEngine2DSprite.SetParentSize(AWidth: Single; AHeight: Single);
begin
  FParentPosition.InitWidth := AWidth;
  FParentPosition.InitHeight := AHeight;
end;

procedure TEngine2DSprite.BringToFront(Sender: TObject);
Var
  LIndex : Integer;
begin
  LIndex := FChildren.IndexOf(TEngine2DObject(Sender));
  FChildren.Exchange(LIndex,FChildren.ItemCount-1);
end;

Procedure TEngine2DSprite.ClearOldStatus;
begin
  FMouseIsDown := False;
end;

Function TEngine2DSprite.GetConvexPoints : TPointsCollection;
begin
  result := [PointF(Position.X, Position.Y), PointF(Position.X + Position.Width, Position.Y), PointF(Position.X + Position.Width, Position.Y + Position.Height), PointF(Position.X, Position.Y + Position.Height)];
end;

Function TEngine2DSprite.IsMouseMove(Shift: TShiftState; InX: Single; InY: Single) : Boolean;
var
  i: Integer;
begin
  result := False;
  if not Visible then
    exit;
  if not IsInSquare(InX, InY) then
    begin
      if FIsMouseEnter then
        begin
          FIsMouseEnter  := false;

          if Assigned(FOnMouseLeave) then
            FOnMouseLeave(Self);
        end;
      exit;
    end;

  if not HitTest then
  begin
    // ��������е�children, �����Ƿ�������¼�...
    for i := FChildren.ItemCount-1 to 0 do
      begin
        if FChildren.Items[i].IsMouseMove(Shift, InX - FPosition.X,InY - FPosition.Y) then
          begin
            result := true;
            exit;
          end;
      end;
  end else
  begin
    if Not FIsMouseEnter then
      begin
        FIsMouseEnter := true;
        if Assigned(FOnMouseEnter) then
          FOnMouseEnter(Self);
      end;
    if Assigned(FOnMouseMove) then
     begin
      FOnMouseMove(Self,Shift,InX,InY);
     end;
    result := true;
  end;

end;

Function TEngine2DSprite.IsMouseUp(Button: TMouseButton; Shift: TShiftState; InX: Single; InY: Single) : Boolean;
Var
  OriMouseDown : Boolean;
  i : Integer;
begin
  result := False;
  if not Visible then
    exit;
//  OriMouseDown := FMouseIsDown;
//  FMouseIsDown := False;

  if not IsInSquare(InX, InY) then
  begin
    exit;
  end;
  if not HitTest then
  begin
    for i := FChildren.ItemCount-1 downto 0 do
      begin
        FChildren.Items[i].IsMouseUp(Button, Shift, InX - FPosition.X,InY - FPosition.Y);
      end;
  end else
  begin
    //
//    if (FDrag) and (OriMouseDown) then
//    begin
//      CreateResetAnimation;
//    end;
    if Assigned(FOnMouseUp) then
      FOnMouseUp(Self,Button,Shift,InX,InY);
  end;
  result := true;
end;

Function TEngine2DSprite.IsMouseDown(Button: TMouseButton; Shift: TShiftState; InX: Single; InY: Single) : Boolean;
Var
  I : Integer;
  ok : Boolean;
begin
  result := False;
  if not Visible then
    exit;

  if not IsInSquare(InX, InY) then
  begin
    exit;
  end;
  if not HitTest then
  begin
    // �������û��HitTest���ԵĻ�,��ô�Ϳ���Children��û��HitTest����....
    for I := FChildren.ItemCount-1 downto 0 do
    begin
      if FChildren.Items[i].IsMouseDown(Button, Shift, InX - FPosition.X, InY - FPosition.Y) then
        begin
          result := true;
          exit;
        end;
    end;
  end else
  begin
    FMouseIsDown := true;
    FMouseDownPoint := PointF(InX, InY);
    if FDrag then
    begin
      Self.FInitPosition := PointF(X,Y);
    end;
    if Assigned(FOnMouseDown) then
      FOnMouseDown(Self,Button,Shift,InX,InY);
    result := true;
  end;

end;

Function TEngine2DSprite.IsInSquare(InX: Single; InY: Single) : Boolean;
begin
  result := false;
  if (InX >= Self.X) and (InY >= Self.Y) and (InX <= Self.X + Self.Width) and (InY <= Self.Y + Self.Height) then
  begin
    result := true;
  end;
end;

Procedure TEngine2DSprite.DrawMousePosition(InX: Single; InY: Single);
begin
  if (FDrag) and (FMouseIsDown) then
  begin
    X := FInitPosition.X + (InX - FMouseDownPoint.X);
    Y := FInitPosition.Y + (InY - FMouseDownPoint.Y);
  end;
end;

Procedure TEngine2DSprite.SetWidth(AWidth: Single);
begin
  if FPosition.Width <> AWidth then
  begin
    FPosition.Width := AWidth;
  end;
end;

procedure TEngine2DSprite.UpdateSpriteBackground;
var
  i: Integer;
  LObject : TEngine2DObject;
begin
  for i := 0 to FChildren.ItemCount-1 do
    begin
      LObject := FChildren.Items[i];
      if LObject.Visible then
        begin
          if LObject.ClassName.Equals('TEngine2DImage') then
             begin
               TEngine2DImage(LObject).ModifyNormalBitmap;
             end;
        end;
    end;
end;

Procedure TEngine2DSprite.SetHeight(AHeight: Single);
begin
  if FPosition.Height <> AHeight then
  begin
    FPosition.Height := AHeight;
  end;
end;

Function TEngine2DSprite.CreateAName(inType : Integer) : String;
Var
  I : Integer;
  tmpObject : TEngine2DObject;
  S : String;
begin
  if inType = 1 then
  begin
    // ��Children�Զ�����һ������...
    for i := 0 to FChildren.ItemCount - 1 do
    begin

    end;
  end else
  if inType = 2 then
  begin
    // ��Animation�Զ�����һ������...
    I := 1;
    while true do
    begin
      S := 'Animation'+IntToStr(I);
      if FAnimation.Contains(S) then
      begin
        I := I + 1;
      end else
      begin
        Break;
      end;
    end;
  end;
  result := S;
end;

procedure TEngine2DSprite.CreateMoveAnimation(AStartPos, AEndPos: TPointF;
  AFinishProc: TProc);
Var
  tmpPAnimation : T2DPathAnimation;
  dx, dy : Single;
  LAnimationFinish : TProc<String>;
begin
  dx := Position.InitWidth/Position.Width;
  dy := Position.InitHeight/Position.Height;

  tmpPAnimation := T2DPathAnimation.Create;
  tmpPAnimation.Name := Self.CreateAName(2);
  tmpPAnimation.Loop := False;

  LAnimationFinish := procedure(AAnimationName:String)
  begin
    FAnimationFinishList.Add(AAnimationName);
    if Assigned(AFinishProc)  then
      AFinishProc;
  end;

  tmpPAnimation.OnFinish := LAnimationFinish;// AnimationFinish;

  tmpPAnimation.Speed := 2*sqrt(power(AStartPos.X * dx - AEndPos.X * dx, 2) + Power(AStartPos.Y * dy - AEndPos.Y * dy, 2));
  tmpPAnimation.FreeOnFinish := true;
  tmpPAnimation.AddAPoint(AStartPos.X * dx, AStartPos.Y * dy);
  tmpPAnimation.AddAPoint(AEndPos.X * dx, AEndPos.Y * dy);
  tmpPAnimation.Enabled := true;
  tmpPAnimation.Owner := Self;
  FAnimation.Add(tmpPAnimation.Name, tmpPAnimation);
end;

Procedure TEngine2DSprite.AnimationFinish(inName: string);
begin
  // �漰��һЩ������ִ����ɺ���Ҫ�Զ��ͷ�, �����Ƚ�ִ����ɵĶ�����������б����棬
  //  ��Repaint��ʱ������һ����飬������Ƿ��ж���ִ������ˣ��������Ҫ�Զ��ͷ�...
  FAnimationFinishList.Add(inName);
end;

Procedure TEngine2DSprite.CreateResetAnimation;
Var
  tmpPAnimation : T2DPathAnimation;
  dx, dy : Single;
  LAnimationFinish : TProc<String>; //TAnimationFinish;
begin
  // ���ֻ����������£�û��λ��, ��ô�Ͳ�������...
  if (X = FInitPosition.X) and (Y = FInitPosition.Y) then
    exit;
  // ��λ�Ƶ�ʱ�򣬴�����...
  CreateMoveAnimation(PointF(X,Y), FInitPosition, nil);

//  dx := Position.InitWidth/Position.Width;
//  dy := Position.InitHeight/Position.Height;
//  tmpPAnimation := T2DPathAnimation.Create;
//  tmpPAnimation.Name := Self.CreateAName(2);
//  tmpPAnimation.Loop := False;
//
//  LAnimationFinish := procedure(AAnimationName:String)
//  begin
//    FAnimationFinishList.Add(AAnimationName);
//  end;
//
//  tmpPAnimation.OnFinish := LAnimationFinish;// AnimationFinish;
//
//  tmpPAnimation.Speed := 2*sqrt(power(X*dx - FInitPosition.X*dx, 2) + Power(Y*dy - FInitPosition.Y*dy, 2));
//  tmpPAnimation.FreeOnFinish := true;
//  tmpPAnimation.AddAPoint(X*dx, Y*dy);
//  tmpPAnimation.AddAPoint(FInitPosition.X*dx, FInitPosition.Y*dy);
//  tmpPAnimation.Enabled := true;
//  tmpPAnimation.Owner := Self;
//  FAnimation.Add(tmpPAnimation.Name, tmpPAnimation);

end;

procedure TEngine2DSprite.CreateRotateAnimation(AStartValue,
  AStopValue: Integer; ALoop: boolean; ASpeed: Integer; ARotate: TPointF);
var
  LRAnimation : T2DRotationAnimation;
  LAnimationFinish : TProc<String>;
begin
  LRAnimation := T2DRotationAnimation.Create;
  FRotationAngle := AStartValue;

  LAnimationFinish := procedure(AAnimationName:String)
  begin
    FAnimationFinishList.Add(AAnimationName);
  end;

  With LRAnimation do
  begin
    Name := CreateAName(2);
    Loop := ALoop;
    OnFinish :=  LAnimationFinish ;//AnimationFinish;
    StartValue := AStartValue;
    StopValue := AStopValue;
    Speed := 300;
    FreeOnFinish := true;
    InitRotationPoint := ARotate;
    Enabled := true;
    Owner := Self;
  end;
  FAnimation.Add(LRAnimation.Name,LRAnimation);
end;

end.
