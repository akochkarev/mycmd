unit main;

interface
uses dos,crt,keycodes,mytypes,drives,keyboard;

procedure SortByName(var Dir:TDirInfo;FileCntr:integer);
procedure SortBySize(var Dir:TDirInfo;FileCntr:integer);
procedure SortMode;
function IntLength(num:longint):byte;
function FillStr(ch:char; n:byte):string;
procedure WindowX(Wind:TWindPos);
procedure DrawPathWindow(Left:boolean; Path:string);
procedure ExchRec(var Dir:MySearchRec;var CurFile:SearchRec);
function GetDirInfo(Path:string;var Dir:TDirInfo):integer;
procedure WriteItemStr(var Dir:TDirInfo;i:integer);
procedure DrawItems(var Beg,Ending:integer;var Dir:TDirInfo;Sel:integer);
procedure PanelProcess(var CurPos,ItemsBeg,ItemsEnd:integer;var Dir:TDirInfo; FileCntr:integer);
procedure SwitchLeft;
procedure SwitchRight;
procedure InitPanel(var ItemsBeg,ItemsEnd,CurPos,FileCntr:integer);
procedure UpdatePathX(mask:string;Left:boolean;var Dir:TDirInfo;
             var Path:PathStr;var ItemsBeg,ItemsEnd,CurPos,FileCntr:integer);
procedure UpdatePathSel;
procedure UpdatePathAll;
procedure CutPath(var path:PathStr);
procedure Execute(path:PathStr);
procedure NavigateX(Left:boolean;var Dir:TDirInfo;
       var Path:PathStr;var ItemsBeg,ItemsEnd,CurPos,FileCntr:integer);
procedure OpenWith(var ProgramPath,Path:PathStr;var Dir:TDirInfo;CurPos:integer);
procedure RefreshPanels;
function ShowMessage(Mess:string):word;
procedure CreateFolder(Left:boolean;var Dir:TDirInfo;
             var Path:PathStr;var ItemsBeg,ItemsEnd,CurPos,FileCntr:integer);
procedure Cursor(Strs:word);
procedure ChangeDrive;
procedure CopyFile(FromPath,ToPath:PathStr);
procedure MoveFile(FromPath,ToPath:PathStr);
procedure DeleteFile(Path:PathStr);
procedure Selection(var Dir:TDirInfo;var CurPos:integer);
procedure RemoveDir(var Path:PathStr;var Dir:TDirInfo;var CurPos:integer);
procedure FileAction(Act:byte);
procedure UpCaseStr(var str:string);
procedure ReadConfig(CPath:PathStr);
procedure DrawHelpStr;
procedure DrawBorder;
procedure About;
procedure ShowHelpFile;

implementation

procedure SortByName(var Dir:TDirInfo;FileCntr:integer);
var AuxRec: MySearchRec;
    i,j:integer;
    start:byte;
begin
     if Dir[1].Name='..' then start:=2 else start:=1;
     for i:=start to FileCntr do
     begin
          for j:=start to FileCntr-1 do
          begin
               if Dir[j].Name > Dir[j+1].Name then
               begin
                    AuxRec:=Dir[j]; Dir[j]:=Dir[j+1]; Dir[j+1]:=AuxRec;
               end;
          end;
     end;
end;

procedure SortBySize(var Dir:TDirInfo;FileCntr:integer);
var AuxRec: MySearchRec;
    i,j:integer;
    start:byte;
begin
     if Dir[1].Name='..' then start:=2 else start:=1;
     for i:=start to FileCntr do
     begin
          for j:=start to FileCntr-1 do
          begin
               if Dir[j].Size > Dir[j+1].Size then
               begin
                    AuxRec:=Dir[j]; Dir[j]:=Dir[j+1]; Dir[j+1]:=AuxRec;
               end;
          end;
     end;
end;

