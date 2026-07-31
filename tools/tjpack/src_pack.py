#-*- coding=utf-8 -*-
# 代码加密
# 递归扫描SRC_PATH目录，读取全部lua文件
# 先进行luajit字节码（现在没有好的反编译破解），再使用XXTEA加密（使用xxtea_dll，该程序由cocosdx导出）
# 去掉.lua后缀后，将分隔符替换为.，扁平化文件路径
# 如model\scene.lua -> model.scene，lua中require调用model.scene即可

import os
import os.path
import binascii
import base64
import zipfile
import subprocess
import shutil
import md5
import re
import sys
import struct
import argparse
import ctypes
import json

import tjz
import tjlog
import tjutil
import platform


#####################################
# 全局配置
PACKINPUTFLAG = 'y'
OUTPUT_PATH = './src_pack'
VERSION_PATH = None #'./version.plist'
INPLACE = False
SRC_PATH = '../../MyLuaGame'
CODE_DIRS = ('src', 'cocos', 'updater')

if PACKINPUTFLAG == 'n':  #是否是更新包
	SRC_PATH1 = './updatePack'

SRC_EXT = '.lua'

# for raw size and md5
RAW_FILE_INFOS = {}

def compileSources(rootDir):
	XXTEA_KEY = tjz.XXTEA_KEY
	rootDir = os.path.abspath(rootDir)

	tjlog.info('begin compile', rootDir)
	tjlog.info('XXTEA_KEY', XXTEA_KEY)

	XXTEA_KEY = binascii.unhexlify(XXTEA_KEY)

	dirname = os.path.basename(rootDir)
	outputDir = os.path.join(OUTPUT_PATH, dirname)
	os.makedirs(outputDir)

	fileList = tjutil.listFiles(rootDir, SRC_EXT)
	nFiles = len(fileList)
	zipFileList = []
	for iFile, filePath in enumerate(fileList):
		tjlog.progress(cur=iFile, max=nFiles, title='src_pack')
		outputFilePath = os.path.relpath(filePath, rootDir)
		# tmpFilePath = os.path.join(outputDir, outputFilePath)
		# zip中去掉后缀
		outputFilePath = outputFilePath[:-len(SRC_EXT)].replace('\\', '.').replace('/', '.')
		relPath = os.path.join(dirname, outputFilePath).replace('\\', '/')
		outputFilePath = os.path.join(outputDir, outputFilePath)

		# tmpFilePath = os.path.abspath(tmpFilePath)
		# if not os.path.exists(tmpFilePath):
		# 	os.makedirs(tmpFilePath)

		RAW_FILE_INFOS[relPath] = {
			'name': relPath,
			'md5': tjutil.getMD5(filePath),
			'size': os.path.getsize(filePath),
		}

		try:
			# luajit字节码
			# 靠XXTEA外部加密，不做字节码省去x86和x64版本维护，另外lua异常方便打印行号
			if filePath.find('\\src\\config\\') != -1 and filePath.find('\\x64\\') != -1:
                                cmd = [tjutil.luajit64_exe, '-b', filePath, filePath]
                                cmd = ' '.join(cmd)
                                ret = subprocess.call(cmd, shell=True)
                                tjlog.debug(filePath, 'luajit 64 ok') 
                        elif filePath.find('\\src\\config\\') != -1:
                                cmd = [tjutil.luajit_exe, '-b', filePath, filePath]
                                cmd = ' '.join(cmd)
                                ret = subprocess.call(cmd, shell=True)
                                tjlog.debug(filePath, 'luajit ok')


			if platform.system() == 'Darwin' and filePath.find('/src/config/') != -1 and filePath.find('/x64/') != -1:
                                cmd = [tjutil.luajit64_exe, '-b', filePath, filePath]
                                cmd = ' '.join(cmd)
                                ret = subprocess.call(cmd, shell=True)
                                tjlog.debug(filePath, 'luajit 64 ok') 
                        elif filePath.find('/src/config/') != -1:
                                cmd = [tjutil.luajit_exe, '-b', filePath, filePath]
                                cmd = ' '.join(cmd)
                                ret = subprocess.call(cmd, shell=True)
                                tjlog.debug(filePath, 'luajit ok')






			# lz4
			# tj!
			with open(filePath, 'rb') as fp:
				data = fp.read()

			tjz.encodeAndCompressToFile(data, XXTEA_KEY, outputFilePath, pwdIsHex=False)
			filesize1 = os.stat(outputFilePath).st_size

			# xxtea
			# cmd = [tjutil.xxtea_exe, '-e', XXTEA_KEY, '-s', tjz.XXTEA_SIGN, outputFilePath, outputFilePath]
			# cmd = ' '.join(cmd)
			# ret = subprocess.call(cmd, shell=True)

			filesize2 = os.stat(outputFilePath).st_size
		except Exception, e:
			tjlog.error(filePath, 'compile error')
			raise
		tjlog.debug(filePath, 'compile ok')
	tjlog.hide_progress()
	return outputDir


