unit uEngine2DInvade;
{$ZEROBASEDSTRINGS OFF}

{
    ��������, ��Щ������Ҫ����Ƿ���������Sprite���뵽����Щ������˶�����Invade��Manager��
    �������Manager���������еĿ��Ա����������ͬʱ������Ƿ���Sprite���뵽��Ӧ������...
    ���ǲ�����SAT�㷨�������ֽ��м��,��ô�����Ƕ����ֵ�����Ķ���Ҳ������չΪ͹�����...

    ************************************NOTICE************************************
    �����Ƚϵ�������붼��͹����Σ���������˰������,��ֽ�Ϊ���͹���������...
    ******************************************************************************
}

interface
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  uEngine2DClasses, FMX.Dialogs;

Type
  TOnInvaded = Procedure(Msg : String) Of Object;

Type
  TPointsCollection = Array of TPointF;

// ����һ���������������ͶӰ��...
//���ٱ�֤�µ�ǰ��͹����������еĵ��ͶӰ�����ñ�������...
Type
  TNormalVectorAndPoints = Class
  Private
    FSelfSubPoints : Array Of TPointF;   // ͹����α����ͶӰ��...
    FOppositeSubPoints : Array Of TPointF; // �Է�����������ϵ�ͶӰ��...
    FOriVector : TPointF;      // ��ʼ������...
    FNormalVector : TPointF;   // ������....
    FSelfMax, FSelfMin : Single;   //�Լ���ͶӰ������ֵ����Сֵ...
    FOppositeMax, FOppositeMin : Single;  // �Է�ͶӰ�����ֵ����Сֵ...
    Function GetSubPoint(inAP : TPointF) : TPointF;
  Public
    Constructor Create;
    Destructor Destroy; Override;
    Procedure SetValue(inPoint : TPointF);   // �����³�ʼ����ֵ....
    Procedure ReceiveSelfPoints(inP : Array Of TPointF);  // �յ�͹����ε����еĵ�...
    Function CheckCollision(inP : Array Of TPointF) : Boolean;  // ����Ƿ�����ײ...
  End;

// ����һ��͹�����....
Type
  TConvexPolygon = Class
  Private
    FAllPoints : TPointsCollection;    // ͹����ε����е�...
    FAllVector : TStringList;  // ���е�����List...
    FName : String;            // ���͹����ε�����....
    FInfluenceName : String;   //Ŀ��Sprite����....
    FDstPoint : TPointF;       //Ŀ��λ��
    FDstOriPoint : TPointF;    //Ŀ��λ�ó�ʼ����
    Procedure ClearAll;
  Public
    Constructor Create;
    Destructor Destroy; Override;
    Procedure AddAPoint(inP : TPointF);
    Procedure SetPoints(inP : Array Of TPointF);
    Function CalForAllVector : Boolean;    // ��������е�����(��ÿ���ߵķ�����)....
    Function CheckForCollision(inP :Array Of TPointF) : Boolean;

    Property Name : String Read FName Write FName;
    property InfluenceName : String read FInfluenceName write FInfluenceName;
    Property AllPoints : TPointsCollection Read FAllPoints;
    property DstPoint : TPointF read FDstPoint write FDstPoint;
    property OriDstPoint : TPointF read FDstOriPoint write FDstOriPoint;
  end;

// �������еĿ���������...
Type
  T2DInvadeManager = Class
  Private
    FOnInvaded : TOnInvaded;

  Public
    FConvexPolygon : T2DNameList<TConvexPolygon>;   // ���е�͹�����...

    Constructor Create;
    Destructor Destroy; override;
    Procedure UpdateAnINvadeData(inName,AInfluName : String; Points : Array Of TPointF; AOriDstPoint, ADstPoint : TPointF);
    Function CheckInvade(InP : Array Of TPointF) : String;   // ���ر����ֵ����������...
    function GetInvadeObject(InP : Array Of TPointF) : TConvexPolygon;  // ���ر����ֵ��������

    Property OnInvaded : TOnInvaded Read FOnInvaded Write FOnInvaded;
  End;

Type
  TOriInvadePoints = record
    FName : String;
    FPoints : Array Of TPointF;
    InfluenceName : String;
    DstOriPoints : TPointF;   // ��ʼĿ�������
    DstCurPoints : TPointF;   //Resize��Ŀ�������
  end;

implementation

{TNormalVectorAndPoints}
Constructor TNormalVectorAndPoints.Create;
begin
  SetLength(FSelfSubPoints, 0);
  SetLength(FOppositeSubPoints, 0);
  FOriVector := PointF(0,0);
end;

Destructor TNormalVectorAndPoints.Destroy;
begin
  SetLength(FSelfSubPoints, 0);
  SetLength(FOppositeSubPoints, 0);
  Inherited;
end;

