@echo off
if exist LastModifyList.txt (del LastModifyList.txt)
python csv2lua_dev.py th
python csv2py.py th
pause