@echo off
if exist LastModifyList.txt (del LastModifyList.txt)
python csv2py.py
if "%1" equ "" (
	@echo "full package or update package? full package(y), update package(n)?(y/n)"
	python texture_pack.py > log_texture.txt
	log_texture.txt
	pause
) else (
	@echo "waiting for building texture (update package) ..."
	python texture_pack.py "%1"
)
