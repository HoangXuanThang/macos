#-*- coding=utf-8 -*-

import os
import shutil
import binascii
import subprocess

import tjutil


LUAFILENAME = 'fixer.lua'

def main():
	cwd = os.getcwd()
	rnd = os.urandom(8)
	name = binascii.hexlify(rnd)

	name = "70ba7e14140b0097"
	print name

	luajitdir = os.path.dirname(tjutil.luajit_exe)
	if os.path.exists(LUAFILENAME):
		os.remove(LUAFILENAME)
	shutil.copy(os.path.join('mod_fixer', LUAFILENAME), os.path.join(luajitdir, LUAFILENAME))

	os.chdir(luajitdir)

	# luajit字节码
	cmd = [tjutil.luajit_exe, '-b', 'fixer.lua', '-t', 'raw', '%s.jpg' % name]
	cmd = ' '.join(cmd)
	print cmd
	ret = subprocess.call(cmd, shell=True)
	if ret == 0:
		shutil.copy('%s.jpg' % name, os.path.join(cwd, 'mod_fixer'))
	else:
		raise Exception(ret)

	# 现在编译的字节码32位和64位是一样的, 不清楚是不是luajit raw type的缘故
	cmd = [tjutil.luajit64_exe, '-b', 'fixer.lua', '-t', 'raw', '%s64.jpg' % name]
	cmd = ' '.join(cmd)
	#print cmd
	#ret = subprocess.call(cmd, shell=True)
	#if ret == 0:
	#	shutil.copy('%s64.jpg' % name, os.path.join(cwd, 'mod_fixer'))
	#else:
	#	raise Exception(ret)

if __name__ == '__main__':
	main()