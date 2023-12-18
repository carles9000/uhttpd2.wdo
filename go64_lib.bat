@echo off

rem ----------------------
rem Bat to compile wdo lib
rem ----------------------

call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64

c:\harbour\bin\hbmk2 wdo_lib.hbp -comp=msvc64

IF ERRORLEVEL 1 GOTO COMPILEERROR

@echo ------------------------
@echo WDO for UT was created !
@echo ------------------------

rem copy wdo.lib c:\uhttpd2.tweb\sample.app\wdo-dbf\lib\wdo\wdo.lib

GOTO EXIT

:COMPILEERROR

echo *** Error ***

:EXIT

pause