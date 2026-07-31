@echo off
if exist LastModifyList.txt (del LastModifyList.txt)
REM python csv2lua_dev.py
python csv2py.py
REM csv.py
pause