unit uEngine2DExtend;
{$ZEROBASEDSTRINGS OFF}
interface
uses
  System.Classes,System.SysUtils,System.Types,System.UITypes,System.UIConsts,
  FMX.Graphics, FMX.Objects, FMX.Types, uEngine2DObject,
  uEngineConfig, System.JSON, uGeometryClasses, FMX.Dialogs;



Type

  TObjectStatus = (osStatic,osDynamic,osNone);

  {TEngine2DImage 类顾名思义，集成了图片元素的基本属性和方法}
  TEngine2DImage = class(TEngine2DObject)
    private
      FImageStatus : TObjectStatus;  // 标记对象状态（静态，动态）
      FConfig : TImageConfig;      // 记录除位置、大小等之外的其他属性 ..
      //FBitmap : TBitmap;
      FCurTick : Integer;  //记录当前帧，单位：毫秒（步长取决于引擎重绘时间）
      FWaitTick : Integer;  //记录等待时间
      FImageIndex : Integer;  //当前播放第几张图片
      FIsDelayPlay  : boolean;  // 当前是否处于延迟播放状态
      procedure MsgFromImageConfig(const S : String);
    protected


    public
      Constructor Create(AImage: TBitmap);
      Destructor Destroy;override;
      procedure Repaint;override;
      procedure ClearOldStatus;override;  // 清除旧状态
      procedure LoadConfig(AConfig : String);override;
      procedure Resize(TheParentPosition : T2DPosition);override;
      Procedure ReadFromJSONObject(Var inJObj : TJSONObject); override;
      procedure ModifyNormalBitmap;   // 正常情况下图片切换
      procedure ModifyMouseMoveBitmap; // 响应MouseMove事件 图片切换

      property ImageStatus : TObjectStatus read FImageStatus write FImageStatus;
      property ImageConfig : TImageConfig read FConfig write FConfig;
      property InitPosition : TPointF read FInitPosition write FInitPosition;
      property MouseDownPoint : TPointF read FMouseDownPoint write FMouseDownPoint;

  end;
  {TEngine2DImageEX类中的ImageConfig无须创建，为引用对象}
  TEngine2DImageEX = class(TEngine2DImage)
    private
      FConfigRef : TImageConfig;

    public
      procedure Repaint;override;

      property ImageConfig : TImageConfig read FConfigRef write FConfigRef;
  end;

  {TEngine2DText 类集成了在动画场景中显示文本信息的基本属性和方法}
  TEngine2DText = class(TEngine2DObject)
    private
      FFontFamily : String;
      FInitSize : Integer;    // 字体初始大小
      FFontSize : Integer;
      FText : String;
      FWordWrap : boolean;
      FFontColor : TAlphaColor;
      FStyle : TFontStyles;
      FTrimming : TTextTrimming;
      FHorzAlign: TTextAlign;
      FVertAlign : TTextAlign;

      procedure SetFontSize(value : Integer);
      procedure SetFontColor(value : TAlphaColor);
      procedure SetStyle(value : TFontStyles);

    public

      Constructor Create(AImage : TBitmap);
      Destructor Destroy;override;
      procedure Resize(TheParentPosition : T2DPosition);override;
      Procedure ReadFromJSONObject(Var inJObj : TJSONObject);override;
      procedure Repaint;override;

      property FontFamily : String read FFontFamily write FFontFamily;
      property FontSize : Integer read FFontSize write SetFontSize;
      property Text : String read FText write FText;
      property Style: TFontStyles read FStyle write SetStyle;
      property WordWrap : boolean read FWordWrap write FWordWrap default false;
      property FontColor : TAlphaColor read FFontColor write SetFontColor;
      property Trimming : TTextTrimming read FTrimming write FTrimming;

  end;


implementation
uses
  uEngineUtils,uPublic,uEngineAnimation;

{ TEngine2DImage }

procedure TEngine2DImage.ClearOldStatus;
begin
//  FIsMouseMove := false;
end;

constructor TEngine2DImage.Create(AImage: TBitmap);
begin
  Inherited Create(AImage);
  //FBitmap := TBitmap.Create;
  FCurTick := 0;
  FWaitTick := 0;
  FImageIndex := 0;
  FIsDelayPlay := false;
end;

destructor TEngine2DImage.Destroy;
begin
  //FBitmap.DisposeOf;
  if Assigned(FConfig) then
    FConfig.DisposeOf;
  inherited;
end;


