#-*- coding=utf-8 -*-
# 把png小图重新打包成atlas和pvr.ccz文件
#!/usr/bin/env python

import os
import os.path
import binascii
import base64
import subprocess
import shutil
import json
import sys
import argparse
from collections import defaultdict

sys.path.append('../tjpack')

import tjutil
import tjlog

PACK_FLAG = 'n'
ORIGINAL_PATH = '../../client/application/res/'
OUTPUT_PATH = './tp_tmp/output'
PNGQUANT = False
DEBUG_PNG = False

ALL_A4 = False
ALL_RGB565 = False
OPTCONFIG = {}

def noramlPath(s):
	return os.path.normpath(s.strip()).replace("\\", "/")

def getCsvProject(project):
	#######开A4 个别资源像素会多了1！ 但在游戏中也看不出来
	global OPTCONFIG, ALL_A4, ALL_RGB565
	if ALL_A4:
		return {'opt': 'RGBA4444'}
	if ALL_RGB565:
		return {'opt': 'RGB565'}

	if not OPTCONFIG:
		with open('optlist.csv', 'rb') as fp:
			for x in fp.readlines():
				xx = x.split(',')
				OPTCONFIG[noramlPath(xx[0])] = xx[1].strip()
		opts = defaultdict(int)
		for x in OPTCONFIG.values():
			opts[x] += 1
		print 'OPTCONFIG', len(OPTCONFIG)
		print opts
		OPTCONFIG[None] = None


	project = noramlPath(project)
	for pat, opt in OPTCONFIG.iteritems():
		if pat and project.find(pat) >= 0:
			return {'opt': opt}
	return {'opt': 'RGBA8888'}


def process(filepath, opt):
	path = filepath
	filepath = noramlPath(os.path.abspath(filepath))
	newfilepath = filepath.replace(".png", ".pvr.ccz")

	if PNGQUANT:
		if DEBUG_PNG:
			shutil.copy(filepath, filepath + ".bak.png")
		slimpath = tjutil.pngSlim(filepath)
		shutil.move(slimpath, filepath)
		if DEBUG_PNG:
			shutil.copy(filepath, slimpath)

	cmd = None
	if opt == 'RGBA8888':
		newfilepath = filepath
	else:
		packer = tjutil.texpacker_exe
		cmd = ' '.join([
			packer, filepath,
			"--data", OUTPUT_PATH + ".plist",
			"--sheet", newfilepath,
			"--max-size", "2048",
			"--size-constraints", "AnySize",
			"--premultiply-alpha",
			"--border-padding", "0",
			"--disable-rotation",
			"--trim-mode", "None",
			# "--content-protection", PWD,
			"--dither-fs-alpha",
			"--disable-auto-alias",
			"--opt", opt
		])

		try:
			flag = os.system(cmd)
			if flag != 0:
				tjlog.error('texture pack error', filepath)
		except Exception, e:
			tjlog.error('process exception', filepath)
			return None

	if os.path.exists(newfilepath):
		if cmd and DEBUG_PNG:
			cmd = cmd.replace(newfilepath, newfilepath + ".png")
			os.system(cmd)

	else:
		tjlog.error('no texture pack file output', newfilepath)
		return None
	return newfilepath

def run(rootDir, ext=None):
	print 'run in', rootDir, ext
	list_dirs = set()
	for root, dirs, files in os.walk(rootDir):
		for f in files:
			if ext and f.endswith(ext):
				list_dirs.add(root)
				break

	cnt1, cnt2= 0, 0
	for Dir in list_dirs:
		print 'step in dir', Dir
		for root, dirs, files in os.walk(Dir):
			for f in files:
				if f.endswith(ext):
					cnt1 += 1
					filepath = os.path.join(root, f)
					project = Dir + "/" + f[:-len(ext)]
					cfg = getCsvProject(project)
					oldsize = os.path.getsize(filepath)
					tjlog.info(cfg['opt'], filepath)
					# 现在没有content-protection
					newfilepath = process(filepath, cfg['opt'])
					if newfilepath:
						cnt2 += 1
						filepath = os.path.abspath(filepath)
						newfilepath = os.path.abspath(newfilepath)
						newsize = os.path.getsize(newfilepath)
						tjlog.info(os.path.basename(filepath), oldsize, '->', os.path.basename(newfilepath), newsize, "%.2f%%" % (100.0*newsize/oldsize))
						if filepath != newfilepath:
							os.remove(filepath)

	tjlog.info('run over', cnt1, cnt2)

def main():
	global PACK_FLAG, OUTPUT_PATH, ORIGINAL_PATH, PNGQUANT, ALL_A4, ALL_RGB565, DEBUG_PNG

	parser = argparse.ArgumentParser(prog='texture_pack', description='texture packer')
	parser.add_argument('-flag', dest='flag', default='n', help=tjutil.utf2local('完整包y，更新包n'))
	parser.add_argument('--pngquant', dest='pngquant', action="store_true", default=False, help=tjutil.utf2local('不使用pngquant压缩'))
	parser.add_argument('--alla4', dest='alla4', action="store_true", default=False, help=tjutil.utf2local('忽略a4list，全部进行A4'))
	parser.add_argument('--all565', dest='all565', action="store_true", default=False, help=tjutil.utf2local('忽略a4list，全部进行RGB565'))
	parser.add_argument('--debugpng', dest='debugpng', action="store_true", default=False, help=tjutil.utf2local('忽略a4list，全部进行A4'))

	args = parser.parse_args(sys.argv[1:])

	tjlog.init(True, 'texture_pack.log')
	tjlog.debug(args)

	PACK_FLAG = args.flag
	PNGQUANT = args.pngquant
	ALL_A4 = args.alla4
	ALL_RGB565 = args.all565
	DEBUG_PNG = args.debugpng
	if PACK_FLAG == 'n':  #是否是更新包
		#游戏里相关的json等复制到TexturePack/updatePack/
		ORIGINAL_PATH = './tp_tmp/res/'

	print 'PACK_FLAG', PACK_FLAG
	print 'OUTPUT_PATH', OUTPUT_PATH
	print 'ORIGINAL_PATH', ORIGINAL_PATH
	print 'PNGQUANT', PNGQUANT
	print 'ALL_A4', ALL_A4, 'ALL_RGB565', ALL_RGB565

	#先删除output下所有文件
	if not os.path.exists(OUTPUT_PATH):
		os.makedirs(OUTPUT_PATH)
	if os.path.exists(OUTPUT_PATH):
		shutil.rmtree(OUTPUT_PATH)

	#把游戏目录里的ExportJson拷贝过来
	shutil.copytree(ORIGINAL_PATH, OUTPUT_PATH)

	run(OUTPUT_PATH, ".png")

if __name__ == '__main__':
	main()