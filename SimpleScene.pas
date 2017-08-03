unit SimpleScene;

interface
uses
  Windows, Messages, SysUtils, UITypes,Classes, vcl.Graphics, fmx.Controls, fmx.Forms, fmx.Dialogs,
  fmx.StdCtrls, fmx.ExtCtrls,  {CoolGraphButton, VerticalListContainer,} NewBasic,
  ShellAPI, fmx.Menus{, BookM, GifImage, VGShap};

type

 TSceneNodeNew = class
  private
   //theCanvas : TCanvas;
   Name : String;
   Content : String;
   AttList : TAttributeList;

   FLeft,FTop : integer;
   FWidth,FHeight : integer;
   FShowType : Byte;
   FOnRequestMessage : TSendMessage;
   FOnTellBack       : TSendMessage;
   FOnGetImage : TGetImage;
   FMouseIn : Boolean;
   FVisible : Boolean;

   procedure SetFMouseIn(Value : Boolean);
   procedure SetFLeft(Value : integer);
   procedure SetFTop(Value : integer);
   procedure SetFShowType(Value : Byte);
   procedure SetFVisible(Value : Boolean);
  public
   IDName : String;
   waitingfilename : String;
   theRealObject : TObject;
   theCClassName : String;
   parentX,parentY : integer;

   Constructor Create;
   Destructor Destroy; override;
   Procedure SetContent(inStr : String);
   Function GetValueByName(inName : String) : String;
   //procedure SetCanvas(inCanvas : TCanvas);
   //procedure DrawOut(Startx, wWidth, StartY, wHeight, delta : integer; theCanvas : TCanvas; TheSBK : TBitMap);
  published
   property Left : integer read FLeft write SetFLeft;
   property Top : integer read FTop write SetFTop;
   property Width : integer read FWidth write FWidth;
   property Height : integer read FHeight write FHeight;
   property ShowType : Byte read FShowType write SetFShowType;
   property MouseIn : Boolean read FMouseIn write SetFMouseIn default false;
   property Visible : Boolean read FVisible write setFVisible default true;
   property OnRequestMessage : TSendMessage read FOnRequestMessage write FOnRequestMessage;
   property OnTellBack : TSendMessage read FOnTellBack write FOnTellBack;
   property OnGetImage : TGetImage read FOnGetImage write FOnGetImage;
 end;

 TSimpleContainer = class(TStringList)
  private
  public
   Constructor Create;
   Destructor Destroy; override;
   procedure addItem(inItem : TSceneNodeNew);
   function GetItemByReal(theReal : TObject) : TSceneNodeNew;
 end;

 TNewSceneDOCNew = class(TStringList)
  private
   //theCanvas : TCanvas;
   //SavedBackGround : TBitMap;
   Version : string;
   StandAlone : Boolean;
   Title : String;
   StyleSheetType : Byte; //0 : text/css 1: XSL
   Encoding : String;
   XMLSource : String;
   FOnRequestMessage : TSendMessage;
   FOnRequestObject : TRequestObject;
   FOnGetSrcForNode : TGetStream;
   FOnLoadStreamForScript : TLoadStream;
   FOnGetImage : TGetImage;
   FCursor : integer;
   FLeft : integer;
   FTop  : integer;
   alignLeft,alignTop,
   alignBottom,alignRight : integer;
   MousePos : TPoint;
   procedure XMLParser;
   procedure arrangeItems;
   procedure SetFCursor(Value : integer);
   procedure SetFLeft(Value : integer);
   procedure SetFTop(Value : integer);
   Procedure GetCor_Value(inNode : TSceneNodeNew; Var x,y,w,h : integer);
   procedure givetheBMP(Handle : String; Var theGraph : TBitMap);
   procedure givetheBMP2(theP : TBitMap; theLink : String);
   procedure MsgFromControl(Var Msg : String);
   procedure GetSrcForNode(inStr : String; theStream : TMemoryStream);
   procedure LoadStreamForScript(inStr : String; Var DataStored : TMemoryStream; sType : Byte);
  public
   Width,Height : integer;
   NextHandleString : String;
   CurrentPath : String;
   parentX,parentY : integer;
   Constructor create;
   Destructor destroy; override;
   Procedure Clear; override;
   Procedure AddNode(inStr : String);
   Procedure SetContent(inStr : String); overload;
   procedure SetContent(inStr : String; thePath : String); overload;
   procedure Refresh;
   //procedure SetCanvas(inCanvas : TCanvas);
   function selfMouseMove(Shift : TShiftState; X,Y : integer) : Boolean;
   procedure selfMouseClick;
   procedure selfDblClick;
   procedure changeMsg(Msg : String);
   function selfMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer) : Boolean;
   function selfMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: integer) : Boolean;
   procedure selfKeyPress(Var Key : Char);
   procedure selfKeyUp(Var Key : Word; Shift : TShiftState);
   procedure selfKeyDown(Var Key : Word; Shift : TShiftState);
   procedure DrawOut(Startx, wWidth, StartY, wHeight, delta : integer; theCanvas : TCanvas);
   procedure getImageForNode(index : integer);
   //Function ReturnItemByAttValue(attName : String; attValue : String) : TSceneNode;
  published
   property Cursor : integer read FCursor write SetFCursor;
   property Left : integer read FLeft write SetFLeft;
   property Top : integer read FTop write SetFTop;
   property OnRequestMessage : TSendMessage read FOnRequestMessage write FOnRequestMessage;
   property OnRequestObject : TRequestObject read FOnRequestObject write FOnRequestObject;
   property OnGetImage : TGetImage read FOnGetImage write FOnGetImage;
   property OnGetSrcForNode : TGetStream read FOnGetSrcForNode write FOnGetSrcForNode;
   property OnLoadStreamForScript : TLoadStream read FOnLoadStreamForScript write FOnLoadStreamForScript;
 end;

