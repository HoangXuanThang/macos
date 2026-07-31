@echo off

REM cd ../LuaGameFramework




cd %~dp0


REM python remove_bom.py

xcopy /Y .\config.json .\simulator\win32\
start ./simulator/win32/MyLuaGame.exe -workdir ./ -writable-path ./simulator/win32 -resolution 1280x720 -console enable -write-debug-log debug.log

REM cd ..\..\..\tools\battletest\platform
REM backend.exe