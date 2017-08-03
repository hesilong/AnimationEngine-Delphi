program AnimationEngine_XE8;

uses
  System.StartUpCopy,
  FMX.Forms,
  AniMain in 'AniMain.pas' {Form1},
  uEngine in 'uEngine.pas',
  uEngine2DClasses in 'uEngine2DClasses.pas',
  uEngine2DObject in 'uEngine2DObject.pas',
  uEngine2DExtend in 'uEngine2DExtend.pas',
  uEngine2DModel in 'uEngine2DModel.pas',
  uEngine2DSprite in 'uEngine2DSprite.pas',
  uEngineConfig in 'uEngineConfig.pas',
  uGeometryClasses in 'uGeometryClasses.pas',
  uEngineUtils in 'uEngineUtils.pas',
  uEngineResource in 'uEngineResource.pas',
  uPublic in 'Logic\uPublic.pas',
  uSTXLogic in 'Logic\uSTXLogic.pas',
  uConfiguration in 'uConfiguration.pas',
  uBasketBallLogic in 'Logic\uBasketBallLogic.pas',
  uZYZLogic in 'Logic\uZYZLogic.pas',
  uDDSLogic in 'Logic\uDDSLogic.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Landscape, TFormOrientation.InvertedLandscape];
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
