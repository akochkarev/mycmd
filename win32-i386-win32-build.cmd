fpc -va  OPT="-gl -Xs -WC" -Twin32 -Pi386 -FE.\bin\ .\src\mycmd.pas >i386-win32.log

xcopy /Y .\src\mycmd.ini .\bin >>i386-win32.log
xcopy /Y .\src\start.cmd .\bin >>i386-win32.log
xcopy /Y .\src\mycmd.hlp .\bin >>i386-win32.log

rem pause

