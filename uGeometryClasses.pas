unit uGeometryClasses;

interface
uses
  System.Types;

{
    ���ӳ�ʼ��������ڵĳ��������¼������,�����������ݵ�ͳһ��¼....
    �����ڼ������ŵ�ʱ�����еĲ�������ȫ��....
}

Type
   T2DPosition = record
    InitX,InitY : Single;
    X,Y : Single;
    InitWidth, InitHeight : Single;
    Width, Height : Single;
    Rotate : Single;
    ScaleX,ScaleY : Single;
    function Zero : T2DPosition;
  end;

implementation

{T2DPosition}
function T2DPosition.Zero;
begin
  InitX := 0;
  InitY := 0;
  X := 0;
  Y := 0;
  Rotate := 0;
  ScaleX := 1;
  ScaleY := 1;
  InitWidth := 50;
  InitHeight := 50;
  Width := 50;
  Height := 50;
end;

end.
