@echo off
chcp 65001
@where pip
if "%errorlevel%"=="0" (
	echo pip exist
) else (
	echo pip not install!!!
	start https://pypi.python.org/pypi/pip#downloads
	exit
)

@lua lua2txt.lua
@python copyText2excel.py

:NEXT1
echo "please check temp.xls and input 'y' or 'Y' to add json content"
set /p flag=

if /i %flag% NEQ y (goto NEXT1)

@python exportText.py
:NEXT2
echo "add content to temp.xls input 'y' or 'Y' to export lua file"
set /p flag1=
if /i %flag1% NEQ y (goto NEXT2)

@python csv2lua.py

echo "the end"

pause