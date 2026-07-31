@echo off
cd ..\csv2lua\
if exist LastModifyList.txt (del LastModifyList.txt)
if exist LastModifyList_cn.txt (del LastModifyList_cn.txt)
rem python csv2lua_dev.py
csv2src.exe --input=../../config/game --output=./config

cd ..\checkCsv\
xcopy ..\csv2lua\config\*.* .\config\ /e /y

echo begin excute lua code
lua.exe choose.lua
python main.py
@echo check log.txt
checkCsvReport.html
pause