Procedure TNormalVectorAndPoints.SetValue(inPoint: TPointF);
begin
  if FOriVector <> inPoint then
  begin
    FOriVector := inPoint;
    FNormalVector := PointF(inPoint.Y, -1*inPoint.X);
  end;
end;

Function TNormalVectorAndPoints.GetSubPoint(inAP: TPointF) : TPointF;
var
  k, b : Single;
begin
  if FNormalVector.X = 0 then
  begin
    Result := PointF(0, inAP.Y);
  end else
  if FNormalVector.Y = 0 then
  begin
    Result := PointF(inAP.X, 0);
  end else
  begin
    k := FNormalVector.Y/FNormalVector.X;
    b := inAP.Y + inAP.X/K;
    result := PointF(k*b/(k*k+1), k*k*b/(k*k+1));
  end;
end;

Procedure TNormalVectorAndPoints.ReceiveSelfPoints(inP: array of TPointF);
Var
  I, _Len : Integer;
  tmpP, tmpP1 : TPointF;
  k, b : Single;
begin
  _Len := 0;
  FSelfMax := 0;
  FSelfMin := 0;
  for I := 0 to High(inP) do
  begin
    tmpP := inP[i];
    tmpP1 := GetSubPoint(tmpP);
    _Len := _Len + 1;
    SetLength(FSelfSubPoints, _Len);
    FSelfSubPoints[_Len-1].X := tmpP1.X;
    FSelfSubPoints[_Len-1].Y := tmpP1.Y;
    // ��������еĵ㣬ȡ��������Сֵ...
    if FNormalVector.X = 0 then
    begin
      // ȡYֵ...
      if _Len = 1 then
      begin
        FSelfMax := tmpP1.Y;
        FSelfMin := tmpP1.Y;
      end else
      begin
        if tmpP1.Y > FSelfMax then
        begin
          FSelfMax := tmpP1.Y;
        end;
        if tmpP1.Y < FSelfMin then
        begin
          FSelfMin := tmpP1.Y;
        end;
      end;
    end else
    begin
      // ȡ X ֵ..
      if _Len = 1 then
      begin
        FSelfMax := tmpP1.X;
        FSelfMin := tmpP1.X;
      end else
      begin
        if tmpP1.X > FSelfMax then
        begin
          FSelfMax := tmpP1.X;
        end;
        if tmpP1.X < FSelfMin then
        begin
          FSelfMin := tmpP1.X;
        end;
      end;
    end;
  end;
  
end;

Function TNormalVectorAndPoints.CheckCollision(inP: array of TPointF) : Boolean;
Var
  I, _Len : Integer;
  tmpP : TPointF;
begin
  result := False;
  _Len := 0;
  if Length(inP) < 3 then
  begin
    exit;
  end;
  // �����������е�ͶӰ��....
  for I := 0 to High(inP) do
  begin
    tmpP := GetSubPoint(inP[i]);
    _Len := _Len + 1;
    SetLength(Self.FOppositeSubPoints, _Len);
    Self.FOppositeSubPoints[_Len - 1].X := tmpP.X;
    Self.FOppositeSubPoints[_Len - 1].Y := tmpP.Y;
    if FNormalVector.X = 0 then
    begin
      if _Len = 1 then
      begin
        FOppositeMax := tmpP.Y;
        FOppositeMin := tmpP.Y;
      end else
      begin
        if tmpP.Y > FOppositeMax then
        begin
          FOppositeMax := tmpP.Y;
        end;
        if tmpP.Y < FOppositeMin then
        begin
          FOppositeMin := tmpP.Y;
        end;
      end;
    end else
    begin
      if _Len = 1 then
      begin
        FOppositeMax := tmpP.X;
        FOppositeMin := tmpP.X;
      end else
      begin
        if tmpP.X > FOppositeMax then
        begin
          FOppositeMax := tmpP.X;
        end;
        if tmpP.X < FOppositeMin then
        begin
          FOppositeMin := tmpP.X;
        end;
      end;
    end;
  end;
  // ������Լ���ͶӰ�������͹����εĶ����ͶӰ���Ƿ����ص�����...
  // ֻ�е�����͹����ε�ͶӰ��Сֵ���ڱ�������ֵ
  //  �������ֵС�ڱ������Сֵ��ʱ�򣬲�û����ײ,�������������ײ��...
  if (FOppositeMax < FSelfMin) or (FOppositeMin > FSelfMax) then
  begin
    result := false;
    exit;
  end;
  result := true;
end;

{TConvexPolygon}
Constructor TConvexPolygon.Create;
begin
  SetLength(FAllPoints, 0);
  FAllVector := TStringList.Create;
end;

Destructor TConvexPolygon.Destroy;
begin
  ClearAll;
  SetLength(FAllPoints, 0);
  FAllVector.DisposeOf;
  Inherited;