implementation

{ TSceneNodeNew }

constructor TSceneNodeNew.Create;
begin
  inherited;
  Name := '';
  Content := '';
  IDName := '';
  waitingfilename := '';
  FMouseIn := false;
  FVisible := True;
  theRealObject := Nil;
end;

destructor TSceneNodeNew.Destroy;
begin

  inherited;
end;

function TSceneNodeNew.GetValueByName(inName: String): String;
begin
 if not Assigned(AttList) then begin result := ''; exit; end;
  result := AttList.GetValueByName(inName);
end;

procedure TSceneNodeNew.SetContent(inStr: String);
Var
  s1 : String;
  i : integer;
  CurrentPos : integer;
  CurrentName : String;
 begin
  if inStr = '' then
   begin
    Name := '';
    Content := '';
    IDName := '';
   end else
   begin
    s1 := trim(inStr);
    i := Pos('<',s1);
    if i = 0 then
     begin
      // means this is not a valide XML-like node text...
      Name := '';
      Content := '';
      IDName := '';
      exit;
     end else
    if i <> 1 then
     begin
      // means there is error about this node...
      Name := '';
      Content := '';
      IDName := '';
      exit;
     end else
     begin
      CurrentPos := i;
      i := Pos('>',s1);
      if i = 0 then
       begin
        // means this is not a valid XML-like node text...
        Name := '';
        Content := '';
        IDName := '';
        exit;
       end else
       begin
        CurrentName := trim(Copy(s1,CurrentPos,i-1));
        delete(s1,CurrentPos,i);
        if CurrentName = '' then
         begin
          // means this is not a valid XML-like node text...
          Name := '';
          Content := '';
          IDName := '';
          exit;
         end;
        if CurrentName[Length(CurrentName)] = '/' then
         begin
          // means this node is an blank node just like <style/>
          delete(CurrentName,1,1);
          delete(CurrentName,Length(CurrentName),1);
          CurrentName := trim(CurrentName);
          if CurrentName = '' then
           begin
            // error occur, the tag fill just with /...
            Name := '';
            Content := '';
            IDName := '';
            exit;
           end else
          if Pos(' ',CurrentName) = 0 then
           begin
            Name := CurrentName;
            Content := '';
            IDName := '';
            exit;
           end else
           begin
            Name := trim(Copy(CurrentName,1,Pos(' ',CurrentName)));
            delete(CurrentName,1,Pos(' ',CurrentName));
            CurrentName := trim(CurrentName);
            if not Assigned(AttList) then
             AttList := TAttributeList.Create;
            AttList.SetContent(CurrentName,';');
            Content := '';
            IDName := '';
            exit;
           end;
         end else
         begin
          if Pos(' ',CurrentName) <> 0 then
           begin
            if CurrentName[1] = '<' then
             Delete(CurrentName,1,1);
            Name := trim(Copy(CurrentName,1,Pos(' ',CurrentName)));
            delete(CurrentName,1,Pos(' ',CurrentName));
            CurrentName := trim(CurrentName);
            if not Assigned(AttList) then
             AttList := TAttributeList.Create;
            AttList.SetContent(CurrentName,';');
           end else
            Name := CurrentName;
         end;
        i := Pos('<',s1);
        if i = 0 then
         begin
          Content := s1;
          exit;
         end else
         begin
          Content := Copy(s1,1,i-1);
          delete(Content,1,i-1);      //omit following lines means we are not support sub items for
                                      //this version...
          {if not Assigned(SubNodes) then
           begin
            SubNodes := TSceneNodeList.create(self);
            SubNodes.OnGetItemWH := OnGetItemWH;
            SubNodes.OnBackSubWH := GetSubWH;
            SubNodes.OnRequestMessage := OnRequestMessage;
            SubNodes.OnGetImage := OnGetImage;
            if Assigned(theCanvas) then
             SubNodes.SetCanvas(theCanvas);
            SubNodes.ShowType := ShowType;
           end;
          SubNodes.SetContent(s1);}
         end;
       end;
     end;
   end;
 end;

