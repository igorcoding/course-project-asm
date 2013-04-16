@echo off
cls
echo enter filename:
set /p filename=
echo -----------compiling...-----------
tasm.exe /L /zi %filename%

echo -----------linking...-----------

FOR %%i IN ("*.obj") DO Set FileNameOBJ=%%i
TLINK.EXE /v /x /t /l %FileNameOBJ%

:end
pause > nul
