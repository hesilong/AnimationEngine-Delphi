unit uEngineConfig;
{$DEFINE TEST}

interface
  uses
    System.Classes,System.SysUtils,System.Json,FMX.Graphics, uEngineResource,
    uEngine2DClasses;

Type
  TResourceType = (rtImage,rtText);

  TBaseConfig = class
    protected
      FSourceName : String;  //精灵名
      FType : TResourceType; //精灵类型
      FResManager : TEngineResManager;
    public

     property SourceName : String read FSourceName write FSourceName;
     property ResourceType : TResourceType read FType write FType;
     Property Resmanager : TEngineResManager Read FResManager Write FResManager;
  end;

  TImageConfig = class(TBaseConfig)
    private
    Type
     TBasePlay = class
       protected
         FAnimationCount : Integer;
         FFilePath : String;
         FResManager : TEngineResManager;

//         procedure SetFilePath(value : String);virtual;abstract;
       public
         Constructor Create(AResManager : TEngineResManager);
         procedure LoadFromJsonObject(AJson :TJsonObject);virtual;
         property AnimationCount : Integer read FAnimationCount write FAnimationCount;
//         property FilePath : String write SetFilePath;
     end;

     TNormalPlay = class(TBasePlay)
        private
          FIndexList : TStringList;
          FAnimationList : TStringList;
          FAnimationInterval : Integer;
          FDelayInterval : Integer;
          FLoop : boolean;
          FControlName : String;

          function GetBitmap(index:Integer):TBitmap;
//          procedure SetFilePath(value : String); override;
        public
          Constructor Create(AResManager : TEngineResManager);
          Destructor Destroy;override;
          procedure LoadFromJsonObject(AJson :TJsonObject); override;

          property Item[index:Integer] : TBitmap read GetBitmap;
          property AnimationInterval : Integer read FAnimationInterval write FAnimationInterval;
          property DelayInterval  : Integer read FDelayInterval  write FDelayInterval;
          property Loop : boolean read FLoop write FLoop default false;
          property ControlName : String read FControlName;
      end;

      //目前默认mousemove 的时候最多切换一张图
      TMouseMovePlay = class(TBasePlay)
        private
          FBitmap : TBitmap;
//          procedure SetFilePath(value:String);override;
        public
          Constructor Create(AResManager : TEngineResManager);
          Destructor Destroy;override;

          property Item : TBitmap read FBitmap;
      end;

    private

      FNormalBitmap : TBitmap;             // 静态的时候显示的图片....
//      FCurNormalIndex : Integer;
      FNormalPlayControler : TNormalPlay;
      FMouseMovePlayControler : TMouseMovePlay;
      FNormalPlayManager : T2DNameList<TNormalPlay>;
      FOnSwitchStatus : TGetStrProc;
      FFinishProc : TProc;
//      function GetCurNormalPlayControl : TNormalPlay;
    public
      Constructor Create(AJson :TJsonObject;AResManager : TEngineResManager);
      Destructor Destroy;override;
      Procedure SetNormalImg(inName : String);overload;   // 设置下正常显示的图片的名称..
      procedure SetNormalImg(AIndex : Integer);overload;  // 多图模式，切换图片
      procedure LoadNormalControler(AJson : TJsonArray;AIndex : Integer = 0);
      procedure SwitchNormalControlerByName(AName : String;AFinishProc : TProc);

      property NormalBitmap :TBitmap Read FNormalBitmap Write FNormalBitmap;
      property NormalPlayControler : TNormalPlay read FNormalPlayControler write FNormalPlayControler; //  GetCurNormalPlayControl;
      property MouseMovePlayControler : TMouseMovePlay read FMouseMovePlayControler;
      property FinishProc : TProc read FFinishProc write FFinishProc;
      property OnSwitchStatus : TGetStrProc read FOnSwitchStatus write FOnSwitchStatus;
  end;

  const DRAW_INTERVAL = 40; // unit : ms

implementation

{ TImageConfig.TNormalPlay }

constructor TImageConfig.TNormalPlay.Create(AResManager : TEngineResManager);
begin
  inherited Create(AResManager);
  FIndexList := TStringList.Create;
  FAnimationList := TStringList.Create(true);
end;

destructor TImageConfig.TNormalPlay.Destroy;
begin
  FIndexList.DisposeOf;
  FAnimationList.DisposeOf;
  inherited;
end;

function TImageConfig.TNormalPlay.GetBitmap(index: Integer): TBitmap;
var
  LBmp : TBitmap;
  LKey : String;
  LPos : Integer;