procedure TSceneNodeNew.SetFLeft(Value: integer);
begin
 if FLeft = Value then
  exit;
 FLeft := Value;
end;

procedure TSceneNodeNew.SetFMouseIn(Value: Boolean);
begin
 if FMouseIn = Value then
  exit;
 FMouseIn := Value;
end;

procedure TSceneNodeNew.SetFShowType(Value: Byte);
begin
 if FShowType = Value then
  exit;
 FShowType := Value;
end;

procedure TSceneNodeNew.SetFTop(Value: integer);
begin
 if FTop = Value then
  exit;
 FTop := Value;
end;

procedure TSceneNodeNew.SetFVisible(Value: Boolean);
begin
 if FVisible = Value then
  exit;
 FVisible := Value;
end;

{ TNewSceneDOCNew }

procedure TNewSceneDOCNew.AddNode(inStr: String);
Var
  tmpNode : TSceneNodeNew;
  //BKM : TBookContainer;
  //BGroup : TButtonContainer;
  //TGroup : TVerticalListContainer;
  //SSelfControl : TSelfControlItem;
  //SSelfSVG : TVGShap;
  s : String;
  x,y,w,h : integer;
  p1 : Pointer;
  ncolor : TColor;
  s1,s2 : string;
  tmpStream : TMemoryStream;

 begin
  if inStr = '' then exit;
  tmpNode := TSceneNodeNew.Create;
  //if Assigned(theCanvas) then
  // tmpNode.SetCanvas(theCanvas);

  tmpNode.OnRequestMessage := OnRequestMessage;
  tmpNode.OnGetImage := OnGetImage;

  tmpNode.SetContent(inStr);
  if tmpNode.Name = '' then
   begin
    tmpNode.Free;
   end else
    begin
     AddObject('',tmpNode);
     {
     if tmpNode.Name = 'SELFCONTROL' then
      begin
       SSelfControl := TSelfControlItem.create;
       SSelfControl.parentX := parentX;
       SSelfControl.parentY := parentY;
       SSelfControl.OnGetImage := giveTheBMP2;
       SSelfControl.OnSendOut := MsgFromControl;
       SSelfControl.OnLoadStream := LoadStreamForScript;
       GetCor_Value(tmpNode,x,y,w,h);
       tmpNode.Left := x;
       tmpNode.Top := y;
       tmpNode.Width := w;
       tmpNode.Height := h;
       SSelfControl.Left := x;
       SSelfControl.Top := y;
       SSelfControl.Width := w;
       SSelfControl.Height := h;

       if assigned(thecanvas) then
        SSelfControl.SetParentCanvas(thecanvas);

       s := '';
       s := tmpNode.GetValueByName('bgcolor');
       if s <> '' then
        begin
         while Pos('#',s) <> 0 do
          s[Pos('#',s)] := '$';
         SSelfControl.BC := StringToColor(s);
        end;
       s := '';
       s := tmpNode.GetValueByName('fillDefs');
       if s <> '' then
        begin
         SSelfControl.FillDefs := s;
        end;
       s := '';
       s := tmpNode.GetValueByName('line-color');
       if s <> '' then
        begin
         while Pos('#',s) <> 0 do
          s[Pos('#',s)] := '$';
         SSelfControl.PC := StringToColor(s);
        end;
       s := '';
       s := tmpNode.GetValueByName('font-color');
       if s <> '' then
        begin
         while Pos('#',s) <> 0 do
          s[Pos('#',s)] := '$';
         SSelfControl.FC := StringToColor(s);
        end;
       s := '';
       s := tmpNode.GetValueByName('font-size');
       if s <> '' then
        begin
         SSelfControl.FS := StrToInt(s);
        end;
       s := '';
       s := tmpNode.GetValueByName('font-name');
       if s <> '' then
        begin
         SSelfControl.FN := s;
        end;
       s := '';
       s := tmpNode.GetValueByName('name');
       if s <> '' then
        begin
         tmpNode.IDName := s;
         SSelfControl.setIDName(s);
        end;
       s := '';
       s := tmpNode.GetValueByName('ParamStr');
       if s <> '' then
        begin
         s := BackToDQuot(s);
         s := BackToColon(s);
         SSelfControl.SetParamVar(s);
        end;
       s := '';
       s := tmpNode.GetValueByName('onclick');
       if s <> '' then
        begin
         //s := BackToDQuot(s);
         SSelfControl.OnClickS := s;
        end;

       s := '';
       s := tmpNode.GetValueByName('onmousemove');
       if s <> '' then
        begin
         //s := BackToDQuot(s);
         SSelfControl.OnMouseMove := s;
        end;
       s := '';
       s := tmpNode.GetValueByName('onmousedown');
       if s <> '' then
        begin
         //s := BackToDQuot(s);
         SSelfControl.OnMouseDownS := s;
        end;
       s := '';
       s := tmpNode.GetValueByName('onmouseup');
       if s <> '' then
        begin
         //s := BackToDQuot(s);
         SSelfControl.OnMouseUpS := s;
        end;
       s := '';
       s := tmpNode.GetValueByName('onkeypress');
       if s <> '' then
        begin
         //s := BackToDQuot(s);
         SSelfControl.OnKeyPressS := s;
        end;
       s := '';
       s := tmpNode.GetValueByName('onkeydown');
       if s <> '' then
        begin
         //s := BackToDQuot(s);
         SSelfControl.OnKeyDownS := s;
        end;
       s := '';
       s := tmpNode.GetValueByName('src');
       if s <> '' then
        begin
         tmpStream := TMemoryStream.Create;
         GetSrcForNode(s,tmpStream);
         if tmpStream.Size = 0 then
          begin end else
          SSelfControl.SetSource(tmpStream);
         FreeAndNil(tmpStream);
        end;
       (*s := '';
       s := tmpNode.GetValueByName('style');
       if s <> '' then
        begin
         while Pos('#',s) <> 0 do
          s[Pos('#',s)] := '$';
         SSelfControl.PC := StringToColor(s);
        end; *)
       tmpNode.theRealObject := SSelfControl;
       tmpNode.theCClassName := 'SELFCONTROL';
      end else  }
      begin
       GetCor_Value(tmpNode,x,y,w,h);
       tmpNode.Left := x;
       tmpNode.Top := y;
       tmpNode.Height := h;
       tmpNode.Width := w;
       s := '';
       s := tmpNode.GetValueByName('name');
       if s <> '' then
        tmpNode.IDName := s;
       if tmpNode.theCClassName = 'GIFIMAGE' then
       begin end else
       tmpNode.theCClassName := 'FL';
      end;
    end;
 end;

