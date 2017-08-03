unit uEngine2DModel;
{$ZEROBASEDSTRINGS OFF}
interface
uses
  System.Classes,System.SysUtils,System.UITypes,
  FMX.Graphics,FMX.Objects,FMX.Dialogs,
  uEngine2DClasses,uEngine2DExtend,uEngine2DObject,uEngineResource,
  uEngine2DSprite, System.JSON, uEngine2DInvade;

{TEngine2DModel 类负责管理场景（包括场景布局信息加载、分发，动画精灵创建、修改、清除）}
Type
  TEngine2DModel = class
    private
      FSpriteList : T2DNameList<TEngine2DSprite>;
      FStarSpriteList : T2DNameList<TEngine2DSprite>;  //管理星星
      FBackgroundName : String;
      FImage : TBitmap;  //画布 ...
      FResourceManager : TEngineResManager;
      FInvadeManager : T2DInvadeManager;
      FOriW, FOriH : Single;    // 画布的初始大小....

      function GetSpriteCount:Integer;
      function GetStarSpriteCount:Integer;
      procedure BringToFrontHandler(Sender: TObject);
      procedure SendToBackHandler(Sender: TObject);
    public
      Constructor Create;
      Destructor Destroy;override;
      procedure LoadConfig(AImage:TBitmap;AConfigPath : String; AResManager : TEngineResManager);
      procedure LoadResource(var OutBmp : TBitmap;ABmpName:String);
      procedure UpdateSpriteBackground;
      Procedure BringToFront(Sender : TObject);
      procedure LoadNextConfig(AConfigPath :String);

      property BackgroundName : String read FBackgroundName;
      property ResourceManager : TEngineResManager read FResourceManager;
      Property InvadeManager : T2DInvadeManager Read FInvadeManager;
      property SpriteList : T2DNameList<TEngine2DSprite> read FSpriteList;
      property StarSpriteList : T2DNameList<TEngine2DSprite> read FStarSpriteList;
      property SpriteCount : Integer read GetSpriteCount;
      property StarSpriteCount : Integer read GetStarSpriteCount;
      property OriW : Single Read FOriW Write FOriW;
      property OriH : Single Read FOriH Write FOriH;
  end;

implementation

{ TEngine2DModel }

procedure TEngine2DModel.BringToFrontHandler(Sender: TObject);
var
  LIndex : Integer;
begin
  //FILO
  LIndex := FSpriteList.IndexOf(TEngine2DSprite(Sender));
  FSpriteList.Exchange(LIndex,FSpriteList.ItemCount-1);
end;

constructor TEngine2DModel.Create;
begin
  FSpriteList := T2DNameList<TEngine2DSprite>.Create;
  FStarSpriteList := T2DNameList<TEngine2DSprite>.Create;
//  FResourceManager := TEngineResManager.Create;
  FInvadeManager := T2DInvadeManager.Create;
end;

destructor TEngine2DModel.Destroy;
begin
  FSpriteList.DisposeOf;
  FStarSpriteList.DisposeOf;
//  FResourceManager.DisposeOf;
  FInvadeManager.DisposeOf;
  inherited;
end;

function TEngine2DModel.GetSpriteCount: Integer;
begin
  result := FSpriteList.ItemCount;
end;

function TEngine2DModel.GetStarSpriteCount: Integer;
begin
  result  := FStarSpriteList.ItemCount;
end;

procedure TEngine2DModel.LoadConfig(AImage:TBitmap;AConfigPath: String ; AResManager : TEngineResManager);
var
  LSprite : TEngine2DSprite;
  i: Integer;
  LDebugCount : Integer;
  S : String;
  tmpArray : TJSONArray;
  tmpValue : TJSONObject;
  tmpSprite : TEngine2DSprite;
  SW, SH : String;
begin
  try
    FImage := AImage;
    FResourceManager := AResManager;
    LoadNextConfig(AConfigPath);
    // 星星只加载一次
    tmpArray := FResourceManager.GetJSONArray('Star');
    if tmpArray <> nil then
      begin
        for i := 0 to tmpArray.Size-1 do
          begin
            tmpValue := TJSONObject(tmpArray.Get(I));
            LSprite := TEngine2DSprite.Create(FImage);
            LSprite.ResManager := Self.FResourceManager;
            LSprite.SetParentSize(FOriW, FOriH);
            LSprite.InvadeManager := Self.FInvadeManager;
            LSprite.ReadFromJSON(tmpValue);
            Self.FStarSpriteList.Add(LSprite.Name, LSprite);
          end;
      end;
  except on e : Exception do
    ShowMessage('Error @TEngine2DModel.LoadConfig:'+e.Message);
  end;
  LDebugCount := 0;
end;

procedure TEngine2DModel.LoadNextConfig (AConfigPath :String);
var
  LSprite : TEngine2DSprite;
  i: Integer;
  S : String;
  tmpArray : TJSONArray;
  tmpValue : TJSONObject;
  tmpSprite : TEngine2DSprite;
  SW, SH : String;
begin
  try
    FSpriteList.Clear;
    FInvadeManager.FConvexPolygon.Clear;
//    FResourceManager.UpdateConfig(AConfigPath);
//    FBackgroundName := FResourceManager.GetJSONValue('Background');
    SW := FResourceManager.GetJSONValue('OriW');
    SH := FResourceManager.GetJSONValue('OriH');

    FOriW := StrToIntDef(SW,1024);
    FOriH := StrToIntDef(SH,768);

    tmpArray := FResourceManager.GetJSONArray('Resource');
    if tmpArray <> nil then
      begin
        // 根据 JSONArray 来创建Sprite...
        for i := 0 to tmpArray.Size - 1 do
        begin
          tmpValue := TJSONObject(tmpArray.Get(I));
          LSprite := TEngine2DSprite.Create(FImage);
          LSprite.ResManager := Self.FResourceManager;
          LSprite.SetParentSize(FOriW, FOriH);
          LSprite.InvadeManager := Self.FInvadeManager;
          LSprite.ReadFromJSON(tmpValue);
          Self.FSpriteList.Add(LSprite.Name, LSprite);
        end;
      end;

  except on e : Exception do
    ShowMessage('Error @TEngine2DModel.LoadNextConfig:'+e.Message);
  end;

end;

procedure TEngine2DModel.LoadResource(var OutBmp: TBitmap; ABmpName: String);
var
  LTmp : TBitmap;
begin
  if Not Assigned(OutBmp) then
    OutBmp := TBitmap.Create else
    OutBmp.Clear($ff000000);

  FResourceManager.LoadResource(OutBmp,ABmpName);
end;

procedure TEngine2DModel.SendToBackHandler(Sender: TObject);
var
  LIndex : Integer;
begin
  //FILO
  LIndex:= FSpriteList.IndexOf(TEngine2DSprite(Sender));
  FSpriteList.Exchange(LIndex,0);
end;

procedure TEngine2DModel.UpdateSpriteBackground;
var
  i : Integer;
  LObject : TEngine2DSprite;
begin
  for i := 0 to FSpriteList.ItemCount-1 do
    begin
      LObject := FSpriteList.Items[i];
      if LObject.Visible then
        begin
          LObject.UpdateSpriteBackground;
        end;
    end;
end;

Procedure TEngine2DModel.BringToFront(Sender: TObject);
Var
  LIndex : Integer;
begin
  LIndex := FSpriteList.IndexOf(TEngine2DSprite(Sender));
  FSpriteList.Exchange(LIndex,FSpriteList.ItemCount-1);
end;

end.
