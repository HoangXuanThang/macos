#-*- coding=utf-8 -*-

import os
import sys
import time
import json
import random
import pprint
import shutil
import hashlib
import argparse
import subprocess

import tjz
import tjlog
import tjutil
import tjcache

def listFiles(rootDir):
	list_dirs = os.walk(rootDir)
	list_ret = {}
	for root, dirs, files in list_dirs:
		for f in files:
			pf = os.path.join(root, f)
			s = os.stat(pf)
			pf = pf.replace('\\', '/')
			# if pf[-8:] == '.pvr.ccz':
			# 	pf = pf[:-8] + '.png'
			list_ret[pf] = int(s.st_size)
	return list_ret

def main():
	parser = argparse.ArgumentParser(prog='pack_tool', description='tj pack tool')
	parser.add_argument('--encode', dest='encode', action="store_true", default=True, help=tjutil.utf2local('加密'))
	parser.add_argument('--decode', dest='decode', action="store_true", default=False, help=tjutil.utf2local('解密'))
	parser.add_argument('--stdout', dest='stdout', action="store_true", default=False, help=tjutil.utf2local('输出到stdout'))
	parser.add_argument('--outpath', dest='outpath', type=str, help=tjutil.utf2local('输出到outpath文件'))
	parser.add_argument('paths', type=str, nargs='+', help=tjutil.utf2local('需要处理的文件路径'))

	args = parser.parse_args(sys.argv[1:])
	if args.outpath:
		args.stdout = False

	if args.decode:
		args.encode = False

	print args

	paths = args.paths
	rootPath = args.paths[0]
	if len(paths) == 1 and os.path.isdir(rootPath):
		paths = listFiles(rootPath)

	repoMappingPath = None
	for path in paths:
		if path.find('repo.mapping') >= 0:
			repoMappingPath = path

		# input file -> data
		with open(path, 'rb') as fp:
			data = fp.read()
		isCompressed = tjz.isCompressed(data)
		print path, isCompressed
		oldlen = len(data)

		if args.decode and isCompressed:
			outputPath = args.outpath if args.outpath else path
			data = tjz.decode(data, tjz.XXTEA_KEY)
			if args.stdout:
				print data
				newlen = len(data)
				outputPath = 'stdout'
			else:
				with open(outputPath, 'wb') as fp:
					fp.write(data)
				newlen = os.stat(outputPath).st_size
			print path, 'decode', oldlen, newlen, outputPath

		elif args.encode and not isCompressed:
			# outputPath = args.outpath if args.outpath else 'encode.tmp'
			outputPath = path + ""
			tjz.encodeAndCompressToFile(data, tjz.XXTEA_KEY, outputPath, useLZ4=True)
			if args.stdout:
				with open(outputPath, 'rb') as fp:
					data = fp.read()
				print data
			else:
				newlen = os.stat(outputPath).st_size
				print path, 'encodeAndCompressToFile', oldlen, newlen, outputPath

	if repoMappingPath:
		if not os.path.isdir(os.path.join(rootPath, "repository")):
			repoMappingPath = None
	if repoMappingPath and args.decode:
		newDir = os.path.join(rootPath, "_norepo_")
		if os.path.exists(newDir):
			shutil.rmtree(newDir)
		print 'repoMappingPath=', repoMappingPath
		with open(repoMappingPath, 'rb') as fp:
			mapp = json.load(fp)
		for path, d in mapp.iteritems():
			path = os.path.join(newDir, path)
			pathMap = os.path.join(rootPath, d['mapping'])
			dirPath = os.path.dirname(path)
			if not os.path.exists(dirPath):
				os.makedirs(dirPath)
			# print os.path.dirname(path)
			print pathMap, '->', path
			try:
				shutil.copyfile(pathMap, path)
			except:
				import traceback
				traceback.print_exc()


if __name__ == '__main__':
	main()