procedure TNewSceneDOCNew.arrangeItems;
begin

end;

procedure TNewSceneDOCNew.changeMsg(Msg: String);
begin

end;

procedure TNewSceneDOCNew.Clear;
Var
 i : integer;
begin
  if Count = 0 then
   begin end else
   begin
     for I := 0 to Count - 1 do
      TSceneNodeNew(Objects[i]).DisposeOf;
   end;
  FCursor := crDefault;
  Version := '1.0';
  StandAlone := True;
  Title := '';
  StyleSheetType := 0;
  Encoding := 'gb2312';
  //XMLSource := '';
  FCursor := crDefault;
  alignleft := 0;
  alignright := 0;
  aligntop := 0;
  alignbottom := 0;
  MousePos.X := 0;
  mousePos.Y := 0;
  inherited;
end;

constructor TNewSceneDOCNew.create;
begin
  inherited;
  Version := '1.0';
  StandAlone := True;
  Title := '';
  StyleSheetType := 0;
  Encoding := 'gb2312';
  XMLSource := '';
  FCursor := crDefault;
  alignleft := 0;
  alignright := 0;
  aligntop := 0;
  alignbottom := 0;
  MousePos.X := 0;
  mousePos.Y := 0;
end;

destructor TNewSceneDOCNew.destroy;
var
 i : integer;
