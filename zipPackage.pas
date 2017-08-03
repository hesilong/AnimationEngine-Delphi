unit zipPackage;
{$ZEROBASEDSTRINGS OFF}
interface

uses
  SysUtils, Variants, Classes, FMX.Graphics, FMX.Controls, FMX.Forms,
  FMX.Dialogs, FMX.ExtCtrls, FMX.StdCtrls,strUtils,zLib,EncdDecd;

Type
  TFileCompressionLevel = (fcNone, fcFastest, fcDefault, fcMaximum);


type
  tZipRecord = class
   private
    fileList : tStringList;
    dataStream : TmemoryStream;
   public
    name : string;
    version : integer;
    macString : string;

   public
    Constructor Create;
    Destructor Destroy; override;
    procedure SetFileList(inList : tStringList);
    function LoadFileFromPackage(filename : string; var theStream : TMemoryStream) : boolean;
    procedure Writedata(inStream : tMemoryStream);
    function getFileList : TStringList;
    procedure Clear;

  end;

Type
  TSingleFile = class
  private

  public
    FileName : String;
    FileSize : Integer;
    Buffer : TBytes;
    BufferLength : Integer;
    Constructor Create;
    Destructor Destroy; override;
    procedure SetInfo(theName : String; theSize : Integer);
    procedure ReadInfo;
  end;


  procedure writepureDataToStream(inStream : TStream; Source : TStream);
  Function SelfEncode(inStr : String) : String;
  Function SelfDecode(inStr : String) : String;
  Function GetHeadString(Var inStr : String; Seperator : Char) : String;
  Function IsPackageValid(inPack : string) : boolean;
  Function CreatePackage(packName : string;sourceDir : string;version : integer;macString : string) : boolean;
  function upPack(packName : string) : tZipRecord;
  procedure UpPackage(PackName : String; var theRecord : tZipRecord);
  procedure UpThePackage(var inStream : TResourceStream; var theRecord : tZipRecord);overload;
  procedure UpThePackage(var sourceStream : TMemoryStream; var theRecord : TZipRecord);overload;
  function UpdateMacPackage(sourcePack,destPack,macString : string) : boolean;

var
  theCommonStream : TMemoryStream;

implementation

Constructor TSingleFile.Create;
begin
  inherited;
  //SetLength(FileName, 128);
  //BufferLength := 136;
end;

Destructor TSingleFile.Destroy;
begin

  inherited;
end;

procedure TSingleFile.SetInfo(theName: string; theSize: Integer);
var
  i, ii, _Len : Integer;
  _Pos : Integer;
  cmd : Byte;
begin
  FileName := theName;
  FileSize := theSize;
  theName := EncodeString(theName);
  _Len := SizeOf(Integer) + SizeOf(Integer) + Length(theName);
  SetLength(Buffer, _Len);
  Move(theSize, Buffer[0], SizeOf(Integer));
  _Pos := SizeOf(Integer);
  ii := Length(theName);
  Move(ii, Buffer[_Pos], SizeOf(Integer));
  _Pos := _Pos + SizeOf(Integer);
  for i := 1 to Length(theName) do
    begin
      cmd := Ord(theName[i]);
      Move(cmd, Buffer[_Pos], SizeOf(Byte));
      _Pos := _Pos + SizeOf(Byte);
    end;
  BufferLength := _Len;
end;

procedure TSingleFile.ReadInfo;
var
  i, _Pos, ii : Integer;
  cmd : Byte;
begin
  Move(Buffer[0], FileSize, SizeOf(Integer));
  _Pos := SizeOf(Integer);
  Move(Buffer[_Pos], ii, SizeOf(Integer));
  _Pos := _Pos + SizeOf(Integer);
  FileName := '';
  for i := 1 to ii do
    begin
      Move(Buffer[_Pos], cmd, SizeOf(Byte));
      _Pos := _Pos + SizeOf(Byte);
      FileName := FileName + Chr(cmd);
    end;
  FileName := DecodeString(FileName);
end;

Function GetHeadString(Var inStr : String; Seperator : Char) : string;
 var
  tempstr : String;
 begin
  inStr := trim(inStr);
  if inStr = '' then
   begin
    result := '';
    exit;
   end;
  if Pos(Seperator,inStr) = 0 then
   begin
    result := inStr;
    inStr := '';
    exit;
   end;
  if inStr[1] = '"' then
   begin
    delete(inStr,1,1);
    tempstr := Copy(inStr,1,Pos('"',inStr));
    tempstr := '"' + tempstr;
    delete(inStr,1,Pos('"',inStr));
   end else
    tempstr := copy(inStr,1,Pos(Seperator,inStr)-1);
  delete(inStr,1,Pos(Seperator,inStr));
  result := tempstr;
 end;

