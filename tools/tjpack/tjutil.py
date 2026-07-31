#-*- coding=utf-8 -*-

import os
import re
import zipfile
import hashlib
import platform
import subprocess

import tjlog

# print __file__, os.getcwd()
filepath = os.path.dirname(__file__)

luajit_exe = os.path.join(filepath, 'bin', 'win', 'luajit')
luajit64_exe = os.path.join(filepath, 'bin', 'win64', 'luajit')
xxtea_exe = os.path.join(filepath, 'bin', 'win', 'xxtea_dll')
pngquant_exe = os.path.join(filepath, 'bin', 'win', 'pngquant') # 2.0
texpacker_exe = 'TexturePacker'

# texpacker_exe = r'"D:\Program Files (x86)\CodeAndWeb\TexturePacker\bin\TexturePacker.exe"'

if platform.system() == 'Darwin':
	luajit_exe = os.path.join(filepath, 'bin', 'mac', 'luajit')
	luajit64_exe = os.path.join(filepath, 'bin', 'mac64', 'luajit')
	xxtea_exe = os.path.join(filepath, 'bin', 'mac', 'xxtea_dll')
	pngquant_exe = os.path.join(filepath, 'bin', 'mac', 'pngquant')
	pngquant_exe = ' '.join([pngquant_exe, '--strip']) # 2.12
	texpacker_exe = '/Applications/TexturePacker.app/Contents/MacOS/TexturePacker'

luajit_exe = os.path.abspath(luajit_exe)
xxtea_exe = os.path.abspath(xxtea_exe)
pngquant_exe = os.path.abspath(pngquant_exe)

print luajit_exe
print xxtea_exe
print pngquant_exe
print texpacker_exe

class cd(object):
	def __init__(self, path):
		self.path = path
		self.orginpath = os.getcwd()

	def __enter__(self):
		tjlog.info('cd enter', self.orginpath, '->', self.path)
		os.chdir(self.path)

	def __exit__(self, exc_type, exc_value, exc_tb):
		tjlog.info('cd exit', self.orginpath, '<-', self.path)
		os.chdir(self.orginpath)

def utf2local(s):
	if platform.system() == 'Windows':
		return s.decode('utf8').encode('gbk')
	return s

def abspath(path):
	return os.path.abspath(os.path.join(os.getcwd(), path)).replace('\\', '/')

def readPlist(path, key):
	try:
		file = open(path)
		text = file.read()
		value = re.findall('<key>' + key + '</key>\s*?<string>(?P<ver>[0-9.]+)</string>',text)[0]
		file.close()
		tjlog.info('\n*** %s 读取 %s 为: %s' % (os.path.abspath(path), key, value))
		return value
	except Exception, e:
		tjlog.error('readPlist', path, key, e)

def readVersion(path):
	return readPlist(path, 'app_version')

def cnInput(str):
	return raw_input(unicode(str,'utf-8').encode('gbk'))

def writePlist(path, key, val=None):
	try:
		file = open(path)
		text = file.read()
		file.close()
		pattern = '<key>' + key + '</key>\s*?<string>(?P<result>[a-z0-9.]+)</string>'
		match = re.search(pattern, text)
		if match is None:
			raise Exception('no such key')
		result = match.group('result')
		if val is None:
			val = cnInput('\n修改 %s 中的 "%s" (%s):' % (path, key, result))
		if val != '':
			newKV = match.group().replace(result, val)
			newText = text.replace(match.group(), newKV)
			file = open(path, 'wb')
			file.write(newText)
			file.close()
			tjlog.info('\n*** 当前 %s 为: %s' % (key, val))
			return val
		tjlog.info('\n*** 当前 %s 为: %s' % (key, result))
		return result
	except Exception, e:
		tjlog.error('writePlist', path, key, e)


def listFiles(rootDir, ext=None, ignoreExt=None):
	list_dirs = os.walk(rootDir)
	list_ret = []
	for root, dirs, files in list_dirs:
		for f in files:
			flag = False
			if ext is None or f.endswith(ext):
				flag = True
			if ignoreExt and f.endswith(ignoreExt):
				flag = False
			if flag:
				list_ret.append(os.path.join(root, f))
	return list_ret

def readFile(path):
	try:
		with open(path, 'rb') as fp:
			return fp.read()
	except Exception, e:
		tjlog.error('readFile', path, e)

# 把整个文件夹内的文件打包
def zipFiles(zipFileName, filePairList):
	f = zipfile.ZipFile(zipFileName, 'w', zipfile.ZIP_DEFLATED)
	for filename in filePairList:
		f.write(filename[0], filename[1])
	f.close()

def getMD5(filepath=None, data=None):
	if filepath:
		with open(filepath, 'rb') as fp:
			m = hashlib.md5()
			m.update(fp.read())
			return m.hexdigest()
	if data:
		m = hashlib.md5()
		m.update(data)
		return m.hexdigest()

def pngSlim(path):
	cmd = ' '.join([pngquant_exe, '--force', path])
	ret = subprocess.call(cmd, shell=True)
	newPath = path[:-4] + '-fs8.png'
	if not os.path.exists(newPath):
		newPath = path[:-4] + '-or8.png'
	if not os.path.exists(newPath):
		tjlog.error('pngSlim %s no output' % path)
		raise Exception("png slim err")
	return newPath