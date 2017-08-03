unit uEngine2DSprite;
{$DEFINE TEST}
{$ZEROBASEDSTRINGS OFF}
interface
uses
  FMX.Objects,System.Math.Vectors,FMX.Types,uEngine2DObject,uEngine2DExtend, uEngine2DClasses,
  System.JSON, System.SysUtils, FMX.Dialogs, uEngineResource, FMX.Graphics,
  System.Types, uEngineUtils, uGeometryClasses, uEngineAnimation, uEngineConfig,
  System.Classes, System.UITypes, Math, uEngine2DInvade, NewScript;

{TEngine2DSprite 类负责动画逻辑的解析，动画资源的加载，动画内容的管理}
Type
  TEngine2DSprite = class

    private
      FImage : TBitmap;
      FSpriteName : String;
//      FEngineObject : TEngine2DObject;
      FVisible : Boolean;
      FScaleX : Single;
      FScaleY : Single;
      BackDrawBuffer : TBitmap;   // 负责这个Sprite的画布....
      FHitTest : Boolean;
      FRotationAngle : Single;   // 旋转的角度....
      FRotationPoint : TPointF;  // 旋转中心点...
      FChildren : T2DNameList<TEngine2DObject>;
      FAnimation : T2DNameList<T2DAnimation>;
      FResManager : TEngineResManager;
      FAlign : TObjectAlign;    // 对齐的方式....
      FPosition : T2DPosition;   // 当前这个Sprite的大小和位置....
      FParentPosition : T2DPosition;  // 这个Sprite的Parent(既最外面的画布的大小和位置(位置为0，0))...
      FOnMouseDown,FOnMouseUp : TMouseEvent;
      FOnMouseMove : TMouseMoveEvent;
      FOnMouseEnter,FOnMouseLeave : TNotifyEvent;
      FDrag : Boolean;   // 这个Sprite是否可以被拖拽....
      FAutoReset : Boolean;  // 如果有拖拽功能的时候，是否有自动复位的功能...
      FMouseIsDown : Boolean;  // 是否鼠标按下了...
      FInitPosition : TPointF;  // 为了拖拽的效果，记录下初始点...
      FMouseDownPoint : TPointF;  // 鼠标Down的时候的点....
      FAnimationFinishList : TStringList;  // 执行完了的动画的姓名列表....
      FInvadeManager : T2DInvadeManager;   // 入侵检测的Manager,这个是由Engine创建的,这里只做引用...
      FIsMouseEnter : boolean;     // 标记鼠标是否进入

      Procedure SetWidth(AWidth : Single);
      Procedure SetHeight(AHeight : Single);
      Function CreateAName(inType : Integer) : String;
      Procedure AnimationFinish(inName : String);   // 一个动画执行完毕后的回调函数...


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

      Procedure CreateResetAnimation;   // 创建可以复位的动画...
      procedure CreateRotateAnimation(AStartValue,AStopValue:Integer;ALoop:boolean;ASpeed:Integer;ARotate : TPointF);  // 创建旋转的动画...
      procedure CreateMoveAnimation(AStartPos, AEndPos : TPointF; AFinishProc : TProc);  // 创建位移动画，两个点需在同一坐标系下

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
      property BackDrawCanvas : TBitmap read BackDrawBuffer;  // 画布
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
  // 检查下执行完成了动画...
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
          // 如果这个动画自动销毁的话，那么在这里直接进行销毁...
          FAnimation.Remove(S);
        end;
      end;
    end;
    FAnimationFinishList.Clear;
  end;
  // 检查下动画...
  for I := 0 to FAnimation.ItemCount - 1 do
  begin
    if FAnimation.Items[i].Enabled then
    begin
      FAnimation.Items[i].DoAnimation(TimeDur);
    end;
  end;
  //绘图矩阵变换
  Matrix := TMatrix.CreateTranslation(-1*(FPosition.X + FRotationPoint.X), -1*(FPosition.Y + FRotationPoint.Y))*
            TMatrix.CreateRotation(FRotationAngle)*
            TMatrix.CreateScaling(FScaleX, FScaleY)*
            TMatrix.CreateTranslation(FPosition.X + FRotationPoint.X, FPosition.Y + FRotationPoint.Y);
  FImage.Canvas.SetMatrix(Matrix);
  // 首先将Sprite中的所有的Children都画在画布上...
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
  // 根据当前的对其方式，计算下当前的大小和位置....
  FParentPosition.Width := AWidth;
  FParentPosition.Height := AHeight;
  TResizeHelper.DoResize(Self.FAlign, FParentPosition, FPosition);

  // 将BackDrawBuffer的大小改变下...
  BackDrawBuffer.Width := Round(FPosition.Width);
  BackDrawBuffer.Height := Round(FPosition.Height);
  // 然后计算下当前所有的Children的Resize事件....
  for i := 0 to FChildren.ItemCount - 1 do
  begin
    tmpObject := FChildren.Items[i];
    if tmpObject <> nil then
    begin
      tmpObject.Resize(FPosition);
    end;
  end;
end;

//从一个JSON Object中获取这个Sprite需要的所有的元素....
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
  // 首先读取下Sprite的基本信息...

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

  // 接下来，读取Children的基本信息....
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

  // 读取下Animaton  ...
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
    // 检查下所有的children, 看下是否有鼠标事件...
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
    // 如果本身没有HitTest属性的话,那么就看下Children有没有HitTest属性....
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
    // 给Children自动生成一个名字...
    for i := 0 to FChildren.ItemCount - 1 do
    begin

    end;
  end else
  if inType = 2 then
  begin
    // 给Animation自动生成一个名字...
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
  // 涉及到一些动画在执行完成后需要自动释放, 所以先将执行完成的动画放在这个列表里面，
  //  在Repaint的时候增加一个检查，检查下是否有动画执行完成了，完成了需要自动释放...
  FAnimationFinishList.Add(inName);
end;

Procedure TEngine2DSprite.CreateResetAnimation;
Var
  tmpPAnimation : T2DPathAnimation;
  dx, dy : Single;
  LAnimationFinish : TProc<String>; //TAnimationFinish;
begin
  // 如果只是鼠标点击了下，没有位移, 那么就不处理了...
  if (X = FInitPosition.X) and (Y = FInitPosition.Y) then
    exit;
  // 有位移的时候，处理下...
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
