xcopy /Y luacov.stats.out .\src
xcopy /Y luacovbin.lua .\src
cd scripts

lua luacovbin.lua

move /Y luacov.report.out ..\
del /Q luacovbin.lua luacov.stats.out
pause