procedure SortMode;
var i,j:byte; Key:word;
begin
     Window(27,10,53,16);
     TextAttr:=DialogColor;
     ClrScr;
     GotoXY(2,2); Write('    Select sort mode:');
     i:=1;
     repeat
           GotoXY(1,4);
           for j:=1 to 3 do
           begin
                if i=j then
                begin
                     TextAttr:=DialogSelColor;
                     WriteLn(SortModes[j]);
                     TextAttr:=DialogColor;
                end
                 else WriteLn(SortModes[j]);
           end;
           Key:=GetKeyEvent;
           if (Key=UpKey) and (i<>1) then dec(i);
           if (Key=DownKey) and (i<>3) then inc(i);
           if Key=Enter then break;
     until false;
     Sort:=i;
     UpdatePathAll;
end;

function IntLength(num:longint):byte;
var i:byte;
begin
     for i:=1 to 20 do
     begin
          num:= num div 10;
          if num=0 then break;
     end;
     IntLength:=i;
end;

function FillStr(ch:char; n:byte):string;
var i:byte; str:string;
begin
     str:='';
     for i:=1 to n do str:=str+ch;
     FillStr:=str;
end;

procedure WindowX(Wind:TWindPos);
begin
     Window(Wind.X1,Wind.Y1,Wind.X2,Wind.Y2);
end;