Function IsPackageValid(inPack : string) : boolean;
var
 tmpStream : tMemoryStream;
 version,fsize : integer;
 s1 : string;
 begin
   //
  result := false;
  if not FileExists(inPack) then
    exit;
  tmpStream := tMemoryStream.Create;
  tmpStream.LoadFromFile(inPack);

  tmpStream.Seek(LongInt(-sizeOf(Integer)),SoFromEnd);
  try
    tmpStream.Read(version,sizeOf(Integer));
   except
    tmpStream.Free;
    exit;
  end;
  try
    tmpStream.Seek(LongInt(- 2 * sizeOf(Integer)),SoFromEnd);
    tmpStream.Read(fsize,sizeOf(Integer));
  except
    tmpStream.Free;
    exit;
  end;

  if tmpStream.Size < fsize + 2 * sizeOf(Integer) + 512 then
   begin
    tmpStream.Free;
    exit;
   end;

  tmpStream.Seek(LongInt(-(fsize + 2 * sizeOf(Integer) + 512)),SoFromEnd);
  setlength(s1,3);
  tmpStream.ReadBuffer(s1[1],3);
  if s1 <> 'CTN' then
    begin
      tmpStream.Free;
      exit;
    end;
  result := true;
  tmpStream.Free;

 end;


Constructor TZipRecord.Create;
begin
    name := '';
    dataStream := TmemoryStream.Create;
    version := -1;
    fileList := tStringList.Create;
    macString := '';
end;

procedure TzipRecord.Clear;
begin
  DataStream.Clear;
  name := '';
  version := -1;
  FileList.Clear;
  macString := '';
end;

Destructor TzipRecord.Destroy;
begin
    name := '';
    dataStream.DisposeOf;
    version := -1;
    fileList.Free;;
    macString := '';
end;

function TzipRecord.LoadFileFromPackage(filename: string; var theStream : TMemoryStream) : boolean;
 var
   i : integer;
   s1,S2 : string;
   startOff,sizeofstream : integer;
   theBuffer : TBytes;
