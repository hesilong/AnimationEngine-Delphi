unit uSTXLogic;

interface
uses
  System.Classes, System.UITypes,System.SysUtils, System.Types,System.Generics.Collections,
  FMX.Dialogs,FMX.Types, uPublic, uEngine2DModel,
  uEngine2DSprite,uEngine2DExtend,Math;

const
  ANIMATION_INTERVAL = 100;
  ANIMATION_TOTAL_COUNT = 8;
  FULL_STAR = 'x-1.png';
  HALF_STAR = 'x-3.png';
  EMPTY_STAR = 'x-2.png';
  SHOW_STAR_COUNT = 7;

Type
  TSTXLogic = class(TLogicWithStar)
  private
    FCurrentDragSprite : TEngine2DSprite;
    FDstPoint : TPointF;
    FOriDstPoint : TPointF;
    FInfluName : String;     // 待验证的精灵名
    FEntered : boolean;     //是否进入了验证区域
    FCurConfigName : String;   //当前读取的配置文件名
    FCurAniCount : Integer;   // 用于计数当前动画播放帧

    FResultMap : TDictionary<String,Integer>;

    function CheckIfFinishCurrent:boolean;
    procedure PlayAnimation(AIsRight:boolean);
    procedure OnNextTimer(Sender :TObject); override;
    procedure OnAnimationTimer(Sender : TObject);
    procedure ReadScoreFromLocal;
    procedure UpdateStarStatus;

  protected
    procedure CopySpriteFromSrc(ASprite : TEngine2DSprite);
    procedure NextSight;override;
    procedure ClearAll;
  public

    Destructor Destroy; override;
    procedure Init;override;

    procedure MouseDownHandler(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);override;
    procedure MouseMoveHandler(Sender: TObject; Shift: TShiftState; X, Y: Single);override;
    procedure MouseUpHandler(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);override;


  end;

implementation
uses
  uEngine2DInvade,uEngine2DObject,uEngineUtils,AniMain;
{ TSTXLogic }

function TSTXLogic.CheckIfFinishCurrent: boolean;
var
  item : TPair<String,Integer>;
begin
  result := true;
  for item in FResultMap do
    begin
      if item.Value = 1 then
        begin
          result := false;
          exit;
        end;
    end;

end;

procedure TSTXLogic.ClearAll;
var
  LStr,S :String;
begin
  FResultMap.Clear;
  FCurrentDragSprite := nil;
  FEntered := false;

  LStr := FIndexList.Strings[FCurIndex];
  FCurConfigName := GetHeadString(LStr,'`');
  S := GetHeadString(LStr,'`');
  while S.Trim <> '' do
    begin
      FResultMap.Add(GetHeadString(S,' '),1);
    end;
end;

procedure TSTXLogic.CopySpriteFromSrc(ASprite: TEngine2DSprite);
var
  LParentSprite : TEngine2DSprite;
  LTmpObject : TEngine2DObject;
  LSrcImage,LD1Image : TEngine2DImage;
  LTmpImage :TEngine2DImageEX;
begin
   LSrcImage := TEngine2DImage(ASprite.Children.Items[0]);
   LParentSprite := FEngineModel.SpriteList.Has('heiban');
   LD1Image := TEngine2DImage(LParentSprite.Children.Has('d1'));
   LTmpImage := TEngine2DImageEX.Create(LParentSprite.BackDrawCanvas);
   LTmpImage.SpriteName := 'cp_'+ASprite.Name;
   LTmpImage.ImageStatus := LSrcImage.ImageStatus;  //保留原Sprite的图片状态
   LTmpImage.Align := GetAlignNew('4');   //oaScale
   LTmpImage.Visible := true;
   LTmpImage.InitWidth  := ASprite.Position.InitWidth ; // 副本Sprite的初始宽度与源Srpite的初始宽度相同
   LTmpImage.InitHeight := ASprite.Position.InitHeight ;
   LTmpImage.InitX := FOriDstPoint.X ;  // 该坐标为相对于 LParentSprite的坐标
   LTmpImage.InitY := FOriDstPoint.Y ;
   LTmpImage.X := FDstPoint.X - LParentSprite.X;   //FDstPoint.X为全局坐标，LTmpImage.X的坐标为相对ParentSprite.X,所以要相减
   LTmpImage.Y := FDstPoint.Y - LParentSprite.Y;
   LTmpImage.Width := LSrcImage.Width;
   LTmpImage.Height := LSrcImage.Height;
   LTmpImage.ResManager := LSrcImage.ResManager;
   LTmpImage.InvadeManager := LSrcImage.InvadeManager;
   LTmpImage.ImageConfig := LSrcImage.ImageConfig;
   LParentSprite.Children.Add(LTmpImage.SpriteName,LTmpImage);