procedure DrawPathWindow(Left:boolean; Path:string);
var Sd,TAOld:byte;
begin
     TAOld:=TextAttr;
     TextAttr:=MainColor;
     if Length(Path)>36 then
     begin
          while Length(Path)+4 > 38 do
          begin
               Sd:=Pos('\',path);
               Delete(path,Sd,1);
               Delete(path,Sd,Pos('\',path)-Sd);
          end;
          Insert('\...',path,Sd);
     end;
     if Left then WindowX(PathWindL)
       else WindowX(PathWindR);
     ClrScr;
     WriteLn(FillStr('Í',(38-Length(Path)) div 2),Path,FillStr('Í',38-Length(Path)-(38-Length(Path)) div 2));
     Write('Free: ',DiskFree(DiskNum(Path[1])) div 1024);
     Write(' of ',DiskSize(DiskNum(Path[1])) div 1024,' Kb');
     TextAttr:=TAOld;
     DrawBorder;
     DrawHelpStr;
end;

procedure ExchRec(var Dir:MySearchRec;var CurFile:SearchRec);
begin
     with Dir do
     begin
          Attr:=CurFile.Attr;
          AtSt:='----';
          if Attr and ReadOnly <> 0 then AtSt[1]:='r';
          if Attr and Hidden <> 0 then AtSt[2]:='h';
          if Attr and SysFile <> 0 then AtSt[3]:='s';
          if Attr and Archive <> 0 then AtSt[4]:='a';
          Time:=CurFile.Time;
          Size:=CurFile.Size;
          Name:=CurFile.Name;
          Selected:=false;
     end;
end;

Function GetDirInfo(Path:string;var Dir:TDirInfo):integer;
var i:integer; CurFile:SearchRec;
    s:byte;
begin
     GetDirInfo:=0;
     FindFirst(Path,AnyFile,CurFile);
     if DosError<>0 then  exit;
     if (CurFile.Name<>'.') and (CurFile.Attr<>VolumeID) then
     begin
          ExchRec(Dir[1],CurFile);
          s:=2;
     end
      else s:=1;
     for i:=s to MaxFiles do
     begin
          FindNext(CurFile);
          if DosError<>0 then
          begin
               GetDirInfo:=i-1;
               break;
          end
             else
          ExchRec(Dir[i],CurFile);
     end;
     case Sort of
      1:exit;
      2:SortByName(Dir,i-1);
      3:SortBySize(Dir,i-1);
     end;
end;


procedure WriteItemStr(var Dir:TDirInfo;i:integer);
var st:string;
begin
     if Dir[i].Attr=Directory then
      WriteLn(Dir[i].Name,FillStr(' ',15 - Length(Dir[i].Name)),'<DIR>',
         '        ',Dir[i].AtSt)
      else
      WriteLn(Dir[i].Name,FillStr(' ',15 - Length(Dir[i].Name)),Dir[i].Size,
        FillStr(' ',13-IntLength(Dir[i].Size)),Dir[i].AtSt);
end;


procedure DrawItems(var Beg,Ending:integer;var Dir:TDirInfo;Sel:integer);
var i:integer;
begin
     TextAttr:=MainColor;
     ClrScr;
     for i:=Beg to Ending do
     begin
          if i = Sel then
          TextAttr:=MainSelColor;
          if Dir[i].Selected then TextAttr:=TextAttr xor SelColor;
          WriteItemStr(Dir,i);
          TextAttr:=MainColor;
     end;
end;

procedure PanelProcess(var CurPos,ItemsBeg,ItemsEnd:integer;var Dir:TDirInfo; FileCntr:integer);
begin
     case Key of
     UpKey   : begin
                    if CurPos<>ItemsBeg then dec(CurPos)
                     else
                    if ItemsBeg<>1 then
                    begin
                         dec(ItemsBeg); dec(ItemsEnd); dec(CurPos);
                    end;
               end;
     DownKey : begin
                    if CurPos<>ItemsEnd then inc(CurPos)
                     else
                    if ItemsEnd<>FileCntr then
                    begin
                         inc(ItemsBeg); inc(ItemsEnd); inc(CurPos);
                    end;
               end;
     PageUp  : begin
                    if ItemsBeg > 20 then
                    begin
                         CurPos:=CurPos-20;
                         ItemsBeg:=ItemsBeg-20;
                         ItemsEnd:=ItemsEnd-20;
                    end
                     else
                    if ItemsBeg < 21 then
                    begin
                         CurPos:=CurPos-ItemsBeg+1;
                         ItemsBeg:=1;
                         if ItemsEnd > 20 then ItemsEnd:=20
                          else
                         if ItemsEnd = FileCntr then ItemsEnd:=FileCntr;
                    end;
               end;

     PageDown: begin
                    if ItemsEnd+20 < FileCntr then
                    begin
                         CurPos:=CurPos+20;
                         ItemsBeg:=ItemsBeg+20;
                         ItemsEnd:=ItemsEnd+20;
                    end
                     else
                    if FileCntr-ItemsEnd < 21 then
                    begin
                         CurPos:=CurPos+FileCntr-ItemsEnd;
                         ItemsBeg:=ItemsBeg+FileCntr-ItemsEnd;
                         ItemsEnd:=FileCntr;
                    end;
               end;

     end;

          DrawItems(ItemsBeg,ItemsEnd,Dir,CurPos);
end;

procedure SwitchLeft;
begin
     WindowX(PanelL);
     ActiveLeft:=true;
end;

procedure SwitchRight;
begin
     WindowX(PanelR);
     ActiveLeft:=false;
end;
procedure InitPanel(var ItemsBeg,ItemsEnd,CurPos,FileCntr:integer);
begin
     ItemsBeg:=1; ItemsEnd:=20; CurPos:=1;
     if ItemsEnd > FileCntr then ItemsEnd:=FileCntr;
end;

procedure UpdatePathX(mask:string;Left:boolean;var Dir:TDirInfo;
             var Path:PathStr;var ItemsBeg,ItemsEnd,CurPos,FileCntr:integer);
begin
     FileCntr:=GetDirInfo(Path+mask,Dir);
     if FileCntr=0 then
     begin
          ShowMessage('Fatal error. Path not found.');
          ChangeDrive;
          Exit;
     end;
     InitPanel(ItemsBeg,ItemsEnd,CurPos,FileCntr);
     DrawPathWindow(Left,Path);
     if Left then WindowX(PanelL)
      else
     WindowX(PanelR);
     DrawItems(ItemsBeg,ItemsEnd,Dir,1);
end;
procedure UpdatePathSel;
begin
     if ActiveLeft then
        UpdatePathX(Mask,True,DirL,PathL,ItemsBegL,ItemsEndL,CurPosL,FileCntrL)
      else
        UpdatePathX(Mask,False,DirR,PathR,ItemsBegR,ItemsEndR,CurPosR,FileCntrR);
end;

procedure UpdatePathAll;
begin
     UpdatePathX(Mask,True,DirL,PathL,ItemsBegL,ItemsEndL,CurPosL,FileCntrL);
     UpdatePathX(Mask,False,DirR,PathR,ItemsBegR,ItemsEndR,CurPosR,FileCntrR);
     if ActiveLeft then SwitchLeft else SwitchRight;
end;

procedure CutPath(var path:PathStr);
begin
     repeat
        Delete(path,Length(path),1);
        if path[Length(path)]='\' then break;
     until false;
end;
procedure Execute(path:PathStr);
begin
     Exec(GetEnv('COMSPEC'),'/c'{'/k'}+path);
end;
      {when pressing Enter - open dirs & run programs}
procedure NavigateX(Left:boolean;var Dir:TDirInfo;
             var Path:PathStr;var ItemsBeg,ItemsEnd,CurPos,FileCntr:integer);
begin
          if Dir[CurPos].Name='..' then CutPath(Path)
           else
          if (Dir[CurPos].Attr=Directory) and (Dir[CurPos].Name<>'.')
                       then Path:=Path+Dir[CurPos].Name+'\'
           else Execute(Path+Dir[CurPos].Name);
           UpdatePathX(Mask,Left,Dir,Path,ItemsBeg,ItemsEnd,CurPos,FileCntr);

end;

procedure OpenWith(var ProgramPath,Path:PathStr;var Dir:TDirInfo;CurPos:integer);
begin
     Execute(' '+ProgramPath+' '+Path+Dir[CurPos].Name);
end;

procedure RefreshPanels;
begin
     DrawPathWindow(true,PathL);
     DrawPathWindow(false,PathR);
     WindowX(PanelL);
     DrawItems(ItemsBegL,ItemsEndL,DirL,CurPosL);
     WindowX(PanelR);
     DrawItems(ItemsBegR,ItemsEndR,DirR,CurPosR);
     if ActiveLeft then SwitchLeft else SwitchRight;
end;

function ShowMessage(Mess:string):word;
var x1,x2:byte; TAOld:byte;
begin
     TAOld:=TextAttr;
     if Length(mess) > 78 then
     begin x1:=2; x2:=78 end
      else
     begin
     x1:=40-Length(mess) div 2;
     x2:=40+Length(mess) div 2;
     end;
     Window(x1,12,x2,14);
     TextAttr:=MessColor;
     ClrScr;
     gotoxy(1,2); write(Mess);
     ShowMessage:=GetKeyEvent;
     TextAttr:=TAOld;
     RefreshPanels;
end;

procedure CreateFolder(Left:boolean;var Dir:TDirInfo;
             var Path:PathStr;var ItemsBeg,ItemsEnd,CurPos,FileCntr:integer);{vot tebe rabotenka na zavtra!!!}
var Ch:char; i:byte; Folder:string[8];
begin
     {$I-}
     Window(20,10,59,14);
     TextAttr:=DialogColor;
     ClrScr;
     GotoXY(4,2); Write('Create new directory');
     GotoXY(4,3);
     Write(Path);
     Cursor($0010);
     ReadLn(Folder);
     Cursor($2020);
     MkDir(Path+Folder);
     if IOResult <> 0 then
     begin
          Writeln('   Cant create directory');
          GetKeyEvent;
     end;
     UpdatePathAll;
     {$I+}
end;

procedure Cursor(Strs:word);
var  R:registers;
begin
     R.AH:=1;
     R.CX:=Strs;
     Intr($10,R);
end;

procedure ChangeDrive;
var DrvStr:string[26];
    i,pos,TAOld:byte;
    Key:Word;
begin
     TAOld:=TextAttr;
     DrvStr:=DOSDrives;
     if ActiveLeft then Window(17,1,23,2+Length(DrvStr))
      else Window(57,1,63,2+Length(DrvStr));
     TextAttr:=MessColor;
     for i:=1 to Length(DrvStr)+2 do
     begin
          Write('       ');
          delay(600);
     end;
     pos:=1;
     repeat
           for i:=1 to Length(DrvStr) do
           begin
                GotoXY(2,1+i);
                if i=pos then TextAttr:=MessSelColor;
                WriteLn('  ',DrvStr[i],'  '); TextAttr:=MessColor;
           end;
           Key:=GetKeyEvent;
           if Key=Enter then
           begin
                if ActiveLeft then PathL:=DrvStr[pos]+':\'
                 else PathR:=DrvStr[pos]+':\';
                UpdatePathSel;
                TextAttr:=TAOld;
                Exit;
           end;
           if (Key=UpKey)and(pos>1) then dec(pos);
           if (Key=DownKey)and(pos<Length(DrvStr)) then inc(pos);
     until (Key=Esc)and((FileCntrL and FileCntrR)<>0);
     TextAttr:=TAOld;
     RefreshPanels;
end;

procedure CopyFile(FromPath,ToPath:PathStr);
var
  Incr:longint;
  Sum:longint;
  FromF, ToF: file;
  NumRead, NumWritten: Word;
  Buf: array[1..2048] of Char;
  Attr,Key:word;
begin
  Assign(FromF,FromPath); { Open input file }
  GetFAttr(FromF,Attr);
  if Attr and Directory <> 0 then
  begin
       ShowMessage('Cant copy dirs. Sorry. :(');
       exit;
  end;

  Window(15,9,65,16);
  TextAttr:=DialogColor;
  ClrScr;
  GotoXY(22,2); Write('Copyng');
  GotoXY(2,3); Write(FromPath);
  GotoXY(24,4); Write('to');
  GotoXY(2,5); Write(ToPath);
  GotoXY(16,7); Write('Enter-OK / Esc-Cancel');
  repeat
        Key:=GetKeyEvent;
        case Key of
        Esc : break;
        Enter :
          begin
               SetFAttr(FromF,0);
               Reset(FromF, 1);  { Record size = 1 }
               if DiskFree(DiskNum(ToPath[1])) < FileSize(FromF) then
               begin
                    ShowMessage('No free space on drive '+ToPath[1]);
               end
                else
               begin
                    Assign(ToF,ToPath); { Open output file }
                    Rewrite(ToF,1);
                    GotoXY(10,7); Write('<.............................>');
                    GotoXY(11,7);
                    incr:=FileSize(FromF) div 30;
                    sum:=0;
                    repeat
                          BlockRead(FromF, Buf, SizeOf(Buf), NumRead);
                          Sum:=Sum+NumRead;
                          if Sum >= Incr then
                          begin
                               Write('');
                               Sum:=0;
                          end;
                          BlockWrite(ToF, Buf, NumRead, NumWritten);
                    until (NumRead = 0) or (NumWritten <> NumRead);
                    SetFAttr(ToF,Attr);
                    Close(ToF);
               end;
               Close(FromF);
               break;
          end;
        end;
  until false;
  SetFAttr(FromF,Attr);
end;

procedure MoveFile(FromPath,ToPath:PathStr);
var
  F: file;
  Key,Attr:word;
  NewName:String[12];
begin
  Assign(F,FromPath);
  GetFAttr(F,Attr);
  if Attr and Directory <> 0 then
  begin
       ShowMessage('Cant move dirs. Sorry.');
       exit;
  end;
  SetFAttr(F,0);
  Reset(F);
  Window(15,9,65,16);
  TextAttr:=DialogColor;
  ClrScr;
  GotoXY(22,2); Write('Rename');
  GotoXY(2,3); Write(FromPath);
  GotoXY(24,4); Write('to');
  GotoXY(16,7); Write('Enter-OK / Esc-Cancel');
  GotoXY(2,5); Write(ToPath);
  repeat
        Key:=GetKeyEvent;
        case Key of
        Esc : break;
        Enter :
          begin
               {$I-}
               GotoXY(2,5); Write(ToPath);
               Cursor($0010);
               ReadLn(NewName);
               Cursor($2020);
               Rename(F,ToPath+NewName);
               if IOResult<>0 then ShowMessage('Error moving file');
               break;
          end;
        end;
  until false;
  SetFAttr(F,Attr);
  Close(F);
end;

procedure DeleteFile(Path:PathStr);
var
  F: file;
  Key,Attr:word;
begin
  Assign(F,Path);
  GetFAttr(F,Attr);
  if Attr and Directory <> 0 then
  begin
       if ActiveLeft then RemoveDir(PathL,DirL,CurPosL)
        else RemoveDir(PathR,DirR,CurPosR);
       exit;
  end;
  SetFAttr(F,0);
  Window(15,9,65,16);
  TextAttr:=DialogColor;
  ClrScr;
  GotoXY(22,2); Write('Delete!');
  GotoXY(2,3); Write(Path);
  GotoXY(16,7); Write('Enter-OK / Esc-Cancel');
  repeat
        Key:=GetKeyEvent;
        case Key of
        Esc : break;
        Enter :
          begin
               {$I-}
               Reset(F);
               Erase(F);
               if IOResult<>0 then
               Begin
                    ShowMessage('Cant delete file');
                    exit;
               end;
               {$I+}
               Close(F);
               exit;
          end;
        end;
  until false;
  SetFAttr(F,Attr);
end;

procedure Selection(var Dir:TDirInfo;var CurPos:integer);
begin
     if Dir[CurPos].Name='..' then exit;
     if Dir[CurPos].Selected=false then Dir[CurPos].Selected:=true
      else Dir[CurPos].Selected:=false;
     Key:=DownKey;
     RefreshPanels;
end;

procedure RemoveDir(var Path:PathStr;var Dir:TDirInfo;var CurPos:integer);
var Key:word;
begin
     {$I-}
     Window(15,9,65,16);
     TextAttr:=DialogColor;
     ClrScr;
     GotoXY(22,2); Write('Delete Dir?');
     GotoXY(2,3); Write(Path+Dir[CurPos].Name);
     GotoXY(16,7); Write('Enter-OK / Esc-Cancel');
     repeat
        Key:=GetKeyEvent;
        case Key of
        Esc : begin RefreshPanels; exit; end;
        Enter :
          begin
               RmDir(Path+Dir[CurPos].Name );
               if IOResult <> 0 then
               begin
                    ShowMessage('Can not delete dir!');
                    RefreshPanels;
                    Exit;
               end;
               break;
          end;
        end;
  until false;
end;

procedure FileAction(Act:byte);
var i:integer;
begin
     if ActiveLeft then
     begin
           case Act of
           5:CopyFile(PathL+DirL[CurPosL].Name,PathR+DirL[CurPosL].Name);
           6:MoveFile(PathL+DirL[CurPosL].Name,PathR);
           8:DeleteFile(PathL+DirL[CurPosL].Name);
          end;
          for i:=1 to ItemsEndL do
           if (DirL[i].Selected=true)and(i<>CurPosL) then
          begin
               case Act of
                5:CopyFile(PathL+DirL[i].Name,PathR+DirL[i].Name);
                6:MoveFile(PathL+DirL[i].Name,PathR);
                8:DeleteFile(PathL+DirL[i].Name);
               end;
          end;
     end
      else
     begin
           case Act of
           5:CopyFile(PathR+DirR[CurPosR].Name,PathL+DirR[CurPosR].Name);
           6:MoveFile(PathR+DirR[CurPosR].Name,PathL);
           8:DeleteFile(PathR+DirR[CurPosR].Name);
          end;
          for i:=1 to ItemsEndR do
           if (DirR[i].Selected=true)and(i<>CurPosR) then
          begin
               case Act of
                5: CopyFile(PathR+DirR[i].Name,PathL+DirR[i].Name);
                6: MoveFile(PathR+DirR[i].Name,PathL);
                8: DeleteFile(PathR+DirR[i].Name);
               end;
          end;
     end;
UpdatePathAll;
end;

procedure UpCaseStr(var str:string);
var i:byte;
begin
     for i:=1 to Length(str) do str[i]:=UpCase(str[i]);
end;

procedure ReadConfig(CPath:PathStr);
var F:text; str,param,value:string; n:byte;
begin
     {$I-}
     if CPath='' then exit;
     Assign(F,CPath);
     Reset(F);
     if IOResult<>0 then exit;
     while not EoF(F) do
     begin
          ReadLn(F,str);
          if str[1]='#' then continue;
          param:=Copy(str,1,Pos('=',str)-1);
          if param='' then continue;
          n:=Pos('"',str); Delete(str,n,1);
          value:=Copy(str,n,Pos('"',str)-n);
          UpCaseStr(param); UpCaseStr(value);

         if param='PATHL' then begin PathL:=value; continue end;
         if param='PATHR' then  begin PathR:=value; continue end;
         if param='VIEWER' then begin ViewerPath:=value; continue end;
         if param='EDITOR' then begin EditorPath:=value; continue end;
     end;
Close(F);
end;

procedure DrawHelpStr;
var i:byte; TAOld:byte;
begin
     TAOld:=TextAttr;
     Window(1,25,80,25);
     TextAttr:=HelpColor; ClrScr;
     for i:=1 to 10 do
     begin
          TextAttr:=HelpSelColor; Write(' F',i);
          TextAttr:=HelpColor;
          case i of
           1: Write('Help');
           2: Write('About');
           3: Write('View');
           4: Write('Edit');
           5: Write('Copy');
           6: Write('Rename');
           7: Write('MkDir');
           8: Write('Delete');
           9: Write('Sort');
           10:Write('Exit');
          end;
     end;
     TextAttr:=TAOld;
end;

procedure DrawBorder;
var i:byte;
begin
     TextAttr:=MainColor;
     Window(1,1,80,25);
     GotoXY(1,3); Write(FillStr('Í',80));
     Window(1,1,1,24); Write('ÉºÌ',FillStr('º',19),'¼');
     Window(80,1,80,24); Write('»º¹',FillStr('º',19),'È');
     Window(41,1,41,24); Write('ËºÎ',FillStr('º',19),'¼');
     Window(40,1,40,24); Write('ËºÎ',FillStr('º',19),'È');
end;
procedure About;
begin
     Window(22,9,57,15);
     GotoXY(1,1);
     TextAttr:=DialogColor; ClrScr;
     WriteLn;
     WriteLn('   Program My_Commander beta 2');
     WriteLn('               by               ');
     WriteLn('       Alexander Kochkaryov     ');
     WriteLn('            group 210a          ');
     WriteLn('            NGASU 2004          ');
     GetKeyEvent;
     RefreshPanels;
end;

procedure ShowHelpFile;
var F:text; i:byte; str:string;  Key:word;
begin
     {$I-}
     Assign(F,HelpPath);
     Reset(F);
     if IOResult<>0 then
     begin ShowMessage('Help file not found.'); Exit; end;
     Window(3,2,78,23);
     TextAttr:=DialogColor; ClrScr;
     repeat
     while not EoF(F) do
     begin
          for i:=1 to 22 do
          begin
               ReadLn(F,str);
               WriteLn(' ',str);
               Key:=GetKeyEvent;
               if Key=Esc then break;
          end;
          if Key=Esc then break;
     end;
     if Key=Esc then break else Reset(F);
     until false;
     GetKeyEvent;
     Close(F);
     RefreshPanels;
end;

end.{Ufff....}
