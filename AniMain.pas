unit AniMain;
{$ZEROBASEDSTRINGS OFF}

{.$DEFINE FORTEST}
interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics,
  FMX.Ani,FMX.Dialogs, FMX.Objects, IOUtils, FMX.Controls.Presentation, FMX.StdCtrls,
  uPublic,uEngineResource;

type
  TForm1 = class(TForm)
    Image1: TImage;
    FloatAnimation1: TFloatAnimation;
    PathAnimation1: TPathAnimation;
    Rectangle1: TRectangle;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    BGBitmap : TBitmap;
    FResourceManager : TEngineResManager;
//    FLogicUnit : TBaseLogic;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
uses
  uEngine,uEngine2DObject,uEngineUtils,uConfiguration;

{$R *.fmx}

procedure TForm1.FormCreate(Sender: TObject);
var
  LTmp : TObject;
  tmpList : tStringList;
  LStr,LFirstConfig :String;
  LResName,LIndexName,LLogicName : String;
begin
  // 先加载配置文件
  try
    FResourceManager := TEngineResManager.Create;
    {$IFDEF MSWINDOWS}
    FResourceManager.LoadConfig(RES_NAME);
    {$ELSE}
    FResourceManager.LoadConfig(TPath.GetDocumentsPath + PathDelim + RES_NAME);
    {$ENDIF}
  except
    ShowMessage('Error @FResourceManager Create');
  end;

  try
    tmpList := TStringList.Create;
    {$IFDEF FORTEST}
    tmpList.LoadFromFile(INDEX_NAME);
    {$ELSE}
    FResourceManager.LoadResource(tmpList,'index.txt');
    {$ENDIF}

    G_CurrentLogic := GetLogicUnitByAliasName(LOGIC_NAME);

    // 引擎初始化依赖逻辑单元实例，需先实例逻辑单元
    LStr := tmpList.Strings[0];
    LFirstConfig := GetHeadString(LStr,'`');
    try
      G_Engine := TEngine2D.Create(nil);
      G_Engine.Parent := Rectangle1;
      G_Engine.Align := TAlignLayout.Client;
      G_Engine.LoadAnimation(LFirstConfig,FResourceManager);
    except
      ShowMessage('Error @G_Engine Create');
    end;

    // 逻辑单元初始化时依赖动画引擎，需等待完成
    try
      G_CurrentLogic.IndexList.AddStrings(tmpList);
      G_CurrentLogic.Init;
    except
      ShowMessage('Error @LogicUnit Init');
    end;

    //初始化完成，重绘
    FormResize(nil);
  finally
    tmpList.DisposeOf;
  end;

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if Assigned(G_Engine) then
    G_Engine.DisposeOf;
  if Assigned(FResourceManager) then
    FResourceManager.DisposeOf;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if Assigned(G_Engine) then
  begin
    G_Engine.Resize(Round(Image1.Width),Round(Image1.Height));
  end;
end;

Initialization
  ReportMemoryLeaksOnShutDown := true;

end.