def main():
	global PACKINPUTFLAG
	global VERSION_PATH
	global SRC_PATH
	global INPLACE

	parser = argparse.ArgumentParser(prog='src_pack', description='lua code packer')
	parser.add_argument('flag', help=tjutil.utf2local('完整包y，更新包n'))
	parser.add_argument('-s', '--src-path', dest='src_path', help=tjutil.utf2local('lua代码路径'))
	parser.add_argument('--onebyone', dest='onebyone', action="store_true", default=False, help=tjutil.utf2local('单目录'))
	parser.add_argument('--inplace', dest='inplace', action="store_true", default=False, help=tjutil.utf2local('在src目录里直接操作，不进行复制'))

	# parser.add_argument('-v', '--version', dest='version', help=tjutil.utf2local('version.plist里的app_version'))
	# parser.add_argument('--version-path', dest='version_path', help=tjutil.utf2local('version.plist路径'))
	# parser.add_argument('--package-key', dest='pack_key', help=tjutil.utf2local('母包lua加密密钥'))

	args = parser.parse_args(sys.argv[1:])

	tjlog.init(True, 'src_pack.log')
	tjlog.debug(args)

	PACKINPUTFLAG = args.flag
	if args.src_path:
		SRC_PATH = args.src_path
	INPLACE = args.inplace

	tjlog.info('PACKINPUTFLAG:', PACKINPUTFLAG)
	tjlog.info('SRC_PATH:', SRC_PATH)
	tjlog.info('ABS_SRC_PATH:', os.path.abspath(SRC_PATH))
	tjlog.info('INPLACE:', INPLACE)
	tjlog.info('ONEBYONE:', args.onebyone)

	if os.path.exists('src_mapping.json'):
		os.remove('src_mapping.json')

	if os.path.exists(OUTPUT_PATH):
		shutil.rmtree(OUTPUT_PATH)
	os.makedirs(OUTPUT_PATH)

	if args.onebyone:
		srcPaths = [SRC_PATH]
	else:
		srcPaths = [os.path.join(SRC_PATH, s) for s in CODE_DIRS]
	outputPaths = []
	for path in srcPaths:
		outputDir = compileSources(path)
		outputPaths.append(outputDir)

	if INPLACE:
		for i, path in enumerate(srcPaths):
			if os.path.exists(path):
				shutil.rmtree(path)
				shutil.move(outputPaths[i], path)
		shutil.rmtree(OUTPUT_PATH)

	with open('src_mapping.json', 'wb') as fp:
		fp.write(json.dumps(RAW_FILE_INFOS))
	tjlog.info('src_mapping.json gen ok')

if __name__ == '__main__':
	main()



###############################################
# DLL形式加载，会遇到返回数据\0等恶心处理
# from ctypes import *
# xxteadll = CDLL('xxtea_dll.dll')
# leng = c_ulong()
# xxteadll.xxtea_encrypt.argtypes = [c_char_p, c_ulong, c_char_p, c_ulong, c_void_p]
# xxteadll.xxtea_encrypt.restype = c_char_p
# xxteadll.xxtea_free.argtypes = [c_char_p]
# a= xxteadll.xxtea_encrypt('1234567890',10,'key',3,pointer(leng))
# print repr(a),leng,repr(a[1])
# print type(a), len(a)
# xxteadll.xxtea_free(a)