end;

destructor TSTXLogic.Destroy;
begin
  if Assigned(FResultMap) then
    FResultMap.DisposeOf;
//  if Assigned(FNextTimer) then
//    FNextTimer.DisposeOf;
//  if Assigned(FAnimationTimer) then
//    FAnimationTimer.DisposeOf;
  inherited;
end;

procedure TSTXLogic.Init;
var
  LStr,S :String;
begin
  if Not Assigned(FResultMap) then
     FResultMap := TDictionary<String,Integer>.Create else
     FResultMap.Clear;
  FFullStarName := FULL_STAR;
  FHalfStarName := HALF_STAR;
  FEmptyStarName := EMPTY_STAR;
  ClearAll;
  ReadScoreFromLocal;
end;

procedure TSTXLogic.MouseDownHandler(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  LSprite :TEngine2DSprite;
begin
   if Sender.ClassName.Equals('TEngine2DSprite') then
     begin
       LSprite := TEngine2DSprite(Sender);
       if LSprite.Drag then
          begin
            FEngineModel.BringToFront(LSprite);
            FCurrentDragSprite := LSprite;
          end;

     end;

end;

procedure TSTXLogic.MouseMoveHandler(Sender: TObject; Shift: TShiftState; X,
  Y: Single);
var
  LSprite : TEngine2DSprite;
  LCon : TConvexPolygon;
begin
   if Sender.ClassName.Equals('TEngine2DSprite') then
     begin
       if FCurrentDragSprite <> Sender then
         exit;
       LSprite := TEngine2DSprite(Sender);
       if (LSprite.Drag) and (LSprite.MouseIsDown) then
        begin
          LSprite.X := LSprite.InitPosition.X + (X - LSprite.MouseDownPoint.X);
          LSprite.Y := LSprite.InitPosition.Y + (Y - LSprite.MouseDownPoint.Y);
        end;
       LCon := FEngineModel.InvadeManager.GetInvadeObject(FCurrentDragSprite.GetConvexPoints);
       if (LCon <> nil) and (LCon.InfluenceName.Equals(LSprite.Name))  then
         begin
           FInfluName := LCon.InfluenceName;
           FDstPoint := LCon.DstPoint;
           FOriDstPoint := LCon.OriDstPoint;
           FEntered := true;
         end else
         begin
           FEntered := false;
           FInfluName := '';
           FDstPoint.Zero;
           FOriDstPoint.Zero;
         end;
     end;

end;

procedure TSTXLogic.MouseUpHandler(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  LSprite,LParentSprite : TEngine2DSprite;
  LTmpObject : TEngine2DObject;
  LSrcImage,LD1Image : TEngine2DImage;
  LTmpImage :TEngine2DImageEX;
begin
  if Sender.ClassName.Equals('TEngine2DSprite') then
    begin
      if FCurrentDragSprite <> Sender then
         exit;
      LSprite := TEngine2DSprite(Sender);
      if (LSprite.Drag) and (LSprite.MouseIsDown) then
       begin
         if FEntered then
           begin
             LSprite.Visible := false;
             CopySpriteFromSrc(LSprite);
             FEntered := false;
             FResultMap.AddOrSetValue(LSprite.Name,0);
             if CheckIfFinishCurrent then
               begin
                 FNextTimer.Enabled := true;
                 PlayAnimation(true);
                 PlayStarAnimationWhenDone(SHOW_STAR_COUNT);
               end;
           end else
           begin
             LSprite.CreateResetAnimation;
             PlayAnimation(false);
           end;
         LSprite.MouseIsDown := false;
       end;
      FCurrentDragSprite := nil;
    end;
end;

procedure TSTXLogic.NextSight;
begin
  inc(FCurIndex);
  if FCurIndex >= TotalCount then
    exit;
  ClearAll;
  FEngineModel.LoadNextConfig(FCurConfigName);
  inherited;
end;

procedure TSTXLogic.OnAnimationTimer(Sender: TObject);
var
  LParentSprite : TEngine2DSprite;
  L2DImage :  TEngine2DImage;
begin
//  inc(FCurAniCount);
//  if FCurAniCount > ANIMATION_TOTAL_COUNT then
//    begin
//      FCurAniCount := 0;
//      FAnimationTimer.Enabled := false;
//      LParentSprite := FEngineModel.SpriteList.Has('heiban');
//      L2DImage := TEngine2DImage(LParentSprite.Children.Has('image1'));
//      L2DImage.ImageConfig.SwitchNormalControlerByName('Normal');
//    end;

end;

procedure TSTXLogic.OnNextTimer(Sender: TObject);
begin
  FNextTimer.Enabled := false;
  NextSight;
end;

procedure TSTXLogic.PlayAnimation(AIsRight: boolean);
var
  LParentSprite : TEngine2DSprite;
  L2DImage :  TEngine2DImage;
  LFinishProc : TProc;
begin
//  if Not Assigned(FAnimationTimer) then
//    begin
//      FAnimationTimer := TTimer.Create(nil);
//      FAnimationTimer.Interval := ANIMATION_INTERVAL;
//      FAnimationTimer.OnTimer := OnAnimationTimer;
//      FAnimationTimer.Enabled := false;
//    end;
//  FCurAniCount := 0;
//  FAnimationTimer.Enabled := true;

  LParentSprite := FEngineModel.SpriteList.Has('heiban');
  L2DImage := TEngine2DImage(LParentSprite.Children.Has('image1'));

  LFinishProc := procedure
  begin
//    LParentSprite := FEngineModel.SpriteList.Has('heiban');
//    L2DImage := TEngine2DImage(LParentSprite.Children.Has('image1'));
    L2DImage.ImageConfig.SwitchNormalControlerByName('Normal',nil);
  end;


  if AIsRight  then
    L2DImage.ImageConfig.SwitchNormalControlerByName('right',LFinishProc) else
    L2DImage.ImageConfig.SwitchNormalControlerByName('wrong',LFinishProc);
//  FIsCorrect := AIsRight;
end;

//procedure TSTXLogic.PlayStarAnimationWhenDone;
//var
//  LSprite : TEngine2DSprite;
//  LPoint : TPointF;
//begin
//  inc(FStarCount);
//  if (FStarCount div 2) > SHOW_STAR_COUNT then
//    begin
//      FStarCount := SHOW_STAR_COUNT * 2;
//      exit;
//    end;
//  LSprite := UpdateASingleStarStatus(Math.Ceil(FStarCount/2.0));
//  if LSprite <> nil then
//    begin
//      LPoint.X := LSprite.Position.InitWidth/2;
//      LPoint.Y := LSprite.Position.InitHeight/2;
//      LSprite.CreateRotateAnimation(0,360,false,300,LPoint);
//    end;
//end;

procedure TSTXLogic.ReadScoreFromLocal;
begin
  FStarCount := 3;
  UpdateStarStatus;
end;

procedure TSTXLogic.UpdateStarStatus;
var
  i: Integer;
begin
  if Not Assigned(FEngineModel) then
    raise Exception.Create('FEngineModel is Not Assigned,FEngineModel Should be Used After Engine Create');
  for i := 1 to SHOW_STAR_COUNT do
    begin
      UpdateASingleStarStatus(i);
    end;
end;

Initialization

  RegisterLogicUnit(TSTXLogic,'STXLogic');

end.
