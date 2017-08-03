unit ScriptManager;

interface
uses
 Windows, Messages, SysUtils, Classes, FMX.Graphics, FMX.Controls;

Type
 TScriptItem = class
  private
   Source : String;
  public
   ItemName : String;
   paramString : String;
   Constructor Create(inStr : String);
   Destructor Destroy; override;
   Procedure SimpleParser;
  end;

 TScriptManager = class(TStringList)
  private
  public
   Constructor Create;
   Destructor Destroy; override;
   Procedure Clear; override;
   Function AddItem(inStr : String) : TScriptItem;
   Function GetItem(inStr : String) : String;
   Function Assigned(inStr : String) : Boolean;
   Function GetItemParamStr(inStr : String) : String;
  end;

implementation

  Constructor TScriptItem.Create(inStr : String);
   begin
    Source := inStr;
    SimpleParser;
   end;

  Destructor TScriptItem.Destroy;
   begin
    inherited;
   end;

  Procedure TScriptItem.SimpleParser;
   Var
    s,s1,s2 : string;
    i,j,k : integer;
   begin
    s := Uppercase(trim(Source));
    i := Pos('FUNCTION ',s);     //获取描述语言的头定义
    if i <> 0 then
     begin
      j := Pos(' VAR ',s);      //if we get the function, then we should get out the func name
                                //, normally, function name end with the var stating..
      if j <> 0 then            // if yes, then should get this thing to ItemName...
       begin
        s1 := Copy(s,i,j-1);
        //delete(Source,1,j-1);   //we should prepare the run body...
        s1 := trim(s1);
        delete(s1,1,Pos(' ',s1)); // delete the key word FUNCTION...
        if Pos('(',s1) <> 0 then
         begin
          ItemName := trim(Copy(s1,1,Pos('(',s1)-1));
          delete(s1,1,Pos('(',s1));
          paramString := Copy(s1,1,Pos(')',s1)-1);
         end else
         begin
          ItemName := trim(Copy(s1,1,Pos(';',s1)-1));
          paramString := '';
         end;
       end else
       begin                   // if not, that means, there are no local variables defined.
        k := Pos(' BEGIN ',s); // we find out the key word begin
        if k <> 0 then
         begin
          s1 := Copy(s,i,k-1);
          //delete(Source,1,k-1);   //we should prepare the run body...
          s1 := trim(s1);
          delete(s1,1,Pos(' ',s1)); // delete the key word FUNCTION...
          if Pos('(',s1) <> 0 then
           begin
            ItemName := trim(Copy(s1,1,Pos('(',s1)-1));
            delete(s1,1,Pos('(',s1));
            paramString := Copy(s1,1,Pos(')',s1)-1);
           end else
           begin
            ItemName := trim(Copy(s1,1,Pos(';',s1)-1));
            paramString := '';
           end;
         end else
         begin
          ItemName := '';     // that means, it is a null things...
          paramString := '';
         end;
       end;
      exit;
     end;
                                  // if not find out the FUNCTION, then should find the PROCEDURE
    i := Pos('PROCEDURE ',s);     //获取描述语言的头定义
    if i <> 0 then
     begin
      j := Pos(' VAR ',s);      //if we get the function, then we should get out the func name
                                //, normally, function name end with the var stating..
      if j <> 0 then            // if yes, then should get this thing to ItemName...
       begin
        s1 := Copy(s,i,j-1);
        //delete(Source,1,j-1);   //we should prepare the run body...
        s1 := trim(s1);
        delete(s1,1,Pos(' ',s1)); // delete the key word FUNCTION...
        if Pos('(',s1) <> 0 then
         begin
          ItemName := trim(Copy(s1,1,Pos('(',s1)-1));
          delete(s1,1,Pos('(',s1));
          paramString := Copy(s1,1,Pos(')',s1)-1);
         end else
         begin
          ItemName := trim(Copy(s1,1,Pos(';',s1)-1));
          paramString := '';
         end;
       end else
       begin                   // if not, that means, there are no local variables defined.
        k := Pos(' BEGIN ',s); // we find out the key word begin
        if k <> 0 then
         begin
          s1 := Copy(s,i,k-1);
          //delete(Source,1,k-1);   //we should prepare the run body...
          s1 := trim(s1);
          delete(s1,1,Pos(' ',s1)); // delete the key word FUNCTION...
          if Pos('(',s1) <> 0 then
           begin
            ItemName := trim(Copy(s1,1,Pos('(',s1)-1));
            delete(s1,1,Pos('(',s1));
            paramString := Copy(s1,1,Pos(')',s1)-1);
           end else
           begin
            ItemName := trim(Copy(s1,1,Pos(';',s1)-1));
            paramString := '';
           end;
         end else
         begin
          ItemName := '';     // that means, it is a null things...
          paramString := '';
         end;
       end;
      exit;
     end;
    ItemName := '';
    paramString := '';
   end;


{ TScriptManager }

function TScriptManager.AddItem(inStr: String): TScriptItem;
Var
 tmpItem : TScriptItem;
 i : integer;
 ok : boolean;
begin
 tmpItem := TScriptItem.Create(inStr);
 if tmpItem.ItemName = '' then
  begin
   tmpItem.DisposeOf;
   result := Nil;
  end else
  begin
   ok := true;
   for i := 0 to Count - 1 do
    begin
     if tmpItem.ItemName = TScriptItem(Objects[i]).ItemName then
      begin
       ok := false;
       break;
      end;
    end;
   if ok then
    begin
     AddObject('',tmpItem);
     result := tmpItem;
    end else
    begin
     tmpItem.DisposeOf;
     result := Nil;
    end;
  end;
end;

procedure TScriptManager.Clear;
Var
 i : integer;
begin
 if Count = 0 then begin end else
 for i := 0 to Count - 1 do
  begin
   TScriptItem(Objects[i]).DisposeOf;
  end;
  inherited;
end;

constructor TScriptManager.Create;
begin
  inherited;
end;

destructor TScriptManager.Destroy;
Var
 i : integer;
begin
  if Count = 0 then
   begin end else
   for I := 0 to Count - 1 do
    TScriptItem(Objects[i]).DisposeOf;
  inherited;
end;

function TScriptManager.GetItem(inStr: String): String;
Var
 i : integer;
 s : String;
 tmpItem : TScriptItem;
begin
 result := '';
 if Count = 0 then exit;
 s := trim(Uppercase(inStr));
 for i := 0 to Count - 1 do
  begin
   tmpItem := TScriptItem(Objects[i]);
   if tmpItem.ItemName = s then
    begin
     result := tmpItem.Source;
     exit;
    end;
  end;
end;

function TScriptManager.Assigned(inStr : String) : Boolean;
 Var
 i : integer;
 s : String;
 tmpItem : TScriptItem;
begin
 result := false;
 if Count = 0 then exit;
 s := trim(Uppercase(inStr));
 for i := 0 to Count - 1 do
  begin
   tmpItem := TScriptItem(Objects[i]);
   if tmpItem.ItemName = s then
    begin
     result := true;
     exit;
    end;
  end;
end;


function TScriptManager.GetItemParamStr(inStr: String): String;
Var
 i : integer;
 s : String;
 tmpItem : TScriptItem;
begin
 result := '';
 if Count = 0 then exit;
 s := trim(Uppercase(inStr));
 for i := 0 to Count - 1 do
  begin
   tmpItem := TScriptItem(Objects[i]);
   if tmpItem.ItemName = s then
    begin
     result := tmpItem.paramString;
     exit;
    end;
  end;
end;


end.
