unit uEngine2DClasses;
{$ZEROBASEDSTRINGS OFF}
interface
uses
  System.Types, System.SysUtils, System.Variants, System.UITypes, System.Classes, System.Generics.Collections,
  FMX.Graphics, System.ZLib, FMX.Ani, FMX.Types, FMX.Dialogs;

//HashOrderList Vector
type T2DNameList<T: class> = class(TPersistent)
  strict private
    FDic : TDictionary<string, T>;
    FList: TObjectList<T>;
  strict private
    function getItems(Index: Integer): T;
  public
    function  Has(AName: string): T;
    function  Contains(AName: string): Boolean;
    procedure Add(AName: string; A: T);
    procedure Remove(AName: string);
    function  IndexOf(A: T): Integer;
    procedure Clear;
    procedure Exchange(Index1, Index2: Integer);
  private
    function getItemsCount: Integer;
  public
    constructor Create(IsOwned: Boolean = True);
    destructor  Destroy; override;
  property  Items[Index: Integer]: T       read getItems;
  property  ItemCount            : Integer read getItemsCount;
end;

implementation

{ TNameList<T> }

procedure T2DNameList<T>.Add(AName: string; A: T);
begin
  if not FDic.ContainsKey(AName) then begin
    FDic.Add(AName, A);
    FList.Add(A);
  end;
end;

function T2DNameList<T>.Has(AName: string): T;
begin
  Result := nil;

  if FDic.ContainsKey(AName) then
    Result := FDic[AName];
end;

function T2DNameList<T>.IndexOf(A: T): Integer;
begin
  Result := FList.IndexOf(A);
end;

procedure T2DNameList<T>.Remove(AName: string);
begin
  if FDic.ContainsKey(AName) then begin
    FList.Remove(FDic[AName]);
    FDic.Remove(AName);
  end;
end;

procedure T2DNameList<T>.Clear;
begin
  FList.Clear;
  FDic.Clear;
end;

function T2DNameList<T>.Contains(AName: string): Boolean;
begin
  Result := False;

  if FDic.ContainsKey(AName) then
    Result := True;
end;

constructor T2DNameList<T>.Create(IsOwned: Boolean);
begin
  FDic := TDictionary<string, T>.Create;
  FList:= TObjectList<T>.Create(IsOwned);
end;

destructor T2DNameList<T>.Destroy;
begin
  FreeAndNil(FDic);
  FreeAndNil(FList);
  inherited;
end;


procedure T2DNameList<T>.Exchange(Index1, Index2: Integer);
begin
  if (Index1 >= FList.Count) or (Index2 >= FList.Count) then exit;
  if Index1 = Index2 then exit;
  FList.Exchange(Index1,Index2);
end;

function T2DNameList<T>.getItems(Index: Integer): T;
begin
  Result := FList[Index];
end;

function T2DNameList<T>.getItemsCount: Integer;
begin
  Result := FList.Count;
end;

end.
