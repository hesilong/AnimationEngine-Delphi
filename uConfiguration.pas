unit uConfiguration;

interface

  var
    CurIndex : Integer = 1;

    Res_Array : array[0..3] of string = ('stx.dat','basketball.dat','zyz.dat','dds.dat');

    Logic_Array : array[0..3] of String = ('STXLogic','BasketballLogic','ZYZLogic','DDSLogic');

    Res_Path_Array : array[0..3] of String = ('./stx/','./basketball/','./zyz/','./dds/');

    RES_NAME : String ;
    LOGIC_NAME : String ;
    {$IFDEF MSWINDOWS}
    INDEX_NAME :String ;
    RES_PATH : String ;
    {$ENDIF}

implementation

Initialization

   RES_NAME := Res_Array[CurIndex];
   LOGIC_NAME := Logic_Array[CurIndex];
   {$IFDEF MSWINDOWS}
   RES_PATH := Res_Path_Array[CurIndex];
   INDEX_NAME :=  RES_PATH + 'index.txt';
   {$ENDIF}

end.
