unit uEngine2DInvade;
{$ZEROBASEDSTRINGS OFF}

{
    在引擎中, 有些区域需要检测是否有其他的Sprite进入到了这些区域，因此定义了Invade的Manager，
    利用这个Manager来管理所有的可以被侵入的区域，同时检测下是否有Sprite进入到相应的区域...
    我们采用了SAT算法来对入侵进行检测,那么，我们队入侵的区域的定义也可以拓展为凸多边形...

    ************************************NOTICE************************************
    两个比较的区域必须都是凸多边形，如果遇到了凹多边形,请分解为多个凸多边形来做...
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

// 定义一个法向量和上面的投影点...
//至少保证下当前的凸多边形上所有的点的投影点计算好保存下来...
Type
  TNormalVectorAndPoints = Class
  Private
    FSelfSubPoints : Array Of TPointF;   // 凸多边形本身的投影点...
    FOppositeSubPoints : Array Of TPointF; // 对方在这个向量上的投影点...
    FOriVector : TPointF;      // 初始的向量...
    FNormalVector : TPointF;   // 法向量....
    FSelfMax, FSelfMin : Single;   //自己的投影点的最大值和最小值...
    FOppositeMax, FOppositeMin : Single;  // 对方投影的最大值和最小值...
    Function GetSubPoint(inAP : TPointF) : TPointF;
  Public
    Constructor Create;
    Destructor Destroy; Override;
    Procedure SetValue(inPoint : TPointF);   // 设置下初始向量值....
    Procedure ReceiveSelfPoints(inP : Array Of TPointF);  // 收到凸多边形的所有的点...
    Function CheckCollision(inP : Array Of TPointF) : Boolean;  // 检测是否有碰撞...
  End;

// 定义一个凸多边形....
Type
  TConvexPolygon = Class
  Private
    FAllPoints : TPointsCollection;    // 凸多边形的所有点...
    FAllVector : TStringList;  // 所有的向量List...
    FName : String;            // 这个凸多边形的名字....
    FInfluenceName : String;   //目标Sprite名字....
    FDstPoint : TPointF;       //目标位置
    FDstOriPoint : TPointF;    //目标位置初始坐标
    Procedure ClearAll;
  Public
    Constructor Create;
    Destructor Destroy; Override;
    Procedure AddAPoint(inP : TPointF);
    Procedure SetPoints(inP : Array Of TPointF);
    Function CalForAllVector : Boolean;    // 计算出所有的向量(即每条边的法向量)....
    Function CheckForCollision(inP :Array Of TPointF) : Boolean;

    Property Name : String Read FName Write FName;
    property InfluenceName : String read FInfluenceName write FInfluenceName;
    Property AllPoints : TPointsCollection Read FAllPoints;
    property DstPoint : TPointF read FDstPoint write FDstPoint;
    property OriDstPoint : TPointF read FDstOriPoint write FDstOriPoint;
  end;

// 管理所有的可侵入区域...
Type
  T2DInvadeManager = Class
  Private
    FOnInvaded : TOnInvaded;

  Public
    FConvexPolygon : T2DNameList<TConvexPolygon>;   // 所有的凸多边形...

    Constructor Create;
    Destructor Destroy; override;
    Procedure UpdateAnINvadeData(inName,AInfluName : String; Points : Array Of TPointF; AOriDstPoint, ADstPoint : TPointF);
    Function CheckInvade(InP : Array Of TPointF) : String;   // 返回被入侵的区域的名字...
    function GetInvadeObject(InP : Array Of TPointF) : TConvexPolygon;  // 返回被入侵的区域对象

    Property OnInvaded : TOnInvaded Read FOnInvaded Write FOnInvaded;
  End;

Type
  TOriInvadePoints = record
    FName : String;
    FPoints : Array Of TPointF;
    InfluenceName : String;
    DstOriPoints : TPointF;   // 初始目标点坐标
    DstCurPoints : TPointF;   //Resize后目标点坐标
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
    // 检测下所有的点，取出最大和最小值...
    if FNormalVector.X = 0 then
    begin
      // 取Y值...
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
      // 取 X 值..
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
  // 首先生成所有的投影点....
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
  // 检测下自己的投影点和入侵凸多边形的顶点的投影点是否有重叠区域...
  // 只有当入侵凸多边形的投影最小值大于本身的最大值
  //  或者最大值小于本身的最小值的时候，才没有碰撞,其他的情况都碰撞了...
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
    // 少于3条边的时候，无法完成计算...
    exit;
  end;
  ClearAll;
  // 从第一个点开始计算,每个点和下一个点连接, 最后一个点和第一个点连接....
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