procedure TEngine2DImage.LoadConfig(AConfig: String);
begin
end;

procedure TEngine2DImage.ModifyMouseMoveBitmap;
var
  LBmp : TBitmap;
begin
  LBmp := FConfig.MouseMovePlayControler.Item;

  if LBmp <> nil then
    begin
//      FCurTick := 0;
//      FBitmap.Clear($FF000000);
      FBitmap.Assign(LBmp);
    end;
//  Repaint;
end;

procedure TEngine2DImage.ModifyNormalBitmap;
var
  LBmp : TBitmap;
begin
//  if (FIsMouseMove) and (FConfig.MouseMovePlayControler.AnimationCount>0) then
//    exit;
  if FConfig.NormalPlayControler = nil then
    exit;
  if FConfig.NormalPlayControler.AnimationCount <=1 then
    exit;
  // 延迟播放
  if FIsDelayPlay and (FConfig.NormalPlayControler.DelayInterval > 0) then
    begin
      FWaitTick := FWaitTick + DRAW_INTERVAL;
      if FWaitTick < FConfig.NormalPlayControler.DelayInterval then
        begin
          exit;
        end else
        begin
          FIsDelayPlay := false;
        end;
    end;

  FCurTick := FCurTick + DRAW_INTERVAL;
  if FCurTick >= FConfig.NormalPlayControler.AnimationInterval then
    begin
      FCurTick := 0;
      Inc(FImageIndex);
      if FImageIndex >= FConfig.NormalPlayControler.AnimationCount then
        begin
          if FConfig.NormalPlayControler.Loop then
            begin
              FImageIndex := 0;
              FWaitTick := 0;
              FIsDelayPlay := true;
            end else
            begin
              FImageIndex := FConfig.NormalPlayControler.AnimationCount-1;
              if Assigned(FConfig.FinishProc)  then
                begin
                  FImageIndex := 0;
                  FConfig.FinishProc();
                  FConfig.FinishProc := nil;
                end;
            end;
        end;
    end;
  FConfig.SetNormalImg(FImageIndex);
end;

procedure TEngine2DImage.MsgFromImageConfig(const S : String);
begin
  FImageIndex := 0;
end;

procedure TEngine2DImage.Repaint;
var
  I : Integer;
begin
  try

    With FBitmap do
    begin
      Canvas.DrawBitmap( FConfig.NormalBitmap,
                         RectF(0,0,FConfig.NormalBitmap.Width,FConfig.NormalBitmap.Height),
                         RectF(FPosition.X, FPosition.Y, FPosition.X+FPosition.Width, FPosition.Y+FPosition.Height),
                         FOpacity,
                         true);
    end;
  finally

  end;
  inherited;
end;

procedure TEngine2DImage.Resize(TheParentPosition : T2DPosition);
begin
  //TResizeHelper.ResizeObject(Round(FBitmap.Width),Round(FBitmap.Height),Self);
  TResizeHelper.DoResize(self.Align, TheParentPosition, FPosition);
  Self.FParentPosition := TheParentPosition;
  UpdateInvadePoints;
end;

Procedure TEngine2DImage.ReadFromJSONObject(var inJObj: TJSONObject);
var
  tmpValue : TJSONValue;
  tmpArray : TJSONArray;
  tmpObject : TJSONObject;
  I : Integer;
  tmpRAnimation  : T2DRotationAnimation;
  tmpPAnimation : T2DPathAnimation;
