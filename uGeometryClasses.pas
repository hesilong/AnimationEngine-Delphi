unit uGeometryClasses;

interface
uses
  System.Types;

{
    增加初始长宽和现在的长宽到这个记录里面来,这样便于数据的统一记录....
    这样在计算缩放的时候，所有的参数都齐全了....
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
