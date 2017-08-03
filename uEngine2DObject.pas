unit uEngine2DObject;
{$ZEROBASEDSTRINGS OFF}
interface
  uses
    System.Classes,System.UITypes, FMX.Types,FMX.Objects,uGeometryClasses,
    System.JSon, uEngineResource, FMX.Graphics, uEngineUtils, uEngine2DInvade,
    System.SysUtils, System.Types,uEngine2DClasses,uEngineAnimation;

const DRAW_INTERVAL = 40; // unit : ms

Type
//  TReceiveMouseEventType = (rtNone,rtAll,rtMouseDownAndUp);

  {TEngine2DObject 类是动画元素的基类，该类集成了动画元素的通用属性}
  TEngine2DObject = class
    const
      DEFAULT_WIDTH = 50;
      DEFAULT_HEIGHT = 50;
    private
      FSendToBack, FBringToFront: TNotifyEvent;
      FInvadeManager : T2DInvadeManager;
      AllInvadeData : Array Of TOriInvadePoints;

      function IsInSquare(X,Y:Single):boolean;
    protected
      FSpriteName : String; //精灵名称
      FPosition : T2DPosition;         // 当前的Object的位置和大小的参数...
      FParentPosition : T2DPosition;   // 这个Object的Parent的位置和大小的参数...
      FVisible : boolean;
      FOpacity : Single;
      FHitTest : Boolean;
      FDrag    : boolean;
      FAlign : TObjectAlign;
//      FIsMouseMove : boolean;
      FIsMouseEnter : boolean;
      FBitmap : TBitmap;
      FResManager : TEngineResManager;
      FAnimation : T2DNameList<T2DAnimation>;
      FAnimationFinishList : TStringList;  // 执行完了的动画的姓名列表....
      FMouseIsDown : Boolean;  // 是否鼠标按下了...
      FInitPosition : TPointF;  // 为了拖拽的效果，记录下初始点...
      FMouseDownPoint : TPointF;  // 鼠标Down的时候的点....

      FOnMouseDown,FOnMouseUp : TMouseEvent;
      FOnMouseMove : TMouseMoveEvent;
      FOnMouseEnter,FOnMouseLeave : TNotifyEvent;

      procedure SetInitX(value : Single);
      procedure SetInitY(value : Single);
      procedure SetX(value : Single); virtual;
      procedure SetY(value : Single); virtual;
      procedure SetRotate(value : Single); virtual;
      procedure SetScaleX(value : Single);virtual;
      procedure SetScaleY(value : Single);virtual;
      procedure SetWidth(value : Single); virtual;
      procedure SetHeight(value : Single);virtual;
      function GetWidth : Single;virtual;
      function GetHeight : Single;virtual;


    public

      Constructor Create(AImage : TBitmap);
      Destructor Destroy;override;
      procedure BringToFront;
      procedure SendToBack;
      Procedure AcceptAInvade(S1, S2, S3, S4 : String);
      Procedure UpdateInvadePoints;  // 当大小或者Visible改变的时候，更新下当前的INvade点的坐标值...
      procedure Repaint;virtual;
      procedure LoadConfig(AConfig : String);virtual;abstract;
      procedure ClearOldStatus;virtual;abstract;
      procedure Resize(TheParentPosition : T2DPosition);virtual;abstract;
      Procedure ReadFromJSONObject(Var inJObj : TJSONObject); virtual; abstract;

      function IsMouseMove(Shift: TShiftState; X,Y: Single) : Boolean;
      function IsMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single) : Boolean;
      function IsMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single) : Boolean;

      property OnMouseDown : TMouseEvent read FOnMouseDown write FOnMouseDown;
      property OnMouseUp   : TMouseEvent read FOnMouseUp write FOnMouseUp;
      property OnMouseMove : TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
      property OnBringToFront : TNotifyEvent read FBringToFront write FBringToFront;
      property OnSendToBack  : TNotifyEvent  read FSendToBack write FSendToBack;

      property Position : T2DPosition read FPosition write FPosition;
      property X : Single read FPosition.X write SetX;
      property Y : Single read FPosition.Y write SetY;
      property InitX : Single read FPosition.InitX write SetInitX;
      property InitY : Single read FPosition.InitY write SetInitY;
      property ScaleX : Single read FPosition.ScaleX write SetScaleX;
      property ScaleY : Single read FPosition.ScaleY write SetScaleY;
      property Rotate : Single read FPosition.Rotate write SetRotate;
      property Width : Single read GetWidth write SetWidth;
      property Height : Single read GetHeight write SetHeight;
      property InitWidth : Single read FPosition.InitWidth write FPosition.InitWidth;
      property InitHeight: Single read FPosition.InitHeight write FPosition.InitHeight;
      property InitParentWidth : Single read FParentPosition.InitWidth ;     // 这个Object的Parent的大小设置为只读选项，实际上这个Object也没有权限改变Parent 的大小...
      property InitParentHeight : Single read FParentPosition.InitHeight;
      property Opacity : Single read FOpacity write FOpacity;
      property Align : TObjectAlign read FAlign write FAlign;
      property SpriteName : String read FSpriteName write FSpriteName;
      property Visible : boolean read FVisible write FVisible;
      Property HitTest : Boolean Read FHitTest Write FHitTest;
      property Drag : boolean read FDrag write FDrag;
      property ResManager : TEngineResManager Read FResManager Write FResManager;
      Property InvadeManager : T2DInvadeManager Read FInvadeManager Write FInvadeManager;
  end;