begin
  // 首先读取一些基本的参数...
  tmpValue := inJObj.Values['Name'];
  if tmpValue <> nil then
  begin
    Self.FSpriteName := tmpValue.Value;
  end;
  tmpValue := inJObj.Values['AniType'];
  if tmpValue <> nil then
  begin
    if tmpValue.Value = '0' then
    begin
      Self.FImageStatus := osStatic;
    end else
    if tmpValue.Value = '1' then
    begin
      Self.FImageStatus := osDynamic;
    end else
    begin
      Self.FImageStatus := osNone;
    end;
  end;
  tmpValue := inJObj.Values['Align'];
  if tmpValue <> nil then
  begin
    Self.FAlign := GetAlignNew(tmpValue.Value);
  end;
  tmpValue := inJObj.Values['Visible'];
  if tmpValue <> nil then
  begin
    Self.FVisible := UpperCase(tmpValue.Value) = 'TRUE';
  end;
  tmpValue := inJObj.Values['Width'];
  if tmpValue <> nil then
  begin
    try
      FPosition.InitWidth := StrToInt(tmpValue.Value);
    except

    end;
  end;
  tmpValue := inJObj.Values['Height'];
  if tmpValue <> nil then
  begin
    try
      FPosition.InitHeight := StrToInt(tmpValue.Value);
    except

    end;
  end;
  tmpValue := inJObj.Values['PositionX'];
  if tmpValue <> nil then
  begin
    try
      FPosition.InitX := StrToInt(tmpValue.Value);
    except

    end;
  end;
  tmpValue := inJObj.Values['PositionY'];
  if tmpValue <> nil then
  begin
    try
      FPosition.InitY := StrToInt(tmpValue.Value);
    except

    end;
  end;

  tmpValue := inJObj.Values['Opacity'];
  if tmpValue <> nil then
    begin
      FOpacity := StrToFloatDef(tmpValue.Value,1);
    end;

  tmpValue := inJObj.Values['HitTest'];
  if tmpValue <> nil then
    begin
      FHitTest := UpperCase(tmpValue.Value) = 'TRUE';
    end;

  tmpValue := inJObj.Values['Drag'];
  if tmpValue <> nil then
    begin
      FDrag := UpperCase(tmpValue.Value) = 'TRUE';
    end;

  tmpValue := inJObj.Values['OnMouseDown'];
  if tmpValue <> nil then
  begin
    FOnMouseDown := G_CurrentLogic.MouseDownHandler;
  end;

  tmpValue := inJObj.Values['OnMouseMove'];
  if tmpValue <> nil then
  begin
    FOnMouseMove := G_CurrentLogic.MouseMoveHandler;
  end;

  tmpValue := inJObj.Values['OnMouseUp'];
  if tmpValue <> nil then
  begin
    FOnMouseUp := G_CurrentLogic.MouseUpHandler;
  end;

  tmpValue := inJObj.Values['OnMouseEnter'];
  if tmpValue <> nil then
  begin
    FOnMouseEnter := G_CurrentLogic.MouseEnterHandler;
  end;

  tmpValue := inJObj.Values['OnMouseLeave'];
  if tmpValue <> nil then
  begin
    FOnMouseLeave := G_CurrentLogic.MouseLeaveHandler;
  end;

  if not Assigned(Self.FConfig) then
  begin
    Self.FConfig := TImageConfig.Create(nil,FResManager);
    FConfig.OnSwitchStatus := MsgFromImageConfig;
  end;
  Self.FConfig.SourceName := Self.SpriteName;
//  FConfig.Resmanager := Self.FResManager;
  tmpValue := inJObj.Values['ImgSource'];
  if tmpValue <> nil  then
  begin
    FConfig.SetNormalImg(tmpValue.Value);
  end;
  // 读取下当前的入侵区域...
  tmpValue := inJObj.Values['InvadeArea'];
  if tmpValue <> nil then
  begin
    tmpArray := TJSONArray(tmpValue);
    if tmpArray <> nil then
    begin
      for I := 0 to tmpArray.Size - 1 do
      begin
        tmpObject := TJSONObject(tmpArray.Get(i));
        Self.AcceptAInvade(tmpObject.Values['Name'].Value,
                           tmpObject.Values['Points'].Value,
                           tmpObject.Values['InfluenceName'].Value,
                           tmpObject.Values['DstPoint'].Value
                           );
      end;
    end;
  end;

  //读取正常动画播放
  tmpValue := inJObj.Values['NormalPlay'];
  if tmpValue <> nil then
    begin
      tmpArray := TJSONArray(tmpValue);
      FConfig.LoadNormalControler(tmpArray) ;
    end;

  // 读取下Animaton  ...
  tmpArray := TJSONArray(inJObj.Values['Animation']);
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

{ TEngine2DImageEX }

procedure TEngine2DImageEX.Repaint;
begin
  try
    With FBitmap do
    begin
      Canvas.DrawBitmap( FConfigRef.NormalBitmap,
                         RectF(0,0,FConfigRef.NormalBitmap.Width,FConfigRef.NormalBitmap.Height),
                         RectF(FPosition.X, FPosition.Y, FPosition.X+FPosition.Width, FPosition.Y+FPosition.Height),
                         FOpacity,
                         true);
    end;
  finally
  end;
end;

{ TEngine2DText }