begin
   if fileList.Count < 1 then
     exit;
   result := false;
   theStream.Clear;
   theStream.Seek(LongInt(0),0);
   filename := upperCase(fileName);
   for i := 0 to fileList.Count - 1 do
    begin
     s1 := upperCase(fileList.Strings[i]);
     if pos(filename,s1) > 0 then
      begin
        S2 := GetheadString(s1,'|');
        if upperCase(S2) <> upperCase(filename) then
        begin
          if pos('\'+filename, S2) = 0 then
            Continue;
        end;
        result := true;
        startoff := strtoint(GetheadString(s1,'|'));
        sizeofstream := strtoint(GetheadString(s1,'|'));
        dataStream.Seek(LongInt(startoff),0);
        //SetLength(theBuffer, sizeOfStream);
        //DataStream.ReadBuffer(theBuffer[0], sizeOfStream);
        //theStream.WriteBuffer(theBuffer[0], SizeOfStream);
        theStream.CopyFrom(dataStream,sizeofstream);
        break;
      end;
    end;

end;

procedure TzipREcord.SetFileList(inList: TStringList);
 var
  i : integer;
begin
  if inList.Count < 1 then
    exit;
  for i := 0 to inList.Count - 1 do
     fileList.Add(inList.Strings[i]);
end;

procedure Tziprecord.Writedata(inStream: TMemoryStream);
begin
  if inStream.Size < 0 then
    exit;
  writepureDataToStream(dataStream,inStream);
end;

function Tziprecord.getFileList : TStringList;
var
  tmpList : TStringList;
  i : Integer;
begin
  result := nil;
  if fileList.Count = 0 then
  begin
    exit;
  end;
  tmpList := TStringList.Create;
  for i := 0 to FileList.Count - 1 do
   begin
     tmpList.Add(fileList.Strings[i]);
   end;
  result := tmpList;
end;

Function SelfEncode(inStr : String) : String;
 Var
  i : integer;
  c1 : char;
  t1,t2 : integer;
  s1,s2,s3 : string;
 begin
  result := '';
  Randomize;
  if inStr = '' then exit;
  s3 := '';
  for i := 1 to Length(inStr) do
   begin
    c1 := inStr[i];
    t1 := ord(c1);
    t1 := t1 * 38;
    s1 := IntToHEX(t1,0);
    if length(s1) < 3 then
     begin
      t2 := 200 + Random(55);
      s2 := IntTOHEX(t2,0);
     end else
    if length(s1) = 3 then
      s2 := '0' else
      s2 := '';
    s1 := s2 + s1;
    s3 := s3 + s1;
   end;
  result := s3;
 end;

Function SelfDecode(inStr : String) : String;
 Var
  c1 : Char;
  s1,s3 : string;
  t1 : integer;
 begin
  result := '';
  if inStr = '' then exit;
  s3 := '';
  while inStr <> '' do
   begin
    s1 := Copy(inStr,1,4);
    delete(inStr,1,4);
    if s1[1] = '0' then
     begin
      s1 := '$' + s1;
      t1 := StrToInt(s1);
      t1 := t1 div 38;
      c1 := Chr(t1);
     end else
    if (Uppercase(s1[1]) = 'C') or
       (Uppercase(s1[1]) = 'D') or
       (Uppercase(s1[1]) = 'E') or
       (Uppercase(s1[1]) = 'F') then
     begin
      delete(s1,1,2);
      s1 := '$' + s1;
      t1 := StrToInt(s1);
      t1 := t1 div 38;
      c1 := Chr(t1);
     end else
     begin
      s1 := '$' + s1;
      t1 := StrToInt(s1);
      t1 := t1 div 38;
      c1 := Chr(t1);
     end;
    s3 := s3 + c1;
   end;
  result := s3;
 end;

procedure writepureDataToStream(inStream : TStream; Source : TStream);
  Var
      Buffer : Array[0..20479] of Char;
      j : integer;
      //k : integer;
  begin
      //k := Source.Size;
      //inStream.WriteBuffer(k,SizeOf(integer));
      if Source.Size = 0 then exit;
      Source.Seek(LongInt(0),0);
      j := Source.Read(Buffer[0],20480);
      while j > 0 do
       begin
        inStream.WriteBuffer(Buffer[0],j);
        j := Source.Read(Buffer[0],20480);
       end;
  end;

function CreatePackage(packName : string;sourceDir : string; version : integer;macstring : string) : boolean;
var
  dir: string;
  j : integer;
  dataMemory : tMemoryStream;
  indexMemory : tMemoryStream;
  fileCount : integer;
  xMemory : tMemoryStream;
  cpMemory : tMemoryStream;
  filesize : integer;
  zStream : TCustomZLibStream;
  //tmpFileRecord : ^tFileRecord;
  aFileRecord : TSingleFile;
  s1,s2 : string;
  filepath,filename : string;
  buffer : pointer;
  macStream : tMemoryStream;
  i : byte;
  total : integer;
  FileNameList: TStringList;
begin
  result := false;
  FileNameList := tStringList.Create;
  try
    dir := trim(sourcedir);
  //EnumFileInQueue(PChar(dir), '.*', FileNameList);
    //EnumFileInQueue(PChar(dir), '.*', FileNameList);
   except
     FileNameList.Free;
     exit;
  end;
//  ShowMessage(IntToStr(FileNameList.Count));
//  memo1.Clear;
//  for I := 0 to FileNameList.Count - 1 do
//    Memo1.Lines.Add(fileNameList.Strings[i]);
try
  fileCount := fileNameList.Count;
  dataMemory := tMemoryStream.Create;
  indexMemory := tMemoryStream.Create;
  indexMemory.WriteBuffer(fileCount,sizeof(Integer));

 for I := 0 to FileNameList.Count - 1 do
  begin
    xMemory := tMemoryStream.Create;
    xMemory.LoadFromFile(fileNameList.Strings[i]);
    xMemory.Seek(LongInt(0),0);
    cpMemory := tMemoryStream.Create;
    zStream := TCompressionStream.Create(TCompressionLevel(fcDefault),cpMemory);
    zStream.CopyFrom(xMemory,0);
    zStream.Free;
    s1 := fileNameList.Strings[i];
    filepath := '';
    if pos('\',s1) > 0 then
     begin
      repeat
         filepath := filepath + copy(s1,1,pos('\',s1));
         delete(s1,1,pos('\',s1));
      until pos('\',s1) <= 0;
     end;

    //GetMem(tmpFileRecord,SizeOf(tFileRecord));
    //tmpFileRecord^.filename := filepath + s1;
    //tmpFileRecord^.size := cpMemory.Size;

    aFileRecord := TSingleFile.Create;
    aFileRecord.SetInfo(filepath + s1, cpMemory.Size);
    indexMemory.WriteBuffer(aFileRecord.BufferLength, SizeOf(Integer));
    indexMemory.WriteBuffer(aFileRecord.Buffer[0], aFileRecord.BufferLength);
    aFileRecord.Free;

    //indexMemory.Writebuffer(tmpFileRecord^,sizeof(tFileRecord));
    WritePureDataToStream(dataMemory,cpMemory);
    //FreeMem(tmpFileRecord);
//    dataMemory.WriteBuffer(cpMemory,sizeOf(cpMemory));
    xMemory.Free;
    cpMemory.Free;
  end;
  macStream := tmemoryStream.Create;
//  GetMem(buffer,512);
//  macStream.LoadFromStream(macstring);
  s1 := 'CTN';
  datamemory.WriteBuffer(s1[1],3);
  if macstring = '' then
   begin
    total := 3;
    repeat
      i := random(26);
      s1 := chr(ord('A') + i);
      dataMemory.WriteBuffer(s1[1],1);
      inc(total);
    until total = 512;
   end else
   begin
    macString := selfEncode(macString);
    j := length(macString);
    dataMemory.Writebuffer(j,sizeOf(integer));
    dataMemory.WriteBuffer(macString[1],j);
    total := sizeOf(integer) + j + 3;
    repeat
      i := random(26);
      s1 := chr(ord('A') + i);
      dataMemory.WriteBuffer(s1[1],1);
      inc(total);
    until total = 512;
   end;

  indexMemory.Seek(LongInt(0),0);
  cpMemory := tMemoryStream.Create;
  zStream := TCompressionStream.Create(TCompressionLevel(fcDefault),cpMemory);
  zStream.CopyFrom(indexMemory,0);
  zStream.Free;

  j := cpMemory.Size;
  writePureDataToStream(dataMemory,cpMemory);
  datamemory.WriteBuffer(j,sizeOf(Integer));
  j := version;
  datamemory.WriteBuffer(j,sizeOf(Integer));
  cpMemory.Free;
  dataMemory.Seek(LongInt(0),0);
  dataMemory.SaveToFile(packname);

//  dataMemory.SaveToFile('d:\1.dat');

  dataMemory.Free;
  indexMemory.Free;
  result := true;
 except

end;
end;

function upPack(packName : string) : tZipRecord;
 var
  sourceStream : tMemoryStream;
  dataStream : tMemoryStream;
  indexStream : tMemoryStream;
  xStream : tMemoryStream;
  cpStream : tCustomZlibStream;
  fSize : integer;
  buffer : Pointer;
  xCount, _Len : integer;
  //tmpFileRecord : ^tFileRecord;
  aFile : TSingleFile;
  fileCount : integer;
  i : integer;
  offset : integer;
  version : integer;
  macStream : TStringStream;
  macString : string;
  tmpList : tStringList;
  outputStream : tMemoryStream;
  newOffset : integer;
  s1 : string;
  tmpZipRecord : tZipRecord;
begin
  result := nil;
  tmpZipRecord := tZipRecord.Create;
  sourceStream := tMemoryStream.Create;
  sourceStream.LoadFromFile(packname);
  tmpZipRecord.name := packname;
  sourceStream.Seek(LongInt(-sizeOf(Integer)),SoFromEnd);
  sourceStream.Read(version,sizeOf(Integer));
  tmpZipRecord.version := version;
//  showmessage(inttostr(version));
  sourceStream.Seek(LongInt(- 2 * sizeOf(Integer)),SoFromEnd);
  sourceStream.Read(fsize,sizeOf(Integer));
  sourceStream.Seek(LongInt(-(fsize + 2 * sizeOf(Integer))),SoFromEnd);
  xStream := tMemoryStream.Create;
  xStream.CopyFrom(sourceStream,fsize);
  xStream.Seek(LongInt(0),0);
  macStream := TStringStream.Create('');
  sourceStream.Seek(LongInt(-(fsize + 2 * sizeOf(Integer) + 512)),SoFromEnd);
  macStream.CopyFrom(sourceStream,512);
  macStream.Seek(LongInt(0),0);
  setlength(s1,3);
  macStream.ReadBuffer(s1[1],3);
//should be CTN

  macStream.Seek(LongInt(3),SoFromBeginning);
//  macStream.CopyFrom(sourceStream,509);
 try
   macStream.ReadBuffer(i,sizeOf(integer));
   if i < 509 then
    begin
     macStream.Seek(LongInt(sizeOf(integer)+3),SoFromBeginning);
     setLength(macString,i);
     MacStream.ReadBuffer(macString[1],i);
     macString := selfDecode(macstring);
    end else
     macString := '';
 except
   macstring := '';
 end;
//  showmessage( selfDecode(macstring));
  tmpZipRecord.macString := macString;
//  showmessage(SelfDecode(macString));

  cpStream := TDeCompressionStream.Create(xStream);
  indexStream := tMemoryStream.Create;
  repeat
    getMem(buffer,4096);
    xCount := cpStream.Read(buffer^,4096);
    if xCount <> 0 then
     begin
       indexStream.WriteBuffer(buffer^,xCount);
     end;
    FreeMem(buffer);
  until xCount = 0;

  cpStream.Free;
  xStream.Clear;
  indexStream.Seek(LongInt(0),0);
  indexStream.Read(filecount,sizeOf(Integer));
  sourceStream.Seek(LongInt(0),0);
  offset := 0;
  tmpList := tStringList.Create;
  outputStream := tMemoryStream.Create;
  newOffSet := 0;
  for i := 0 to fileCount -1  do
   begin
     xStream.Clear;

     aFile := TSingleFile.Create;
     indexStream.ReadBuffer(_Len, SizeOf(Integer));
     SetLength(aFile.Buffer, _Len);
     indexStream.ReadBuffer(aFile.Buffer[0], _Len);
     aFile.ReadInfo;
     //GetMem(tmpFileRecord,sizeOf(tFileRecord));
     //indexStream.Read(tmpFileRecord^,sizeOf(tFileRecord));
//     memo1.Lines.Add(tmpFileRecord.path + tmpFileRecord.filename + ' ' + inttostr(tmpFileRecord.size));
//     sourceStream.Read(xStream,tmpFileRecord.size);
     //xStream.CopyFrom(sourceStream,tmpFileRecord.size);
     //offset := offset + tmpFileRecord.size;
     xStream.CopyFrom(sourceStream, aFile.FileSize);
     offset := offset + aFile.FileSize;
     xStream.Seek(LongInt(0),0);
     cpStream := TDeCompressionStream.Create(xStream);
     dataStream := tMemoryStream.Create;
     repeat
       getMem(buffer,4096);
       xCount := cpStream.read(buffer^,4096);
       if xCount <> 0 then
         begin
          dataStream.WriteBuffer(buffer^,xCount);
        end;
       FreeMem(buffer);
     until xCount = 0;
     cpStream.Free;
     sourceStream.Seek(LongINt(offset),SoFromBeginning);
     //outputStream.CopyFrom(dataStream,0);
     //outputStream
     writepureDataToStream(outPutStream,dataStream);
     tmpList.Add(aFile.filename + '|' + inttostr(newOffset) + '|' + inttostr(dataStream.Size) + '|');
     newOffSet := newOffSet + dataStream.Size;
//     sourceStream.Read(xStream,tmpFileRecord.size);
//     s1 := tmpFileRecord.filename;
//     getHeadString(s1,':');
//     dataStream.SaveToFile('d:\3333' + s1);

     //FreeMem(tmpFileRecord);
     aFile.Free;
     xStream.Clear;
     dataStream.Free;
   end;
   tmpzipRecord.Writedata(outPutStream);
   tmpZipRecord.SetFileList(tmpList);
   tmpList.Free;
   outputStream.Free;
   result := tmpZipRecord;
end;

procedure UpPackage(PackName : String; var theRecord : tZipRecord);
var
  sourceStream : tMemoryStream;
  dataStream1 : tMemoryStream;
  indexStream : tMemoryStream;
  xStream : tMemoryStream;
  cpStream : tCustomZlibStream;
  fSize : integer;
  buffer : Pointer;
  xCount, _Len : integer;
  //tmpFileRecord : ^tFileRecord;
  aFile : TSingleFile;
  fileCount : integer;
  i : integer;
  offset : integer;
  version : integer;
  macStream : TStringStream;
  macString : string;
  tmpList : tStringList;
  outputStream : tMemoryStream;
  newOffset : integer;
  s1 : string;
begin
  if not Assigned(theRecord) then
    theRecord := tZipRecord.Create
  else
    theRecord.Clear;
  sourceStream := tMemoryStream.Create;
  sourceStream.LoadFromFile(packname);
  theRecord.name := packname;
  sourceStream.Seek(LongInt(-sizeOf(Integer)),SoFromEnd);
  sourceStream.Read(version,sizeOf(Integer));
  theRecord.version := version;

  sourceStream.Seek(LongInt(- 2 * sizeOf(Integer)),SoFromEnd);
  sourceStream.Read(fsize,sizeOf(Integer));
  sourceStream.Seek(LongInt(-(fsize + 2 * sizeOf(Integer))),SoFromEnd);
  xStream := tMemoryStream.Create;
  xStream.CopyFrom(sourceStream,fsize);
  xStream.Seek(LongInt(0),0);
  macStream := TStringStream.Create('');
  sourceStream.Seek(LongInt(-(fsize + 2 * sizeOf(Integer) + 512)),SoFromEnd);
  macStream.CopyFrom(sourceStream,512);
  macStream.Seek(LongInt(0),0);
  setlength(s1,3);
  macStream.ReadBuffer(s1[1],3);
//should be CTN

  macStream.Seek(LongInt(3),SoFromBeginning);
//  macStream.CopyFrom(sourceStream,509);
 try
   macStream.ReadBuffer(i,sizeOf(integer));
   if i < 509 then
    begin
     macStream.Seek(LongInt(sizeOf(integer)+3),SoFromBeginning);
     setLength(macString,i);
     MacStream.ReadBuffer(macString[1],i);
     macString := selfDecode(macstring);
    end else
     macString := '';
 except
   macstring := '';
 end;
//  showmessage( selfDecode(macstring));
  theRecord.macString := macString;
//  showmessage(SelfDecode(macString));

  cpStream := TDeCompressionStream.Create(xStream);
  indexStream := tMemoryStream.Create;
  repeat
    getMem(buffer,4096);
    xCount := cpStream.Read(buffer^,4096);
    if xCount <> 0 then
     begin
       indexStream.WriteBuffer(buffer^,xCount);
     end;
    FreeMem(buffer);
  until xCount = 0;

  cpStream.Free;
  xStream.Clear;
  indexStream.Seek(LongInt(0),0);
  indexStream.Read(filecount,sizeOf(Integer));
  sourceStream.Seek(LongInt(0),0);
  offset := 0;
  tmpList := tStringList.Create;
  outputStream := tMemoryStream.Create;
  newOffSet := 0;
  dataStream1 := tMemoryStream.Create;
  for i := 0 to fileCount -1  do
   begin
     xStream.Clear;

     aFile := TSingleFile.Create;
     indexStream.ReadBuffer(_Len, SizeOf(Integer));
     SetLength(aFile.Buffer, _Len);
     indexStream.ReadBuffer(aFile.Buffer[0], _Len);
     aFile.ReadInfo;
     //GetMem(tmpFileRecord,sizeOf(tFileRecord));
     //indexStream.Read(tmpFileRecord^,sizeOf(tFileRecord));
//     memo1.Lines.Add(tmpFileRecord.path + tmpFileRecord.filename + ' ' + inttostr(tmpFileRecord.size));
//     sourceStream.Read(xStream,tmpFileRecord.size);
     //xStream.CopyFrom(sourceStream,tmpFileRecord.size);
     //offset := offset + tmpFileRecord.size;
     xStream.CopyFrom(sourceStream, aFile.FileSize);
     offset := offset + aFile.FileSize;
     xStream.Seek(LongInt(0),0);
     cpStream := TDeCompressionStream.Create(xStream);

     DataStream1.Clear;

     repeat
       getMem(buffer,4096);
       xCount := cpStream.read(buffer^,4096);
       if xCount <> 0 then
         begin
          dataStream1.WriteBuffer(buffer^,xCount);
        end;
       FreeMem(buffer);
     until xCount = 0;
     cpStream.Free;
     sourceStream.Seek(LongInt(offset),SoFromBeginning);
     //outputStream.CopyFrom(dataStream,0);
     //outputStream
     writepureDataToStream(outPutStream,dataStream1);
     tmpList.Add(aFile.filename + '|' + inttostr(newOffset) + '|' + inttostr(dataStream1.Size) + '|');
     newOffSet := newOffSet + dataStream1.Size;
//     sourceStream.Read(xStream,tmpFileRecord.size);
//     s1 := tmpFileRecord.filename;
//     getHeadString(s1,':');
//     dataStream.SaveToFile('d:\3333' + s1);

     //FreeMem(tmpFileRecord);
     aFile.Free;
     xStream.Clear;
   end;
   xStream.Clear;
   xStream.Free;
   DataStream1.Clear;
   DataStream1.Free;
   theRecord.Writedata(outPutStream);
   theRecord.SetFileList(tmpList);
   tmpList.Clear;
   tmpList.Free;
   outputStream.Free;
   SourceStream.Clear;
   SourceStream.Free;
   MacStream.Clear;
   MacStream.Free;
   indexStream.Clear;
   indexStream.Free;
end;

procedure UpThePackage(var inStream : TResourceStream; var theRecord : tZipRecord);
var
  sourceStream : tMemoryStream;
  dataStream1 : tMemoryStream;
  indexStream : tMemoryStream;
  xStream : tMemoryStream;
  cpStream : tCustomZlibStream;
  fSize : integer;
  buffer : Pointer;
  xCount, _Len : integer;
  //tmpFileRecord : ^tFileRecord;
  aFile : TSingleFile;
  fileCount : integer;
  i : integer;
  offset : integer;
  version : integer;
  macStream : TStringStream;
  macString : string;
  tmpList : tStringList;
  outputStream : tMemoryStream;
  newOffset : integer;
  s1 : string;
begin

  sourceStream := tMemoryStream.Create;
  inStream.Seek(LongInt(0),0);
  sourceStream.LoadFromStream(inStream);
  UpThePackage(sourceStream,theRecord);
end;

procedure UpThePackage(var sourceStream : TMemoryStream;var theRecord : tZipRecord);
var
  dataStream1 : tMemoryStream;
  indexStream : tMemoryStream;
  xStream : tMemoryStream;
  cpStream : tCustomZlibStream;
  fSize : integer;
  buffer : Pointer;
  xCount, _Len : integer;
  //tmpFileRecord : ^tFileRecord;
  aFile : TSingleFile;
  fileCount : integer;
  i : integer;
  offset : integer;
  version : integer;
  macStream : TStringStream;
  macString : string;
  tmpList : tStringList;
  outputStream : tMemoryStream;
  newOffset : integer;
  s1 : string;
begin
  if not Assigned(theRecord) then
    theRecord := tZipRecord.Create
  else
    theRecord.Clear;
  theRecord.name := '11';
  sourceStream.Seek(LongInt(-sizeOf(Integer)),SoFromEnd);
  sourceStream.Read(version,sizeOf(Integer));
  theRecord.version := version;

  sourceStream.Seek(LongInt(- 2 * sizeOf(Integer)),SoFromEnd);
  sourceStream.Read(fsize,sizeOf(Integer));
  sourceStream.Seek(LongInt(-(fsize + 2 * sizeOf(Integer))),SoFromEnd);
  xStream := tMemoryStream.Create;
  xStream.CopyFrom(sourceStream,fsize);
  xStream.Seek(LongInt(0),0);
  macStream := TStringStream.Create('');
  sourceStream.Seek(LongINt(-(fsize + 2 * sizeOf(Integer) + 512)),SoFromEnd);
  macStream.CopyFrom(sourceStream,512);
  macStream.Seek(LongInt(0),0);
  setlength(s1,3);
  macStream.ReadBuffer(s1[1],3);
//should be CTN

  macStream.Seek(LongInt(3),SoFromBeginning);
//  macStream.CopyFrom(sourceStream,509);
 try
   macStream.ReadBuffer(i,sizeOf(integer));
   if i < 509 then
    begin
     macStream.Seek(LongInt(sizeOf(integer)+3),SoFromBeginning);
     setLength(macString,i);
     MacStream.ReadBuffer(macString[1],i);
     macString := selfDecode(macstring);
    end else
     macString := '';
 except
   macstring := '';
 end;
//  showmessage( selfDecode(macstring));
  theRecord.macString := macString;
//  showmessage(SelfDecode(macString));

  cpStream := TDeCompressionStream.Create(xStream);
  indexStream := tMemoryStream.Create;
  repeat
    getMem(buffer,4096);
    xCount := cpStream.Read(buffer^,4096);
    if xCount <> 0 then
     begin
       indexStream.WriteBuffer(buffer^,xCount);
     end;
    FreeMem(buffer);
  until xCount = 0;

  cpStream.Free;
  xStream.Clear;
  indexStream.Seek(LongInt(0),0);
  indexStream.Read(filecount,sizeOf(Integer));
  sourceStream.Seek(LongInt(0),0);
  offset := 0;
  tmpList := tStringList.Create;
  outputStream := tMemoryStream.Create;
  newOffSet := 0;
  dataStream1 := tMemoryStream.Create;
  for i := 0 to fileCount -1  do
   begin
     xStream.Clear;

     aFile := TSingleFile.Create;
     indexStream.ReadBuffer(_Len, SizeOf(Integer));
     SetLength(aFile.Buffer, _Len);
     indexStream.ReadBuffer(aFile.Buffer[0], _Len);
     aFile.ReadInfo;
     //GetMem(tmpFileRecord,sizeOf(tFileRecord));
     //indexStream.Read(tmpFileRecord^,sizeOf(tFileRecord));
//     memo1.Lines.Add(tmpFileRecord.path + tmpFileRecord.filename + ' ' + inttostr(tmpFileRecord.size));
//     sourceStream.Read(xStream,tmpFileRecord.size);
     //xStream.CopyFrom(sourceStream,tmpFileRecord.size);
     //offset := offset + tmpFileRecord.size;
     xStream.CopyFrom(sourceStream, aFile.FileSize);
     offset := offset + aFile.FileSize;
     xStream.Seek(LongInt(0),0);
     cpStream := TDeCompressionStream.Create(xStream);

     DataStream1.Clear;

     repeat
       getMem(buffer,4096);
       xCount := cpStream.read(buffer^,4096);
       if xCount <> 0 then
         begin
          dataStream1.WriteBuffer(buffer^,xCount);
        end;
       FreeMem(buffer);
     until xCount = 0;
     cpStream.Free;
     sourceStream.Seek(LongInt(offset),SoFromBeginning);
     //outputStream.CopyFrom(dataStream,0);
     //outputStream
     writepureDataToStream(outPutStream,dataStream1);
     tmpList.Add(aFile.filename + '|' + inttostr(newOffset) + '|' + inttostr(dataStream1.Size) + '|');
     newOffSet := newOffSet + dataStream1.Size;
//     sourceStream.Read(xStream,tmpFileRecord.size);
//     s1 := tmpFileRecord.filename;
//     getHeadString(s1,':');
//     dataStream.SaveToFile('d:\3333' + s1);

     //FreeMem(tmpFileRecord);
     aFile.Free;
     xStream.Clear;
   end;
   xStream.Clear;
   xStream.Free;
   DataStream1.Clear;
   DataStream1.Free;
   theRecord.Writedata(outPutStream);
   theRecord.SetFileList(tmpList);
   tmpList.Clear;
   tmpList.Free;
   outputStream.Free;
   SourceStream.Clear;
   SourceStream.Free;
   MacStream.Clear;
   MacStream.Free;
   indexStream.Clear;
   indexStream.Free;
end;

function UpdateMacPackage(sourcePack,destPack,macString : string) : boolean;
 var
   sourceStream : tMemoryStream;
   fsize : integer;
   dataStream,indexStream : tMemoryStream;
   s1 : string;
   macStream : tMemoryStream;
   i,j,total : integer;
 begin
   result := false;
   if not fileExists(sourcePack) then
    exit;

   if not isPackageValid(sourcePack) then
     exit;
   sourceStream := tMemoryStream.Create;
   sourceStream.LoadFromFile(sourcePack);
   sourceStream.Seek(LongInt(-(2*SizeOf(Integer))),soFromEnd);
   sourceStream.ReadBuffer(fsize,sizeOf(Integer));
   sourceStream.Seek(LongInt(-(2*SizeOf(Integer)+ fsize)),soFromEnd);
   indexStream := tMemoryStream.Create;
   indexStream.CopyFrom(sourceStream,2*sizeOf(Integer) + fsize);

   dataStream := tMemoryStream.Create;
   sourceStream.seek(LongInt(0),0);
   dataStream.CopyFrom(sourceStream,sourceStream.Size - 2 * sizeOf(integer) - fsize - 512);

   macStream := tmemoryStream.Create;
//  GetMem(buffer,512);
//  macStream.LoadFromStream(macstring);
   s1 := 'CTN';
   dataStream.WriteBuffer(s1[1],3);
   macString := selfEncode(macString);
   j := length(macString);
   dataStream.Writebuffer(j,sizeOf(integer));
   dataStream.WriteBuffer(macString[1],j);
   total := sizeOf(integer) + j + 3;
   repeat
      i := random(26);
      s1 := chr(ord('A') + i);
      dataStream.WriteBuffer(s1[1],1);
      inc(total);
    until total = 512;
   writepureDataToStream(dataStream,indexStream);
   dataStream.SaveToFile(destPack);
 end;

end.