begin
  if Count = 0 then
   begin end else
   begin
     for I := 0 to Count - 1 do
      TSceneNodeNew(Objects[i]).DisposeOf;
   end;
  inherited;
end;

procedure TNewSceneDOCNew.DrawOut(Startx, wWidth, StartY, wHeight,
  delta: integer; theCanvas: TCanvas);
begin

end;

procedure TNewSceneDOCNew.GetCor_Value(inNode: TSceneNodeNew; var x, y, w,
  h: integer);
Var
  s : string;
  extname : String;
  //theGif : TGifImage;
  i,j,k,l : integer;
  tx,ty : integer;
  ttB2 : TBitMap;
  tmpStream : TMemoryStream;
 begin
  s := '';
  s := inNode.GetValueByName('left');
  if Pos('%',s) <> 0 then
   begin
    system.Delete(s,Pos('%',s),1);
    i := StrToInt(s);
   end else
  if s <> '' then
   i := StrToInt(s)
  else
   i := -1;

  s := '';
  s := inNode.GetValueByName('top');
  if Pos('%',s) <> 0 then
   begin
    system.Delete(s,Pos('%',s),1);
    j := StrToInt(s);
   end else
  if s <> '' then
   j := StrToInt(s)
  else
   j := -1;

  s := '';
  s := inNode.GetValueByName('width');
  if Pos('%',s) <> 0 then
   begin
    system.Delete(s,Pos('%',s),1);
    k := (StrToInt(s) * width) div 100;
   end else
  if s <> '' then
   k := StrToInt(s)
  else
   k := -1;

  s := '';
  s := inNode.GetValueByName('height');
  if Pos('%',s) <> 0 then
   begin
    system.Delete(s,Pos('%',s),1);
    l := (StrToInt(s) * Height) div 100;
   end else
  if s <> '' then
   l := StrToInt(s)
  else
   l := -1;

  if (i <> -1) and (j <> -1) and (k <> -1) and (l <> -1) then
   begin
    x := i; y := j; w := k; h := l;
    exit;
   end;

  if inNode.Name = 'TEXT' then
   begin
        s := '';
        s := inNode.GetValueByName('style');
        //ReturnTheTextSize(inNode.Content,s,k,l);
        if (i <> -1) and (j <> -1) and (k <> -1) and (l <> -1) then
         begin
          x := i; y := j; w := k; h := l;
          exit;
         end;
   end;

  if inNode.Name = 'IMAGE' then
   begin
    if (k = -1) or (l = -1) then
     begin
      ttB2 := TBitMap.Create;
      if assigned(OnGetImage) then
       begin
        FOnGetImage(ttB2,inNode.GetValueByName('src'));
        tx := ttB2.Width;
        ty := ttB2.Height;
       end else
       begin
        tx := 0;
        ty := 0;
       end;
      ttB2.Free;
     end;
    if k = -1 then k := tx;
    if l = -1 then l := ty;
    s := '';
    s := inNode.GetValueByName('src');
    extname := '';
    if s <> '' then
     begin
      extname := Uppercase(ExtractFileExt(s));
     end;


        if (i <> -1) and (j <> -1) and (k <> -1) and (l <> -1) then
         begin
          x := i; y := j; w := k; h := l;
            {
            if (extname = '.GIF') and (inNode.theCClassName <> 'GIFIMAGE') then
             begin
              theGif := TGifImage.Create;
              inNode.theCClassName := 'GIFIMAGE';
              inNode.waitingfilename := s;
              inNode.theRealObject := theGif;
              if (tx = 0) or (ty = 0) then
               begin
               end else
               begin
                tmpStream := TMemoryStream.Create;
                getSrcForNode(s,tmpStream);
                if tmpStream.Size <> 0 then
                 begin
                  tmpStream.Seek(0,0);
                  theGif.LoadFromStream(tmpStream);
                 end;
                FreeAndNil(tmpStream);
               end;
             end; }
          exit;
         end;
   end;

  s := '';
  s := inNode.GetValueByName('align');
  if s = '' then begin end else
  if s = 'CLIENT' then
   begin
    i := alignLeft+1;
    j := aligntop+1;
    k := width - (alignleft + alignright)-1;
    l := height - (aligntop + alignbottom)-1;
    x := i; y := j;
    w := k; h := l;
    exit;
   end else
  if s = 'LEFT' then
   begin
    i := alignLeft;
    alignLeft := alignLeft + k;
    j := 0;
    l := Height - (aligntop + alignBottom);
    x := i; y := j;
    w := k; h := l;
    exit;
   end else
  if s = 'TOP' then
   begin
    i := alignleft;
    j := aligntop;
    aligntop := aligntop + l;
    k := Width - (alignleft + alignRight);
    x := i; y := j;
    w := k; h := l;
    exit;
   end else
  if s = 'RIGHT' then
   begin
    i := width - alignright-k;
    j := aligntop;
    alignright := alignright + k;
    l := Height - (aligntop + alignBottom);
    if l = Height then l := Height - 2;
    if j = 0 then j := 1;
    x := i; y := j;
    w := k; h := l;
    exit;
   end else
  if s = 'BOTTOM' then
   begin
    i := 0;
    j := Height - alignBottom-l;
    k := Width - (alignleft + alignright);
    alignbottom := alignbottom + l;
    x := i; y := j;
    w := k; h := l;
    exit;
   end;

  s := '';
  s := inNode.GetValueByName('halign');
  if s = 'LEFT' then
   begin
    i := 0;
   end else
  if s = 'RIGHT' then
   begin
    i := Width - k;
   end else
  if s = 'CENTER' then
   begin
    i := (Width - k) div 2;
   end;
        if (i <> -1) and (j <> -1) and (k <> -1) and (l <> -1) then
         begin
          x := i; y := j; w := k; h := l;
          exit;
         end;

  s := '';
  s := inNode.GetValueByName('valign');
  if s = 'TOP' then
   begin
    j := 0;
   end else
  if s = 'BOTTOM' then
   begin
    j := Height - l;
   end else
  if s = 'CENTER' then
   begin
    j := (Height - l) div 2;
   end;
  x := i; y := j; w := k; h := l;
           s := '';
           s := inNode.GetValueByName('src');
           if s <> '' then
           begin
           if (extname = '.GIF') and (inNode.theCClassName <> 'GIFIMAGE') then
             begin
              {theGif := TGifImage.Create;
              inNode.theCClassName := 'GIFIMAGE';
              inNode.waitingfilename := s;
              inNode.theRealObject := theGif;
              if (tx = 0) or (ty = 0) then
               begin
               end else
               begin
                tmpStream := TMemoryStream.Create;
                getSrcForNode(s,tmpStream);
                if tmpStream.Size <> 0 then
                 begin
                  tmpStream.Seek(0,0);
                  theGif.LoadFromStream(tmpStream);
                 end;
                FreeAndNil(tmpStream);
               end; }
             end;
           end;
 end;

