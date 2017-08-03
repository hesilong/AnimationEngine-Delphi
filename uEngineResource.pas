unit uEngineResource;
{$ZEROBASEDSTRINGS OFF}

{.$DEFINE FORTEST}
// ***************************************
//  �������е���Դ�ļ�(���е�ͼƬ��Դ��JSON�ĵ���Ϣ)
//  �κ�һ��Sprite�����Ե������Unit����ȡͼƬ��Դ....

interface
 uses
   System.SysUtils,System.Classes,System.JSON,System.UITypes,
   FMX.Graphics, FMX.Dialogs,
   zipPackage;


 Type
  TEngineResManager = class
    private
      FAllSourceData : TZipRecord;
      FConfigText : String;
      FTmpData : TMemoryStream;        // ����һ��Stream, ������������Դ��������ļ�...
      FJSONObject : TJSONObject;       // ����һ��ȫ�ֵ�JSONObject, ���������仯��ʱ��, ����һֱʹ��...

    public
      Constructor Create;
      Destructor Destroy;override;

      procedure LoadConfig(ASrcPath:String);
      procedure UpdateConfig(AConfigIndex : String);
      procedure LoadResource(var OutBmp : TBitmap;ABmpName:String);overload;
      procedure LoadResource(var OutList : TStringList; ATxtName:String);overload;
      function GetJSONValue(AKey : String): String;
      Function GetJSONArray(AKey : String) : TJSONArray;
      Function ReadAllSprite(Var inStr : String) : Boolean;   // ��ȡ���еľ���....

      property ConfigText : String read FConfigText write FConfigText;
  end;

 const CONFIG_INDEX = 'config.txt';

// var
//   G_EngineResManager : TEngineResManager;

implementation
uses
  uConfiguration;

{ TEngineResManager }

constructor TEngineResManager.Create;
begin
    FAllSourceData := TZipRecord.Create;
    FTmpData := TMemoryStream.Create;
end;

destructor TEngineResManager.Destroy;
begin
  FAllSourceData.DisposeOf;
  FTmpData.DisposeOf;
  if FJSONObject <> nil then
  begin
    FJSONObject.DisposeOf;
    FJSONObject := nil;
  end;
  inherited;
end;

function TEngineResManager.GetJSONValue(AKey: String): String;
var
  //JSONObject :  TJSonObject;
  S : String;
  tmpValue : TJSONValue;
begin
  S := ConfigText;
  result := '';
  if S = '' then
    exit;
  try
    tmpValue := FJSONObject.Values[AKey];
    if tmpValue <> nil then
    begin
      result := tmpValue.Value;
    end;
  finally

  end;
end;

Function TEngineResManager.GetJSONArray(AKey: string) : TJSONArray;
begin
  result := TJSONArray(FJSONObject.GetValue(AKey));
end;

Function TEngineResManager.ReadAllSprite(Var inStr : String) : Boolean;
var
  tmpValue : TJSONValue;
  tmpArray : TJSONArray;
  i : Integer;
  S : String;
begin

  tmpArray := TJSONArray(FJSONObject.GetValue('Resource'));
  for i := 0 to tmpArray.Size - 1 do
  begin
    S := (tmpArray.Get(I) as TJSONObject).ToString;
  end;

//  tmpValue := FJSONObject.Values['Resource'];
//  if tmpValue <> nil then
//  begin
//
//  end;
end;

procedure TEngineResManager.UpdateConfig(AConfigIndex: String);
var
  LList : TStringList;
begin
  if not Assigned(FAllSourceData) then
    raise Exception.Create('FAllSourceData is not assigned');
  try
    LList := TStringList.Create;
    FTmpData.Clear;
    FAllSourceData.LoadFileFromPackage(AConfigIndex, FTmpData);
    FTmpData.Seek(LongInt(0),0);
    LList.LoadFromStream(FTmpData);
    FConfigText := LList.Text;
    //  ������δ����ǲ����õ�...
    {$IF defined(FORTEST) and defined(MSWINDOWS)}
    LList.LoadFromFile(RES_PATH+AConfigIndex);   // �޸�4
    FConfigText := LList.Text;
    {$ENDIF}
  finally
    LList.DisposeOf;
  end;
  if FJSONObject <> nil  then
    FJSONObject.DisposeOf;
  FJSONObject := TJSONObject.ParseJSONValue(FConfigText) as TJSonObject;
end;

procedure TEngineResManager.LoadConfig(ASrcPath:String);
begin
  // ��ʼ��ȡ���е���Դ�ļ�....
  if FileExists(ASrcPath) then
  begin
    try
      UpPackage(ASrcPath, FAllSourceData);
    finally
    end;
  end else
  begin
    ShowMessage('Error @TEngineResManager.LoadConfig : File not Exist');
  end;
end;

procedure TEngineResManager.LoadResource(var OutList: TStringList;
  ATxtName: String);
begin
  if FAllSourceData.LoadFileFromPackage(ATxtName,FTmpData) then
   begin
     if Not Assigned(OutList) then
       OutList := TStringList.Create else
       OutList.Clear;
     FTmpData.Seek(LongInt(0),soFromBeginning);
     OutList.LoadFromStream(FTmpData);
   end;
end;

procedure TEngineResManager.LoadResource(var OutBmp: TBitmap; ABmpName: String);
var
  LTmp : TBitmap;
begin

  if FAllSourceData.LoadFileFromPackage(ABmpName, FTmpData) then
  begin
    try
      LTmp := TBitmap.Create;
      LTmp.LoadFromStream(FTmpData);
      OutBmp.Assign(LTmp);
    finally
      LTmp.DisposeOf;
    end;
  end else
  begin
    if FileExists(ABmpName) then
    begin
      try
        LTmp := TBitmap.Create;
        LTmp.LoadFromFile(ABmpName);
        OutBmp.Assign(LTmp);
      finally
        LTmp.DisposeOf;
      end;
    end;
  end;

end;

Initialization
//  G_EngineResManager := TEngineResManager.Create;

Finalization
//  G_EngineResManager.DisposeOf;

end.
