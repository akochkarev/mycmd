{$M 20384,0,0}

uses crt,keycodes,mytypes,main;
var AuxStr:string;
begin  {main program}
     ClrScr;
     Cursor($2020);
     Mask:='*.*';
     GetDir(0,AuxStr);
     PathL:=AuxStr+'\';
     PathR:=PathL;
     EditorPath:='edit';
     ViewerPath:='edit';
     HelpPath:=AuxStr+'\mycmd.hlp';
     ReadConfig(ParamStr(1));
     Sort:=1;

     UpdatePathX(Mask,True,DirL,PathL,ItemsBegL,ItemsEndL,CurPosL,FileCntrL);
     UpdatePathX(Mask,False,DirR,PathR,ItemsBegR,ItemsEndR,CurPosR,FileCntrR);
     SwitchLeft;


     repeat   {Main cycle}
      Key:=ReadScan;
      case Key of
        RightKey : SwitchRight;
        LeftKey  : SwitchLeft;
        CtrlR : RefreshPanels;
        Space :  begin
                        if ActiveLeft then Selection(DirL,CurPosL)
                         else Selection(DirR,CurPosR);
                   end;
        Enter : begin
                if ActiveLeft then NavigateX(true,DirL,PathL,ItemsBegL,ItemsEndL,CurPosL,FileCntrL)
                  else
                 NavigateX(false,DirR,PathR,ItemsBegR,ItemsEndR,CurPosR,FileCntrR);
                end;
        F1 : ShowHelpFile;
        F2 : About;
        F3 : begin
                  if ActiveLeft then OpenWith(ViewerPath,PathL,DirL,CurPosL)
                   else OpenWith(ViewerPath,PathR,DirR,CurPosR);
             end;

        F4 : begin
                  if ActiveLeft then OpenWith(EditorPath,PathL,DirL,CurPosL)
                   else OpenWith(EditorPath,PathR,DirR,CurPosR);
             end;

        F5 :FileAction(5);
        F6 :FileAction(6);
        F7 : begin
                  if ActiveLeft then CreateFolder(True,DirL,PathL,ItemsBegL,ItemsEndL,CurPosL,FileCntrL)
                   else
                  CreateFolder(False,DirR,PathR,ItemsBegR,ItemsEndR,CurPosR,FileCntrR);
             end;
        F8 : FileAction(8);

        F9 : SortMode;

        F10 : Halt;
        AltF1 : begin
                     SwitchLeft; ChangeDrive;
                end;
        AltF2 : begin
                     SwitchRight; ChangeDrive;
                end;
      end;
      If ActiveLeft then
         PanelProcess(CurPosL,ItemsBegL,ItemsEndL,DirL,FileCntrL)
      else
         PanelProcess(CurPosR,ItemsBegR,ItemsEndR,DirR,FileCntrR);
     Until Key=Esc;
end.