procedure TNewSceneDOCNew.getImageForNode(index: integer);
begin

end;

procedure TNewSceneDOCNew.GetSrcForNode(inStr: String;
  theStream: TMemoryStream);
begin

end;

procedure TNewSceneDOCNew.givetheBMP(Handle: String; var theGraph: TBitMap);
begin

end;

procedure TNewSceneDOCNew.givetheBMP2(theP: TBitMap; theLink: String);
begin

end;

procedure TNewSceneDOCNew.LoadStreamForScript(inStr: String;
  var DataStored: TMemoryStream; sType: Byte);
begin

end;

procedure TNewSceneDOCNew.MsgFromControl(var Msg: String);
begin

end;

procedure TNewSceneDOCNew.Refresh;
begin

end;

procedure TNewSceneDOCNew.selfDblClick;
begin

end;

procedure TNewSceneDOCNew.selfKeyDown(var Key: Word; Shift: TShiftState);
begin

end;

procedure TNewSceneDOCNew.selfKeyPress(var Key: Char);
begin

end;

procedure TNewSceneDOCNew.selfKeyUp(var Key: Word; Shift: TShiftState);
begin

end;

procedure TNewSceneDOCNew.selfMouseClick;
begin

end;

function TNewSceneDOCNew.selfMouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer): Boolean;
begin

