unit uEngine;
{$ZEROBASEDSTRINGS OFF}
interface
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math.Vectors,System.JSON, DateUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,FMX.Objects,
  uEngine2DModel, uEngine2DSprite, uEngineUtils, uEngineThread,
  uEngineResource, NewScript;

{TEngine2D类负责场景内容的重绘，统一管理各模块}
Type
  TEngine2D = class(TShape)
    private
      ScriptE : TScript;
      FMouseEnterScript : String;
      FMouseLeaveScript : String;
      FMouseUpScript : String;
      FMouseMoveScript : String;
      FMouseDownScript : String;

    private
      FEngineTimer : TTimer;
      FEngineModel : TEngine2DModel;
      FResManager :  TEngineResManager;
      FImage: TImage;  // 画布 ...
      FThread : TEngineThread;
      FBackground : TBitmap;
      FDrawBuffer : TBitmap;
      FWidth : Single;
      FHeight : Single;
      FTime : TDateTime;

      FOnMouseDown,FOnMouseUp : TMouseEvent;
      FOnMouseMove : TMouseMoveEvent;

      procedure SetImage(const Value: TImage);
      procedure SetHeight(value : Single);

      procedure MouseDown(Button: TMouseButton;
          Shift: TShiftState; x, y: single); override;
      procedure MouseUp(Button: TMouseButton;
          Shift: TShiftState; x, y: single); override;
      procedure MouseMove(Shift: TShiftState; X,
          Y: Single);  override;

    protected
      procedure Draw(Sender : TObject);
      procedure UpdateSpriteBitmap;
      Procedure Paint; Override;
    public
      Constructor Create(AOwner : TComponent);
      Destructor Destroy;override;

      procedure LoadAnimation(AConfigName:String; AResManager : TEngineResManager);
      procedure Resize(const AWidth, AHeight: Integer);
      Procedure ThreadWork;

      property IMGCanvas : TImage read FImage write SetImage;
      property Background : TBitmap Read FBackground;
      Property DrawBuffer : TBitmap Read FDrawBuffer;
      property EngineModel : TEngine2DModel read FEngineModel;
      property OnMouseDown : TMouseEvent read FOnMouseDown write FOnMouseDown;
      property OnMouseUp   : TMouseEvent read FOnMouseUp write FOnMouseUp;
      property OnMouseMove : TMouseMoveEvent read FOnMouseMove write FOnMouseMove;

  end;


var
  G_Engine : TEngine2D;

implementation
uses
  uEngineConfig,uEngine2DObject,uPublic;

{ TEngine2D }

constructor TEngine2D.Create(AOwner : TComponent);
begin
  Inherited;
  FEngineTimer := TTimer.Create(nil);
  FEngineTimer.Interval := DRAW_INTERVAL;
  FEngineTimer.OnTimer := Draw;
  FEngineTimer.Enabled := false;
  FEngineModel := TEngine2DModel.Create;
  FBackground := TBitmap.Create;
  FDrawBuffer := TBitmap.Create;
//  FCurrentInvadedName := '';
  //FThread := TEngineThread.Create(true);
end;

destructor TEngine2D.Destroy;
begin
  FEngineTimer.DisposeOf;
  FEngineModel.DisposeOf;
  FBackground.DisposeOf;
  FDrawBuffer.DisposeOf;
  //FThread.Terminate;
  inherited;
end;

procedure TEngine2D.Draw(Sender: TObject);
var
  LMatrix, Matrix : TMatrix;
  i, J: Integer;
  LCount : Integer;
  TimeDur : Integer;
  tmpP : TPointF;
begin
  // draw sprite
  TimeDur := Round(abs(MilliSecondSpan(FTime, Now)));
  FTime := Now;
  UpdateSpriteBitmap;

  With FDrawBuffer do
  begin
    Canvas.BeginScene();
    try
      Canvas.Clear($00000000);
      LMatrix := Canvas.Matrix;
      Canvas.DrawBitmap(FBackground,
                        RectF(0,0,FBackground.Width,FBackground.Height),
                        RectF(0,0,FWidth,FHeight),1, true);
      LCount := FEngineModel.SpriteCount;
      if LCount > 0 then
        begin
          for i := 0 to LCount-1 do
            begin
              if FEngineModel.SpriteList.Items[i].Visible then
                begin
                  FEngineModel.SpriteList.Items[i].Repaint(TimeDur);
                end;
            end;
        end;
       // draw star
       LCount := FEngineModel.StarSpriteCount;
       if LCount > 0 then
        begin
          for i := 0 to LCount-1 do
            begin
              if FEngineModel.StarSpriteList.Items[i].Visible then
                begin
                  FEngineModel.StarSpriteList.Items[i].Repaint(TimeDur);
                end;
            end;
        end;
       Canvas.SetMatrix(LMatrix);
       // 将可入侵区域画出来，这样可以测试的时候用一下...