implementation

{ TEngine2DObject }

procedure TEngine2DObject.BringToFront;
begin
  if Assigned(FBringToFront) then
    FBringToFront(Self);
end;

constructor TEngine2DObject.Create(AImage : TBitmap);
begin
  FBitmap := AImage;
  FPosition.Zero;
  FParentPosition.Zero;
  FVisible := false;
  FOpacity := 1;
  FAlign := oaNone;
//  FIsMouseMove := false;
  FIsMouseEnter := false;
  FHitTest := false;
  FDrag := false;
  FMouseIsDown := false;
  FAnimation := T2DNameList<T2DAnimation>.Create;
  FAnimationFinishList := TStringList.Create;
  SetLength(AllInvadeData, 0);
end;

destructor TEngine2DObject.Destroy;
begin
  SetLength(AllInvadeData, 0);
  FAnimation.DisposeOf;
  FAnimationFinishList.DisposeOf;
  inherited;
end;

function TEngine2DObject.GetHeight: Single;
begin
  result := FPosition.Height;
end;

function TEngine2DObject.GetWidth: Single;
begin
  result := FPosition.Width;
end;

function TEngine2DObject.IsInSquare(X, Y: Single): boolean;
begin
  result := false;
  x := x - Position.X;
  if x < 0 then  exit;

  if x > FPosition.Width then exit;

  y := y - Position.Y;
  if y < 0 then exit;
  if y > FPosition.Height then exit;

  result := True;
end;

function TEngine2DObject.IsMouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Single): Boolean;
begin
 result := false;

 if not FVisible then
  exit;

 if not FHitTest then exit;

 if not IsInSquare(X, Y) then exit;

 if not assigned(FOnMouseDown) then
  exit;

 FMouseIsDown := true;

 FMouseDownPoint := PointF(X, Y);
// if FDrag then
//  begin
//    Self.FInitPosition := PointF(X,Y);
//  end;
 FOnMouseDown(Self, Button, Shift, X, Y);

 result := true;
end;

function TEngine2DObject.IsMouseMove(Shift: TShiftState; X, Y: Single): Boolean;
begin
  result := false;
  if not FVisible then exit;

  if not FHitTest then exit;

  if not IsInSquare(X, Y) then
    begin
      if FIsMouseEnter then
        begin
          FIsMouseEnter  := false;
          if Assigned(FOnMouseLeave) then
            FOnMouseLeave(Self);
        end;
      exit;
    end;

  if not FIsMouseEnter then
    begin
      FIsMouseEnter := true;
      if Assigned(FOnMouseEnter) then
        FOnMouseEnter(Self);
    end;
  if Assigned(FOnMouseMove) then
    FOnMouseMove(Self, Shift, X, Y);

//  FIsMouseMove := true;
  result := true;
end;

function TEngine2DObject.IsMouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Single): Boolean;
begin
  result := false;
 if not FVisible then
  exit;

 FMouseIsDown := false;

 if not FHitTest then exit;

 if not IsInSquare(X,Y) then exit;


 if not assigned(FOnMouseUp) then
  exit;

 FOnMouseUp(Self, Button, Shift, X, Y);

 result := true;
end;

procedure TEngine2DObject.Repaint;
var
  I : Integer;
  S : String;
  tmpAnimation : T2DAnimation;
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
      FAnimation.Items[i].DoAnimation(DRAW_INTERVAL);
    end;
  end;
