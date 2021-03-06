unit uDDSLogic;

interface
uses
  System.Classes, System.UITypes,System.SysUtils, System.Types,System.Generics.Collections,
  FMX.Dialogs,FMX.Types, uPublic,uEngine2DSprite,uEngine2DExtend;

  Type
    TDDSLogic = class(TLogicWithStar)
      public
        procedure Init;override;

        procedure MouseDownHandler(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);override;
        procedure MouseMoveHandler(Sender: TObject; Shift: TShiftState; X, Y: Single);override;
        procedure MouseUpHandler(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);override;
    end;

implementation

{ TDDSLogic }

procedure TDDSLogic.Init;
begin
  //todo
end;

procedure TDDSLogic.MouseDownHandler(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Sender.ClassName.Equals('TEngine2D') then
    begin
      Showmessage('mousedown');
    end;

end;

procedure TDDSLogic.MouseMoveHandler(Sender: TObject; Shift: TShiftState; X,
  Y: Single);
begin

end;

procedure TDDSLogic.MouseUpHandler(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin

end;

Initialization

  RegisterLogicUnit(TDDSLogic,'DDSLogic');

end.
