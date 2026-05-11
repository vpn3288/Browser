@echo off
echo ?????????...

call "%~dp0Launch_Brave.bat"
timeout /t 2 /nobreak >nul
call "%~dp0Launch_Zen Browser.bat"
timeout /t 2 /nobreak >nul
call "%~dp0Launch_Edge.bat"
timeout /t 2 /nobreak >nul
call "%~dp0Launch_Firefox.bat"
timeout /t 2 /nobreak >nul
call "%~dp0Launch_LibreWolf.bat"
timeout /t 2 /nobreak >nul
call "%~dp0Launch_Chromium.bat"
timeout /t 2 /nobreak >nul
call "%~dp0Launch_Chrome.bat"
timeout /t 2 /nobreak >nul
call "%~dp0Launch_Vivaldi.bat"
timeout /t 2 /nobreak >nul
call "%~dp0Launch_Opera.bat"
timeout /t 2 /nobreak >nul

echo ????????
pause