begin
  if index > FIndexList.Count then
    begin
      result := nil;
      exit;
    end;
  LKey :=  FIndexList.Strings[index];
  LPos := FAnimationList.IndexOf(LKey);
  if LPos = -1 then
    begin
      LBmp := TBitmap.Create;
//      LBmp.LoadFromFile('res/'+LKey);
      FResManager.LoadResource(LBmp,LKey);
      FAnimationList.AddObject(LKey,LBmp);
    end else
    begin
      LBmp := FAnimationList.Objects[LPos] as TBitmap;
    end;
  result := LBmp;
end;

procedure TImageConfig.TNormalPlay.LoadFromJsonObject(AJson: TJsonObject);
begin
  if AJson <> nil then
    begin
      FControlName := AJson.Values['Name'].Value;
      FAnimationCount := StrToIntDef(AJson.Values['Count'].Value,1);
      FFilePath := AJson.Values['FilePath'].Value;
      FResManager.LoadResource(FIndexList,FFilePath);
      FAnimationInterval := StrToIntDef(AJson.Values['Interval'].Value,300);
      FDelayInterval := StrToIntDef(AJson.Values['Delay'].Value,0);
      FLoop := UpperCase(AJson.Values['Loop'].Value) = 'TRUE';
    end;
end;

{ TImageConfig }

constructor TImageConfig.Create(AJson: TJsonObject;AResManager : TEngineResManager);
begin
  FResManager := AResManager;
  FNormalBitmap := TBitmap.Create;
  FNormalPlayManager := T2DNameList<TNormalPlay>.Create;
//  FNormalPlayControler := TNormalPlay.Create(AResManager);
  FMouseMovePlayControler := TMouseMovePlay.Create(AResManager);
end;

destructor TImageConfig.Destroy;
begin
  FNormalBitmap.DisposeOf;
  FNormalPlayManager.DisposeOf;
//  FNormalPlayControler.DisposeOf;
  FMouseMovePlayControler.DisposeOf;
  inherited;
end;

//function TImageConfig.GetCurNormalPlayControl: TNormalPlay;
//begin
//  if FCurNormalIndex < FNormalPlayManager.ItemCount then
//    result :=  FNormalPlayManager.Items[FCurNormalIndex] else
//    result := nil;
//end;

procedure TImageConfig.LoadNormalControler(AJson: TJsonArray;AIndex : Integer = 0);
var
  i: Integer;
  LNormalControl : TNormalPlay;
  LObject : TJsonObject;
begin
  for i := 0 to AJson.Size-1 do
   begin
     LObject := TJsonObject(AJson.Get(i));
     LNormalControl := TNormalPlay.Create(FResManager);
     LNormalControl.LoadFromJsonObject(LObject);
     FNormalPlayManager.Add(LNormalControl.ControlName,LNormalControl);
   end;
  if AIndex < FNormalPlayManager.ItemCount then
    FNormalPlayControler := FNormalPlayManager.Items[AIndex];
end;

procedure TImageConfig.SetNormalImg(AIndex: Integer);
var
  LBmp : TBitmap;
begin
  LBmp := FNormalPlayControler.Item[AIndex];
  FNormalBitmap.Assign(LBmp);
end;

procedure TImageConfig.SwitchNormalControlerByName(AName: String;AFinishProc : TProc);
begin
  if FNormalPlayManager.Contains(AName) then
   FNormalPlayControler := FNormalPlayManager.Has(AName);
  FFinishProc := AFinishProc;
  if Assigned(FOnSwitchStatus) then
    FOnSwitchStatus('switch');
end;

Procedure TImageConfig.SetNormalImg(inName: string);
begin
  if FResManager <> nil then
  begin
    FResManager.LoadResource(FNormalBitmap, inName);
  end;
end;

{ TImageConfig.TMouseMovePlay }

constructor TImageConfig.TMouseMovePlay.Create(AResManager : TEngineResManager);
begin
  inherited Create(AResManager);
  FBitmap := TBitmap.Create;
  FAnimationCount := 0;
end;

destructor TImageConfig.TMouseMovePlay.Destroy;
begin
  if Assigned(FBitmap) then
    FBitmap.DisposeOf;
  inherited;
end;

//procedure TImageConfig.TMouseMovePlay.SetFilePath(value: String);
//begin
//  FFilePath := value;
//  if FileExists(FFilePath) then
//    begin
//      FBitmap.LoadFromFile(FFilePath);
//      FAnimationCount := 1;
//    end;
//end;

{ TImageConfig.TBasePlay }

constructor TImageConfig.TBasePlay.Create(AResManager: TEngineResManager);
begin
   FResManager := AResManager;
end;

procedure TImageConfig.TBasePlay.LoadFromJsonObject(AJson: TJsonObject);
begin

end;

end.
