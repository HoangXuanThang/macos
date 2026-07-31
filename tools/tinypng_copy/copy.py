#-*- coding=utf-8 -*-

import os
import shutil

SRC_PATH = '../../client/game01/res/spine'
TINY_PATH = './tiny'

def listFiles(rootDir, ext='.png'): 
	list_dirs = os.walk(rootDir) 
	list_ret = []
	for root, dirs, files in list_dirs: 
		for f in files:
			pf = os.path.join(root, f)
			if not ext is None:
				if not f.endswith(ext):
					continue
			list_ret.append(pf)
	return list_ret

def findSameNameFiles(rootDir, filenames):
	ret = {f: [] for f in filenames}
	list_dirs = os.walk(rootDir) 
	list_ret = []
	for root, dirs, files in list_dirs: 
		for f in files:
			pf = os.path.join(root, f)
			if f in ret:
				ret[f].append(pf)
	return ret

def main():
	tinyfiles = listFiles(TINY_PATH)
	tinyfiles = [os.path.basename(x) for x in tinyfiles]

	srcmap = findSameNameFiles(SRC_PATH, tinyfiles)

	# print tinyfiles
	# print srcmap

	for filename, maps in srcmap.iteritems():
		if len(maps) == 0:
			continue
		elif len(maps) == 1:
			shutil.copyfile(os.path.join(TINY_PATH, filename), maps[0])
		else:
			print filename, ': existed many source!'
			print [os.path.relpath(f, SRC_PATH) for f in maps]

if __name__ == '__main__':
	main()