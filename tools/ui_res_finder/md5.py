#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import json
import argparse
import hashlib
import platform
import datetime
import functools
from collections import deque


import tjlog

LOG_FILE = "finder_%s.log"
CACHE_MD5_FILE = "file_infos.txt"


def utf2local(s):
	if platform.system() == 'Windows':
		return s.decode('utf8').encode('gbk')
	return s

def listFiles(rootDir):
	list_dirs = os.walk(rootDir)
	list_ret = []
	for root, dirs, files in list_dirs:
		for f in files:
			if f.find('.svn') >= 0:
				continue
			list_ret.append(os.path.join(root, f))
	return list_ret

def checkFile(filePath):
	stat = os.stat(filePath)
	with open(filePath, "rb") as fp:
		data = fp.read()
	m = hashlib.md5()
	m.update(data)
	md5 = m.hexdigest()
	return {
		'size': stat.st_size,
		'md5': md5,
	}

def makeSrcCache(srcPath, cacheFile=True):
	cache, newCache = {}, {}
	path = os.path.join(srcPath, CACHE_MD5_FILE)
	if cacheFile and os.path.exists(path):
		try:
			with open(path, "rb") as fp:
				cache = json.load(fp)
		except:
			pass
		os.remove(path)

	files = listFiles(srcPath)
	for file in files:
		relPath = os.path.relpath(file, srcPath).decode('gbk')
		stat = os.stat(file)
		info = cache.get(relPath, None)
		if info:
			if info['size'] != stat.st_size:
				info = checkFile(file)
				if cacheFile:
					tjlog.debug(u"src更新:", relPath, info)
		else:
			info = checkFile(file)
			if cacheFile:
				tjlog.debug(u"src新增:", relPath, info)
		newCache[relPath] = info

	if cacheFile:
		removes = set(cache.keys()) - set(newCache.keys())
		for key in removes:
			tjlog.debug(u"src删除:", key)

		with open(path, "wb") as fp:
			json.dump(newCache, fp)
		tjlog.info(u"src cache已刷新")
	return newCache

def sameWithMD5(cache, cache2):
	md5s = {v['md5'] : k for k, v in cache.iteritems()}
	md5s2 = {v['md5'] : k for k, v in cache2.iteritems()}

	same = set(md5s.keys()) & set(md5s2.keys())
	for md5 in same:
		tjlog.info(u"same md5:", md5s[md5], md5s2[md5])

	tjlog.info(u"res size:", len(md5s))
	tjlog.info(u"res2 size:", len(md5s2))
	tjlog.info(u"same size:", len(same), 1.0*len(same)/len(md5s))


def main():
	parser = argparse.ArgumentParser(description=u'MD5检查工具')
	parser.add_argument('--src', default='./res', help=u'res目录')
	parser.add_argument('--cmp_src', help=u'res2目录')
	args = parser.parse_args()

	srcPath = os.path.abspath(args.src)
	cmpSrcPath = os.path.abspath(args.cmp_src)

	tjlog.info(u"src存放目录", srcPath.decode('gbk'))
	if not os.path.exists(srcPath):
		raise Exception("not exist " + srcPath)

	cache = makeSrcCache(srcPath)
	tjlog.info("-"*30)
	if cmpSrcPath:
		cache2 = makeSrcCache(cmpSrcPath)
		sameWithMD5(cache, cache2)

	tjlog.debug(u"log文件:", logFile)
	raw_input(utf2local("按任意键退出"))


if __name__ == '__main__':
	now = datetime.datetime.now()
	logFile = LOG_FILE % now.strftime("%y%m%d_%H%M%S")
	tjlog.init(True, logFile)
	main()
