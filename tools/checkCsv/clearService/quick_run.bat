@echo off
rem chcp 65001
@where pip
if "%errorlevel%"=="0" (
	echo pip exist
) else (
	echo pip not install!!!
	start https://pypi.python.org/pypi/pip#downloads
	exit
)

python clear.py -p "../../../config/game_dev/cross/service.csv"
pause