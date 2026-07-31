@echo off
if exist LastModifyList.txt (del LastModifyList.txt)
REM python csv2lua_dev.py
python csv2py.py en
REM csv.py
pause