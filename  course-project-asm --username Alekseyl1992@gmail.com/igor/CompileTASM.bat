@echo off
cls
echo enter filename:
set /p filename=
echo -----------compiling...-----------
tasm.exe /L /zi %filename%

echo -----------linking...-----------

FOR %%i IN ("*.obj") DO Set FileNameOBJ=%%i
TLINK.EXE /v /x /t /l %FileNameOBJ%

choice /M "run?" /C 01
if %ERRORLEVEL% == 0 goto end
if %ERRORLEVEL% == 1 goto run



:run
FOR %%i IN ("*.com") DO Set FileNameCOM=%%i
%FileNameCOM%
goto end

:end
pause > nul
