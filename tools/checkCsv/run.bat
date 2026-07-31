@echo off
cd ..\csv2lua\
if exist LastModifyList.txt (del LastModifyList.txt)
if "%1" equ "" (
	python csv2lua_dev.py
) else (
	python csv2lua_dev.py "%1"
)

cd ..\checkCsv\
xcopy ..\csv2lua\config\*.* .\config\ /e /y

echo begin excute lua code
lua.exe choose.lua
python main.py
@echo check log.txt
pause