//       if FEngineModel.InvadeManager.FConvexPolygon.ItemCount > 0 then
//       begin
//         for I := 0 to FEngineModel.InvadeManager.FConvexPolygon.ItemCount-1 do
//         begin
//           if 'ID2' = FEngineModel.InvadeManager.FConvexPolygon.Items[I].Name then
//           begin
//             Canvas.Stroke.Color := TAlphaColors.Red;
//             Canvas.Fill.Color := TAlphaColors.Red;
//           end else
//           begin
//             Canvas.Stroke.Color := TAlphaColors.Black;
//             Canvas.Fill.Color := TAlphaColors.Black;
//           end;
//           for J := 0 to High(FEngineModel.InvadeManager.FConvexPolygon.Items[i].AllPoints) do
//           begin
//             tmpP := FEngineModel.InvadeManager.FConvexPolygon.Items[i].AllPoints[j];
//             //Canvas.DrawEllipse(RectF(tmpP.X-2, tmpP.Y - 2, tmpP.X+2, tmpP.Y+2),1);
//             Canvas.FillEllipse(RectF(tmpP.X-2, tmpP.Y - 2, tmpP.X+2, tmpP.Y+2),1);
//           end;
//         end;
//       end;

    finally

      Canvas.EndScene;
    end;

  end;
  Repaint;
end;

procedure TEngine2D.LoadAnimation(AConfigName:String; AResManager : TEngineResManager);
var
  LBackgroundName : String;
//  LObject : TJSONObject;
  LValue : String;
begin
  FResManager := AResManager;
  FResManager.UpdateConfig(AConfigName);

  LBackgroundName := FResManager.GetJSONValue('Background');
  FResManager.LoadResource(FBackground, LBackgroundName);
  LValue := FResManager.GetJSONValue('OnMouseDown');
  if LValue <> '' then
    Self.OnMouseDown := G_CurrentLogic.MouseDownHandler;
  LValue := FResManager.GetJSONValue('OnMouseMove');
  if LValue <> '' then
    Self.OnMouseMove := G_CurrentLogic.MouseMoveHandler;
  LValue := FResManager.GetJSONValue('OnMouseUp');
  if LValue <> '' then
    Self.OnMouseUp := G_CurrentLogic.MouseUpHandler;
//  FEngineModel.LoadResource(FBackground, LBackgroundName);

  FEngineModel.LoadConfig(FDrawBuffer,AConfigName,AResManager);

  FEngineTimer.Enabled := true;
  FTime := Now;
  G_CurrentLogic.EngineModel := FEngineModel;
  //FThread.Start;
end;

procedure TEngine2D.UpdateSpriteBitmap;
begin
  FEngineModel.UpdateSpriteBackground;
end;

Procedure TEngine2D.Paint;
begin
  beginUpdate;
  if assigned(DrawBuffer) then
   Canvas.DrawBitmap(DrawBuffer, RectF(0, 0, DrawBuffer.Width,
    DrawBuffer.Height), RectF(0, 0, Width, Height), 1);
  inherited;
  endUpdate;
end;

procedure TEngine2D.MouseDown(Button: TMouseButton;
  Shift: TShiftState; x, y: single);
var
  LSprite : TEngine2DSprite;
  I : Integer;
begin
  // 检查鼠标事件的时候，从列表的最后一个开始遍历...
  for I := FEngineModel.SpriteList.ItemCount-1 downto 0 do
  begin
    LSprite := FEngineModel.SpriteList.Items[I];
    if LSprite.Visible then
    begin
      if LSprite.IsMouseDown(Button, Shift, X, Y) then
      begin
        exit;
      end;
    end;
  end;

  if Assigned(FOnMouseDown) then
    FOnMouseDown(Self,Button,Shift,x,y);
end;

procedure TEngine2D.MouseMove(Shift: TShiftState; X,
  Y: Single);
var
  LSprite : TEngine2DSprite;
  i: Integer;
  S : String;
begin

  for I := FEngineModel.SpriteList.ItemCount-1 downto 0 do
  begin
    LSprite := FEngineModel.SpriteList.Items[I];
    if LSprite.Visible then
    begin
      if LSprite.IsMouseMove(Shift, X, Y) then
      begin
        exit;
      end;
    end;
  end;

  if Assigned(FOnMouseMove) then
    FOnMouseMove(Self,Shift,X,Y);
end;

procedure TEngine2D.MouseUp(Button: TMouseButton;
  Shift: TShiftState; x, y: single);
var
  i: Integer;
  LSprite : TEngine2DSprite;
begin
//  FCurrentDragSprite := nil;
  for I := FEngineModel.SpriteList.ItemCount - 1 downto 0 do
  begin
    LSprite := FEngineModel.SpriteList.Items[i];
    LSprite.IsMouseUp(Button, Shift, X, Y);
  end;
  if Assigned(FOnMouseUp) then
    FOnMouseUp(Self,Button,Shift,x,y);
end;

procedure TEngine2D.Resize(const AWidth, AHeight: Integer);
var
  i: Integer;
  LObject : TEngine2DSprite;
begin
  FWidth := AWidth;
  FHeight := AHeight;
  FDrawBuffer.Width := AWidth;
  FDrawBuffer.Height := AHeight;
  for i := 0 to FEngineModel.SpriteList.ItemCount-1 do
    begin
      LObject := FEngineModel.SpriteList.Items[i];
      if LObject.Visible then
        begin
          LObject.Resize(AWidth, AHeight);
        end;
    end;
  // star
  for i := 0 to FEngineModel.StarSpriteList.ItemCount-1 do
    begin
      LObject := FEngineModel.StarSpriteList.Items[i];
      if LObject.Visible then
        begin
          LObject.Resize(AWidth,AHeight);
        end;
    end;
end;

Procedure TEngine2D.ThreadWork;
begin
  Draw(nil);
end;

procedure TEngine2D.SetHeight(value: Single);
begin
  FHeight := value;
end;

procedure TEngine2D.SetImage(const Value: TImage);
begin

end;

end.
