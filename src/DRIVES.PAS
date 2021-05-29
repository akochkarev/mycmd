  {----------------------------------------------------------------------}
                                 Unit  Drives;
  {----------------------------------------------------------------------}


  {----------------------------------------------------------------------}
                                   Interface
  {----------------------------------------------------------------------}

Uses
  DOS;

Function DOSDrives : String;
{ Функция возвращает строку символов -
имен доступных для DOS логических дисков }

Function DiskNum (Drive : Char) : Byte;
{ Функция возвращает номер лог. диска:
'A'-1,'B'-2,'C'-3 и тд }


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
