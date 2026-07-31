# -*- coding: utf-8 -*-
import os
import sys
import shutil
from cx_Freeze import setup, Executable

PYTHON_INSTALL_DIR = os.path.dirname(os.path.dirname(os.__file__))
os.environ['TCL_LIBRARY'] = os.path.join(PYTHON_INSTALL_DIR, 'tcl', 'tcl8')
os.environ['TK_LIBRARY'] = os.path.join(PYTHON_INSTALL_DIR, 'tcl', 'tk8.5')

# GUI applications require a different base on Windows (the default is for a
# console application).
base = None
# if sys.platform == "win32":
# 	base = "Win32GUI"

# Dependencies are automatically detected, but it might need fine tuning.
build_exe_options = {
	"packages": ["Tkinter"],
	"includes": [],
	"zip_include_packages": [
		"os",
		"sys",
		"json",
		"encodings",
		"logging",
		"winreg",
		"ctypes",
		"future",
		"importlib",
		"PIL",
		"windnd",
	],
	"excludes": [
		"PyQt5",
		"email",
		"unittest",
		"distutils",
		"setuptools",
		"cffi",
		"xml",
		"pycparser",
	],
	"include_files": [],
	"bin_includes": [],
	"include_msvcr": True,
}

#
executables = [
	Executable("mover.py", base=base, targetName="Mover.exe")
]

try:
	shutil.rmtree("./build")
except:
	pass

setup(
	name = "Mover",
	version = "1",
	description = u"UI切图移动定位工具",
	author = "HangZhou TianJi Information Technology Inc.",
	options = {"build_exe": build_exe_options},
	executables = executables,
)
