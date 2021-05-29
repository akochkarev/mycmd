  {----------------------------------------------------------------------}
                                 Unit  Drives;
  {----------------------------------------------------------------------}


  {----------------------------------------------------------------------}
                                   Interface
  {----------------------------------------------------------------------}

Uses
  DOS;

Function DOSDrives : String;
{ �㭪�� �����頥� ��ப� ᨬ����� -
���� ����㯭�� ��� DOS �����᪨� ��᪮� }

Function DiskNum (Drive : Char) : Byte;
{ �㭪�� �����頥� ����� ���. ��᪠:
'A'-1,'B'-2,'C'-3 � � }


  {----------------------------------------------------------------------}
                                Implementation
  {----------------------------------------------------------------------}

Function DOSDrives : String;
Var
  R      : Registers;
  Drives : String;
  I      : Byte;
  Ch     : Char;
Begin
  Ch := Pred ('A');
  Drives := '';
  For I := 1 to 26 do
    Begin
      Ch := Succ (Ch);
      R.AH := $44;
      R.AL := 8;
      R.BL := I;
      MsDOS (R);
      If R.AX <= 1 then Drives := Drives + Ch
    End;
  DOSDrives := Drives
End;

Function DiskNum (Drive : Char) : Byte;
Begin
  Drive := UpCase (Drive);
  DiskNum := Ord (Drive) - Ord ('A') + 1
End;

End.
