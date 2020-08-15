unit mytypes;

interface
uses dos;
const
     MaxFiles=900;

Type
    MySearchRec= record
       Attr: Byte;
       AtSt: String[4];
       Time: Longint;
       Size: Longint;
       Name: string[13];
       Ext:String[4];
       Selected: boolean;
    end;
    TDirInfo=Array[1..MaxFiles] of MySearchRec;
    TWindPos=record
       X1,Y1,X2,Y2:Byte;
    end;

const
     SortModes:Array[1..3] of string=('    Without sorting','    Sort by name','    Sort by Size');
     MainColor=$07; MainSelColor=$70; MessColor=$57; DialogColor=$17;
     DialogSelColor=$71;
     MessSelColor=$37; SelColor=$03;  HelpColor=$39; HelpSelColor=$36;
     PathWindL:TWindPos=(X1:2; Y1:1; X2:40; Y2:2);
     PathWindR:TWindPos=(X1:42; Y1:1; X2:80;Y2:2);
     PanelL:TWindPos=(X1:2; Y1:4; X2:39; Y2:24);
     PanelR:TWindPos=(X1:42; Y1:4; X2:79; Y2:24);
var
   Key:word;
   EditorPath,ViewerPath,HelpPath,
   PathL,PathR:PathStr;
   DirL,DirR:TDirInfo;
   FileCntrL,FileCntrR,
   CurPosL,CurPosR,
   ItemsBegL,ItemsBegR,
   ItemsEndL,ItemsEndR:integer;
   ActiveLeft:boolean;
   Mask:string[13];
   DisksStr:string[24];
   Sort:byte;


implementation

end.