end;

procedure TEngine2DObject.SendToBack;
begin
  if Assigned(FSendToBack) then
    FSendToBack(Self);
end;

Procedure TEngine2DObject.AcceptAInvade(S1: string; S2: string;S3 :String; S4:String);
Var
  _Len, _Len1 : Integer;
  XX, YY : Integer;
  S : String;
begin
  _Len := Length(Self.AllInvadeData);
  _Len := _Len + 1;
  SetLength(AllInvadeData, _Len);
  AllInvadeData[_Len-1].FName := S1;
  AllInvadeData[_Len-1].InfluenceName := S3;
  if S4 <> '' then
    begin
      GetHeadString(S4,'(');
      S := GetHeadString(S4,')');
      XX := StrToIntDef(GetHeadString(S,','),0);
      YY := StrToIntDef(S,0);
      AllInvadeData[_Len-1].DstOriPoints := PointF(XX + FPosition.InitX ,YY + FPosition.InitY);
      AllInvadeData[_Len-1].DstCurPoints := PointF(XX,YY);
    end;
  _Len1 := 0;
  while S2 <> '' do
  begin
    GetHeadString(S2,'(');
    S := GetHeadString(S2,')');
    try
      XX := StrToInt(GetHeadString(S,','));
      YY := StrToInt(S);
    except
      continue;
    end;
    _Len1 := _Len1 + 1;
    SetLength(AllInvadeData[_Len-1].FPoints, _Len1);
    AllInvadeData[_Len-1].FPoints[_Len1-1] := PointF(XX, YY);
  end;
end;

Procedure TEngine2DObject.UpdateInvadePoints;
Var
  I, J : Integer;
  S,S1 : String;
  XX, YY : Integer;
  DX, DY : Single;
  AllPoints : Array of TPointF;
begin
  if not FVisible then
  begin
    exit;
  end;
  if Self.Align = oaClient then
  begin
    DX := Self.FParentPosition.Width/Self.FParentPosition.InitWidth;
    DY := Self.FParentPosition.Height/Self.FParentPosition.InitHeight;
  end else
  begin
    DX := Self.Position.Width/Self.Position.InitWidth;
    DY := Self.Position.Height/Self.Position.InitHeight;
  end;
  for I := 0 to High(AllInvadeData) do
  begin
    for J := 0 to High(AllInvadeData[I].FPoints) do
    begin
      SetLength(AllPoints, J+1);
      AllPoints[J].X := AllInvadeData[I].FPoints[J].X*DX + Self.Position.X + Self.FParentPosition.X;
      AllPoints[J].Y := AllInvadeData[I].FPoints[J].Y*DY + Self.Position.Y + Self.FParentPosition.Y;
    end;
    AllInvadeData[I].DstCurPoints.X := (AllInvadeData[I].DstOriPoints.X - FPosition.InitX)*DX + Self.Position.X + Self.FParentPosition.X;
    AllInvadeData[I].DstCurPoints.Y := (AllInvadeData[I].DstOriPoints.Y - FPosition.InitY)*DY + Self.Position.Y + Self.FParentPosition.Y;
    if FInvadeManager <> nil then
    begin
      FInvadeManager.UpdateAnINvadeData(AllInvadeData[I].FName,
                                        AllInvadeData[I].InfluenceName,
                                        AllPoints,
                                        AllInvadeData[I].DstOriPoints,
                                        AllInvadeData[I].DstCurPoints);
    end;
  end;
  SetLength(AllPoints, 0);
end;

procedure TEngine2DObject.SetHeight(value: Single);
begin
  FPosition.Height := value;
end;

procedure TEngine2DObject.SetInitX(value: Single);
begin
  FPosition.InitX := value;
end;

procedure TEngine2DObject.SetInitY(value: Single);
begin
  FPosition.InitY := value;
end;

procedure TEngine2DObject.SetRotate(value: Single);
begin
  FPosition.Rotate := value;
end;

procedure TEngine2DObject.SetScaleX(value: Single);
begin
  FPosition.ScaleX := value;
end;

procedure TEngine2DObject.SetScaleY(value: Single);
begin
  FPosition.ScaleY := value;
end;

procedure TEngine2DObject.SetWidth(value: Single);
begin
  FPosition.Width := value;
end;

procedure TEngine2DObject.SetX(value: Single);
begin
  FPosition.X := value;
end;

procedure TEngine2DObject.SetY(value: Single);
begin
  FPosition.Y := value;
end;

end.