end;

function TNewSceneDOCNew.selfMouseMove(Shift: TShiftState; X,
  Y: integer): Boolean;
begin

end;

function TNewSceneDOCNew.selfMouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer): Boolean;
begin

end;

procedure TNewSceneDOCNew.SetContent(inStr: String);
begin
  XMLSource := inStr;
  if XMLSource = '' then exit;
  Cursor := crAppStart;
  Clear;
  XMLParser;
  if Count = 0 then exit;
  //arrangeItems;
  Cursor := crDefault;
  if (Width = 0) or (Height = 0) then exit;
  {if assigned(SavedBackGround) then SavedBackGround.Free;
  SavedBackGround := TBitMap.Create;
  SavedBackGround.Width := Width;
  SavedBackGround.Height := Height;
  SavedBackGround.PixelFormat := pf24Bit;}
 end;

procedure TNewSceneDOCNew.SetContent(inStr, thePath: String);
begin
  XMLSource := inStr;
  CurrentPath := thePath;
  if XMLSource = '' then exit;
  Cursor := crAppStart;
  XMLParser;
  if Count = 0 then exit;
  //arrangeItems;
  Cursor := crDefault;
  {if assigned(SavedBackGround) then SavedBackGround.Free;
  SavedBackGround := TBitMap.Create;
  SavedBackGround.Width := Width;
  SavedBackGround.Height := Height;
  SavedBackGround.PixelFormat := pf24Bit;}
 end;

procedure TNewSceneDOCNew.SetFCursor(Value: integer);
begin

end;

procedure TNewSceneDOCNew.SetFLeft(Value: integer);
begin

end;

procedure TNewSceneDOCNew.SetFTop(Value: integer);
begin

end;

procedure TNewSceneDOCNew.XMLParser;
Var
 CurrentPos : integer;
 i : integer;
 C : Char;
 BakSource : String;
 CurrentName : String;
 CurrentContent : String;
 s33 : string;
 CN : String;
 tagbegin : boolean;
 XMLStart : Boolean;
 ErrorCode : integer;
 tmpNode : TSceneNodeNew;
 TotalNode : integer;
 xx : Byte;