end;

Procedure TConvexPolygon.ClearAll;
var
  I : Integer;
  tmpV : TNormalVectorAndPoints;
begin
  for I := 0 to FAllVector.Count - 1 do
  begin
    tmpV := TNormalVectorAndPoints(FAllVector.Objects[I]);
    if tmpV <> nil then
    begin
      tmpV.DisposeOf;
    end;
  end;
  FAllVector.Clear;
end;

Procedure TConvexPolygon.AddAPoint(inP: TPointF);
Var
  _Len : Integer;
begin
  _Len := Length(FAllPoints);
  _Len := _Len + 1;
  SetLength(FAllPoints, _Len);
  FAllPoints[_Len-1] := inP;
end;

Procedure TConvexPolygon.SetPoints(inP: array of TPointF);
Var
  I : Integer;
begin
  SetLength(FAllPoints, 0);
  for I := 0 to High(inP) do
  begin
    SetLength(FAllPoints, I + 1);
    FAllPoints[i].X := inP[i].X;
    FAllPoints[i].Y := inP[i].Y;
  end;
  CalForAllVector;
end;

Function TConvexPolygon.CalForAllVector : Boolean;
Var
  _Len, I : Integer;
  tmpV : TNormalVectorAndPoints;
  tmpP : TPointF;
begin
  result := False;
  _Len := Length(FAllPoints);
  if _Len < 3 then
  begin
    // ����3���ߵ�ʱ���޷���ɼ���...
    exit;
  end;
  ClearAll;
  // �ӵ�һ���㿪ʼ����,ÿ�������һ��������, ���һ����͵�һ��������....
  for I := 1 to _Len do
  begin
    if I = _Len then
    begin
      tmpP := PointF(FAllPoints[0].X - FAllPoints[I-1].X, FAllPoints[0].Y - FAllPoints[I-1].Y)
    end else
    begin
      tmpP := PointF(FAllPoints[I].X - FAllPoints[I-1].X, FAllPoints[I].Y - FAllPoints[I-1].Y)
    end;
    tmpV := TNormalVectorAndPoints.Create;
    tmpV.SetValue(tmpP);
    tmpV.ReceiveSelfPoints(FAllPoints);
    FAllVector.AddObject('', tmpV);
  end;
  result := true;
end;

Function TConvexPolygon.CheckForCollision(inP: array of TPointF) : Boolean;
Var
  tmpV : TNormalVectorAndPoints;
  I : Integer;
begin
  result := true;
  for I := 0 to FAllVector.Count - 1 do
  begin
    tmpV := TNormalVectorAndPoints(FAllVector.Objects[I]);
    if not tmpV.CheckCollision(inP) then
    begin
      result := false;
      exit;
    end;
  end;
end;

{T2DInvadeManager}
Constructor T2DInvadeManager.Create;
begin
  FConvexPolygon := T2DNameList<TConvexPolygon>.Create;
end;

Destructor T2DInvadeManager.Destroy;
begin
  FConvexPolygon.DisposeOf;
  Inherited;
end;

function T2DInvadeManager.GetInvadeObject(InP: array of TPointF): TConvexPolygon;
Var
  S : String;
  I : Integer;
  tmpCP : TConvexPolygon;
begin
  result := nil;
  for I := 0 to FConvexPolygon.ItemCount-1 do
  begin
    tmpCP := FConvexPolygon.Items[I];
    if tmpCP.CheckForCollision(inP) then
    begin
      result := tmpCP;
      exit;
    end;
  end;
end;

Procedure T2DInvadeManager.UpdateAnINvadeData(inName, AInfluName : String; Points : Array Of TPointF; AOriDstPoint, ADstPoint : TPointF);
var
  tmpCP : TConvexPolygon;
begin
  tmpCP := FConvexPolygon.Has(inName);
  if tmpCP = nil then
  begin
    tmpCP := TConvexPolygon.Create;
    tmpCP.SetPoints(Points);
    tmpCP.Name := inName;
    tmpCP.InfluenceName := AInfluName;
    tmpCP.OriDstPoint := AOriDstPoint;
    tmpCP.DstPoint := ADstPoint;
    FConvexPolygon.Add(inName, tmpCP);
  end else
  begin
    tmpCP.DstPoint := ADstPoint;
    tmpCP.SetPoints(Points);
  end;
end;

Function T2DInvadeManager.CheckInvade(InP: array of TPointF) : String;
Var
  S : String;
  I : Integer;
  tmpCP : TConvexPolygon;
begin
  result := '';
  for I := 0 to FConvexPolygon.ItemCount-1 do
  begin
    tmpCP := FConvexPolygon.Items[I];
    if tmpCP.CheckForCollision(inP) then
    begin
      result := tmpCP.Name;
      exit;
    end;
  end;
end;

end.
