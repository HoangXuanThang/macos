#-*- coding=utf-8 -*-

import os
import sys
import math
import ctypes
import datetime

JENKINS_RUN = bool(os.environ.get('JENKINS_RUN', False) in ('True', 'true', '1', 'on'))

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

BLANKBAR = " "*128 + "\r"
PROGRESSBAR = None
WCOUNT = 0

def _set_win_color(color, handle=None):
	handle = handle if handle else std_out_handle
	return ctypes.windll.kernel32.SetConsoleTextAttribute(handle, color)

def _reset_win_color():
	_set_win_color(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE)

def _print(s, color=None):
	global PROGRESSBAR
	endl = "\n"
	if PROGRESSBAR:
		endl = " "*max(0, len(PROGRESSBAR)-len(s)) + "\n"

	if color and sys.stdout.isatty() and sys.platform != 'win32':
		sys.stdout.write(color + s + RESET)
		sys.stdout.write(endl)
	elif color and sys.platform == 'win32':
		if color == RED:
			_set_win_color(FOREGROUND_RED | FOREGROUND_INTENSITY)
		elif color == GREEN:
			_set_win_color(FOREGROUND_GREEN | FOREGROUND_INTENSITY)
		elif color == YELLOW:
			_set_win_color(FOREGROUND_YELLOW | FOREGROUND_INTENSITY)
		elif color == MAGENTA:
			_set_win_color(FOREGROUND_PINK | FOREGROUND_INTENSITY)
		try:
			s = s.decode('utf8').encode('gbk')
		except:
			pass
		finally:
			sys.stdout.write(s)
			sys.stdout.write(endl)
		_reset_win_color()
	else:
		sys.stdout.write(s)
		sys.stdout.write(endl)
	if PROGRESSBAR:
		sys.stdout.write(PROGRESSBAR)

def _log(s):
	global LOGFILE
	global WCOUNT
	if LOGFILE:
		LOGFILE.write(s)
		LOGFILE.write('\n')
		WCOUNT += 1
		if WCOUNT % 100 == 0:
			LOGFILE.flush()

def init(debug=True, filename=None):
	global NODEBUG
	global LOGFILE
	global WCOUNT

	NODEBUG = not debug
	if filename:
		LOGFILE = open(filename, 'wb')
	WCOUNT = 0
	_log(str(datetime.datetime.now()))

def debug(*args):
	if NODEBUG:
		return
	s = ' '.join([str(i) for i in args])
	_print(s, MAGENTA)
	_log(s)

def info(*args):
	s = ' '.join([str(i) for i in args])
	_print(s, GREEN)
	_log(s)

def warning(*args):
	s = ' '.join([str(i) for i in args])
	_print(s, YELLOW)
	_log(s)

def error(*args):
	s = ' '.join([str(i) for i in args])
	_print(s, RED)
	_log(s)

def hide_progress():
	global PROGRESSBAR
	if PROGRESSBAR:
		sys.stdout.write(BLANKBAR)
	PROGRESSBAR = None

def progress(percent=None, cur=None, max=None, title=''):
	global PROGRESSBAR
	if JENKINS_RUN:
		PROGRESSBAR = None
		return

	if cur is not None and max is not None:
		percent = 1.0 * cur / max
	n = 32
	pg = int(math.ceil(percent*n))
	bar = '#'*(pg) + '-'*(n-pg)
	s = ''
	if cur is not None and max is not None:
		curl = len(str(max))
		s = ("%s %5.2f%% (%{curl}d of %d) |%s|\r".format(curl=curl)) % (title, percent*100, cur, max, bar)
	else:
		s = "%s %5.2f%% |%s|\r" % (title, percent*100, bar)
	PROGRESSBAR = s
	sys.stdout.write(s)
