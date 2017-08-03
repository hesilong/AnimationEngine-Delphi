unit uEngineThread;

interface
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants;

Type
  TEngineThread = Class(TThread)
  Private
    FOwner : TObject;

    Procedure Execute; override;
  Public
    Constructor Create(CreateSuspended : Boolean);
    Destructor Destroy; Override;

    Property Owner  :TObject Read FOwner Write FOwner;
  End;

implementation
uses
   uEngine;

Constructor TEngineThread.Create(CreateSuspended: Boolean);
begin
  Inherited Create(true);
  FreeOnTerminate := true;
end;

Destructor TEngineThread.Destroy;
begin
  Inherited;
end;

Procedure TEngineThread.Execute;
begin
  while not Self.Terminated do
  begin
    if G_Engine <> nil then
    begin
      Synchronize(G_Engine.ThreadWork);
    end;
    Sleep(10);
  end;
end;

end.