constructor TEngine2DText.Create(AImage: TBitmap);
begin
  inherited Create(AImage);

  FBitmap.Canvas.Font.Family := 'Arial';
  FBitmap.Canvas.Fill.Color := TAlphaColors.White;
  FBitmap.Canvas.Font.Size := 12;
  FBitmap.Canvas.Font.Style := [];
end;

destructor TEngine2DText.Destroy;
begin

  inherited;
end;

procedure TEngine2DText.ReadFromJSONObject(var inJObj: TJSONObject);
var
  LValue : TJSONValue;
  LS,LSubs : String;
begin
  LValue := inJObj.Values['Name'];
  if LValue <> nil then
    begin
      Self.SpriteName := LValue.Value;
    end;

  LValue := inJObj.Values['Align'];
  if LValue <> nil then
    begin
      Self.Align := GetAlignNew(LValue.Value);
    end;

  LValue := inJObj.Values['Visible'];
  if LValue <> nil then
  begin
    Self.FVisible := UpperCase(LValue.Value) = 'TRUE';
  end;

  LValue := inJObj.Values['Width'];
  if LValue <> nil then
  begin
    FPosition.InitWidth := StrToIntDef(LValue.Value,50);
  end;

  LValue := inJObj.Values['Height'];
  if LValue <> nil then
  begin
    FPosition.InitHeight := StrToIntDef(LValue.Value,50);
  end;

  LValue := inJObj.Values['PositionX'];
  if LValue <> nil then
  begin
    FPosition.InitX := StrToIntDef(LValue.Value,0);
  end;

  LValue := inJObj.Values['PositionY'];
  if LValue <> nil then
  begin
    FPosition.InitY := StrToIntDef(LValue.Value,0);
  end;

 LValue := inJObj.Values['FontColor'];
 if LValue <> nil then
   begin
     FontColor := StringToAlphaColor(LValue.Value);
   end;

 LValue := inJObj.Values['Content'];
 if LValue <> nil then
   begin
     FText := LValue.Value;
   end;

 LValue := inJObj.Values['WordWrap'];
 if LValue <> nil then
   begin
     FWordWrap := UpperCase(LValue.Value) = 'TRUE';
   end;

 LValue := inJObj.Values['HorzAlign'];
 if LValue <> nil then
   begin
     FHorzAlign := TTextAlign(StrToIntDef(LValue.Value,0));
   end;

 LValue := inJObj.Values['VerzAlign'];
 if LValue <> nil then
   begin
     FVertAlign := TTextAlign(StrToIntDef(LValue.Value,0));
   end;

 LValue := inJObj.Values['FontStyle'];
 if LValue <> nil then
   begin
     LS := LValue.Value;
     while LS <> '' do
       begin
         LSubs := GetHeadString(LS,',');
         try
           Style := Style + [TFontStyle(StrToInt(LSubs))];
         except

         end;
       end;
   end;

 LValue := inJObj.Values['FontFamily'];
 if LValue <> nil then
   begin
     FontFamily := LValue.Value;
   end;

 LValue := inJObj.Values['FontSize'];
 if LValue <> nil then
   begin
     FInitSize := StrToIntDef(LValue.Value,12) ;
   end;

end;

procedure TEngine2DText.Repaint;
begin
  try

    With FBitmap do
    begin
      Canvas.FillText(RectF(FPosition.X, FPosition.Y, FPosition.X+FPosition.Width, FPosition.Y+FPosition.Height),
                      FText,
                      FWordWrap,
                      FOpacity,
                      [TFillTextFlag.RightToLeft],
                      FHorzAlign,
                      FVertAlign);
    end;
  finally

  end;
end;

procedure TEngine2DText.Resize(TheParentPosition: T2DPosition);
var
  LSize : Integer;
begin
  LSize := FInitSize;
  TResizeHelper.DoTextResize(self.Align, TheParentPosition, FPosition, LSize);
  FontSize := LSize;
end;

procedure TEngine2DText.SetFontColor(value: TAlphaColor);
begin
  if Not Assigned(FBitmap) then exit;
  FFontColor := value;
  FBitmap.Canvas.Fill.Color := value;
end;

procedure TEngine2DText.SetFontSize(value: Integer);
begin
  if Not Assigned(FBitmap) then exit;
  FFontSize := value;
  FBitmap.Canvas.Font.Size := FFontSize;
end;

procedure TEngine2DText.SetStyle(value: TFontStyles);
begin
  if Not Assigned(FBitmap) then exit;
  FStyle := value;
  FBitmap.Canvas.Font.Style := FStyle;
end;

end.