begin
 if XMLSource = '' then exit;
 ErrorCode := 0;
 BakSource := XMLSource;
 TotalNode := 0;
 i := 1;
 tagbegin := false;
 XMLStart := false;
 repeat
  c := XMLSource[i];
  if ((not XMLStart) and (c <> '<')) then
   begin
    inc(i);
   end else
  if ((not XMLStart) and (c = '<')) then
   begin
    XMLStart := True;
    tagbegin := True;
    inc(i);
   end else
  if XMLStart and (not tagbegin) and (c = '<') then
   begin
    tagbegin := True;
    inc(i);
   end else
  if XMLStart and tagbegin and (c = '?') then
   begin
    CurrentPos := i;
    i := myPos('?>',XMLSource,CurrentPos);
    if i = 0 then
     begin
      showMessage('Error Code 1');
      ErrorCode := 1;
      exit;
     end;
    i := i + 2;
    tagbegin := false;
   end else
  if XMLStart and tagbegin and (c = '!') then
   begin
    if (XMLSource[i+1] = '-') and (XMLSource[i+2] = '-') then
     begin
      CurrentPos := i;
      i := myPos('-->',XMLSource,CurrentPos);
      if i = 0 then
       begin
        showMessage('Error Code 2');
        ErrorCode := 2;
        exit;
       end;
      i := i + 3;
      tagbegin := false;
     end else
    if (XMLSource[i+1] = '[') and (XMLSource[i+2] = 'C') and (XMLSource[i+3] = 'D') and
       (XMLSource[i+4] = 'A') and (XMLSource[i+5] = 'T') and (XMLSource[i+6] = 'A')then
     begin
      CurrentPos := i;
      i := myPos(']]>',XMLSource,CurrentPos);
      if i = 0 then
       begin
        showMessage('Error Code 3');
        ErrorCode := 3;
        exit;
       end;
      i := i + 3;
      tagbegin := false;
     end else
    if (XMLSource[i+1] = 'D') and (XMLSource[i+2] = 'O') and (XMLSource[i+3] = 'C') and
       (XMLSource[i+4] = 'T') and (XMLSource[i+5] = 'Y') and (XMLSource[i+6] = 'P') and
       (XMLSource[i+7] = 'E') then
     begin
      CurrentPos := i;
      i := myPos('>',XMLSource,CurrentPos);
      if i = 0 then
       begin
        showMessage('Error Code 1000');
        exit;
       end;
      i := i + 1;
      tagbegin := false;
     end else
     begin
        showMessage('Error Code 4');
        ErrorCode := 4;
        exit;
     end;
   end else
  if XMLStart and tagbegin  then
   begin
    CurrentPos := i;
    i := myPos('>',XMLSource,CurrentPos);
    if i = 0 then
     begin
      showMessage('Error Code 5');
      ErrorCode := 5;
      exit;
     end;
    //following code treate the blank code such as <style/>,
    //this means this node has no data...
    if XMLSource[i-1] = '/' then
     begin
      CurrentName := Copy(XMLSource,CurrentPos-1,i-CurrentPos+2);
      //means CurrentName just like <xxxxxx/>
      AddNode(CurrentName);
      tagbegin := false;
     end else
     begin
      //else, it is a normal node ...
      CurrentName := Copy(XMLSource,CurrentPos,i-CurrentPos);
      CN := CurrentName;
      CurrentName := trim(CurrentName);

      //get the node name...
      if CurrentName = '' then
       begin
        showMessage('Error Code 7');
        ErrorCode := 7;
        exit;
       end;

      if Pos(' ',CurrentName) = 0 then
       s33 := '' else
      begin
       s33 := CurrentName;
       CurrentName := trim(GetHeadString(s33,' '));
       s33 := trim(s33);
      end;

      //CurrentPos := i + 1;

      i := myPairPos('<'+CurrentName,'</'+CurrentName+'>',XMLSource,CurrentPos);
      //find out this node's end point
      //get out the content of this node, may include sub-node ...
      CurrentContent := Copy(XMLSource,CurrentPos-1,i-CurrentPos+1);
      // CurrentContent may be <xxx sss sss> sssssss sss           || no the end of </xxx>
      AddNode(CurrentContent);
      i := i + length('</'+CurrentName+'>');
      tagbegin := false;
     end;
   end else
  if XMLStart and (not tagBegin) then
   inc(i);
 until (((not tagBegin) and (myPos('<',XMLSource,i)=0)) or (i > Length(XMLSource)));
 XMLSource := BakSource;
end;

{ TSimpleContainer }

function TSimpleContainer.GetItemByReal(theReal: TObject) : TSceneNodeNew;
Var
 i : integer;
begin
 result := nil;
 if count = 0 then
  exit;
 for I := 0 to count - 1 do
  if TSceneNodeNew(Objects[i]).TherealObject = theReal then
   begin
    result := TSceneNodeNew(Objects[i]);
    exit;
   end;
end;

procedure TSimpleContainer.addItem(inItem: TSceneNodeNew);
begin
 if indexOfObject(inItem) <> -1 then
  exit;
 addObject('',inItem);
end;

constructor TSimpleContainer.Create;
begin
  inherited;
end;

destructor TSimpleContainer.Destroy;
Var
 i : integer;
begin
  if count = 0 then
   begin end else
   for I := 0 to count - 1 do
     TSceneNodeNew(Objects[i]).DisposeOf;
  inherited;
end;

end.
