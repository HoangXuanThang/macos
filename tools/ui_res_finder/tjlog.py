#-*- coding=utf-8 -*-

import sys
import ctypes

NODEBUG = False
LOGFILE = None

# TODO maybe the right way to do this is to use something like colorama?
RED = '\033[31m'
GREEN = '\033[32m'
YELLOW = '\033[33m'
MAGENTA = '\033[35m'
RESET = '\033[0m'

''''' See http://msdn.microsoft.com/library/default.asp?url=/library/en-us/winprog/winprog/windows_api_reference.asp
for information on Windows APIs.'''
STD_INPUT_HANDLE = -10
STD_OUTPUT_HANDLE= -11
STD_ERROR_HANDLE = -12
if sys.platform == 'win32':
	std_out_handle = ctypes.windll.kernel32.GetStdHandle(STD_OUTPUT_HANDLE)

FOREGROUND_BLACK = 0x0
FOREGROUND_BLUE = 0x01 # text color contains blue.
FOREGROUND_GREEN= 0x02 # text color contains green.
FOREGROUND_RED = 0x04 # text color contains red.
FOREGROUND_PINK = 0x05
FOREGROUND_YELLOW = 0x06
FOREGROUND_WHITE = 0x07
FOREGROUND_INTENSITY = 0x08 # text color is intensified.

BACKGROUND_BLUE = 0x10 # background color contains blue.
BACKGROUND_GREEN= 0x20 # background color contains green.
BACKGROUND_RED = 0x40 # background color contains red.
BACKGROUND_INTENSITY = 0x80 # background color is intensified.

def _set_win_color(color, handle=None):
	handle = handle if handle else std_out_handle
	return ctypes.windll.kernel32.SetConsoleTextAttribute(handle, color)

def _reset_win_color():
	_set_win_color(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE)

def _print(s, color=None):
	if color and sys.stdout.isatty() and sys.platform != 'win32':
		print(color + s + RESET)
	elif color and sys.platform == 'win32':
		if color == RED:
			_set_win_color(FOREGROUND_RED | FOREGROUND_INTENSITY)
		elif color == GREEN:
			_set_win_color(FOREGROUND_GREEN | FOREGROUND_INTENSITY)
		elif color == YELLOW:
			_set_win_color(FOREGROUND_YELLOW | FOREGROUND_INTENSITY)
		elif color == MAGENTA:
			_set_win_color(FOREGROUND_PINK | FOREGROUND_INTENSITY)
		print(s)
		_reset_win_color()
	else:
		print(s)

def init(debug=True, filename=None):
	global NODEBUG
	global LOGFILE

	NODEBUG = not debug
	LOGFILE = open(filename, 'wb')

def debug(*args):
	if NODEBUG:
		return
	s = ' '.join([unicode(i) if not isinstance(i, (str, unicode)) else i for i in args])
	_print(s, MAGENTA)
	if LOGFILE:
		if isinstance(s, unicode):
			s = s.encode('utf8')
		LOGFILE.write(s)
		LOGFILE.write('\n')

def info(*args):
	s = ' '.join([unicode(i) if not isinstance(i, (str, unicode)) else i for i in args])
	_print(s, GREEN)
	if LOGFILE:
		if isinstance(s, unicode):
			s = s.encode('utf8')
		LOGFILE.write(s)
		LOGFILE.write('\n')

def warning(*args):
	s = ' '.join([unicode(i) if not isinstance(i, (str, unicode)) else i for i in args])
	_print(s, YELLOW)
	if LOGFILE:
		if isinstance(s, unicode):
			s = s.encode('utf8')
		LOGFILE.write(s)
		LOGFILE.write('\n')

def error(*args):
	s = ' '.join([unicode(i) if not isinstance(i, (str, unicode)) else i for i in args])
	_print(s, RED)
	if LOGFILE:
		if isinstance(s, unicode):
			s = s.encode('utf8')
		LOGFILE.write(s)
		LOGFILE.write('\n')
