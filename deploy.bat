@echo off
setlocal
set QT_DIR=D:\Qt\6.8.3\msvc2022_64
set EXE=%~dp0build\Debug\bin\WeatherApp.exe
if not exist "%EXE%" set EXE=%~dp0build\Desktop_Qt_6_8_3_MSVC2022_64bit-Debug\bin\WeatherApp.exe
if not exist "%EXE%" (
    echo WeatherApp.exe not found. Build the project first.
    exit /b 1
)
"%QT_DIR%\bin\windeployqt.exe" --debug --qmldir "%~dp0qml" "%EXE%"
echo Deploy finished: %EXE%
pause