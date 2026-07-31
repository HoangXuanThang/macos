#-*- coding=utf-8 -*-

import os
import sys
import time
import json
import signal
import random
import pprint
import shutil
import hashlib
import argparse
import subprocess
import multiprocessing

import tjz
import tjlog
import tjutil
import tjcache

SRC_PATH = '../../MyLuaGame/res'
OUTPUT_PATH = './res_output'
ONLY_XXTEA_EXTS = set(['.png', '.jpg', '.ccz'])
EXTS = set(['.png', '.jpg', '.ccz', '.json', '.atlas', '.fsh', '.vsh', '.tmx', '.skel', '.ExportJson', '.lua']) | ONLY_XXTEA_EXTS
NO_PACK_EXTS = set(['.mp3', '.mp4'])
SPEC_CHARS = set(['.', '_', '-', '@'])
MAPP_REPO = True
PNGQUANT = True
PNGQUANT_IGNORES = []
NAME_SET = set()
NAME_LIST = []
DIR_NAME_LIST = []
PARALLEL_PACK = True

def checkName(path):
	name = os.path.basename(path)
	for x in name:
		if not ('a' <= x <= 'z' or '0' <= x <= '9' or x in SPEC_CHARS):
			tjlog.warning(path, '[%s]' % name, 'name not in standard')
			return False
	return True


def collecteName(path):
	global NAME_SET
	names = path.replace(':', '_').replace('\\', '/').split('/')
	filename = names[-1]
	if filename.find('.') >= 0:
		filename = filename.split('.')[0]
		if len(filename.strip()) == 0:
			names = names[:-1]
		else:
			names[-1] = filename
	if names[-1][-1] == '@':
		names[-1] = names[-1][:-1]
	for name in names:
		NAME_SET.add(name.lower())


def getExt(path):
	fname = os.path.basename(path)
	if fname.rfind('.') >= 0:
		return fname[fname.rfind('.'):]
	return ""


def mapping(path, destDir):
    global NAME_LIST
    st = os.stat(path)  # ดึงข้อมูลไฟล์ต้นฉบับ เช่น ขนาดไฟล์, วันที่สร้าง ฯลฯ
    ext = getExt(path)  # ดึงนามสกุลไฟล์ เช่น ".png", ".json"

    # ตรวจสอบว่าเป็นไฟล์รีวิว (@) หรือไม่
    shenhe = False
    if path[-len(ext)-1] == '@':
        shenhe = True

    while True:
        # สร้างค่าแฮชแบบสุ่มจากข้อมูลไฟล์และค่าแบบสุ่ม
        data = [str(x) for x in list(st) + [time.time(), os.urandom(32)]]
        name = tjutil.getMD5(data='|'.join(data))

        # กำหนดให้ไฟล์อยู่ใน assets/ ทั้งหมด
        filename = random.choice(NAME_LIST)  # เลือกชื่อไฟล์แบบสุ่ม
        key = '%s%s' % (name, ext)  # ใช้ค่าแฮชเต็มตัวเป็นชื่อไฟล์


        # ตรวจสอบว่าไฟล์นี้ยังไม่มีอยู่
        path = os.path.join(destDir, key)
        if not os.path.exists(path):
            return path, key



def pack(path, ext, outputPath):
	global PNGQUANT_IGNORES

	# input file -> data
	with open(path, 'rb') as fp:
		data = fp.read()
	if tjz.isCompressed(data):
		tjlog.warning(path, 'was tj compressed')
		# only copy
		shutil.copyfile(path, outputPath)
		return 0, len(data), None

	# old data -> new data
	oldlen = len(data)
	md5 = None
	# pngquant good than textupack for spine
	dopngquant = PNGQUANT and ext == ".png"
	if dopngquant:
		npath = os.path.normpath(path.strip()).replace('\\', '/')
		for ss in PNGQUANT_IGNORES:
			if npath.find(ss) >= 0:
				dopngquant = False
				tjlog.debug('[ignore pngquant]', path, 'by', ss)
				break
	if dopngquant:
		pathInCache = tjcache.query(path, data, tag='pngquant')
		inCache = False
		# use cache
		if pathInCache:
			inCache = True
			if pathInCache != path:
				with open(pathInCache, 'rb') as fp:
					cacheData = fp.read()
				if cacheData:
					data = cacheData
					newlen = len(data)
					tjlog.debug('[pngquant cache]', path, '%d/%d' % (newlen, oldlen), '%.2f%%' % (100.*newlen/oldlen), 'ignore' if newlen > oldlen else '')
				else:
					inCache = False
		if not inCache:
			# pngquant
			newPath = tjutil.pngSlim(path)
			with open(newPath, 'rb') as fp:
				newData = fp.read()
			newlen = len(newData)
			os.remove(newPath)
			tjlog.debug('[pngquant]', path, '%d/%d' % (newlen, oldlen), '%.2f%%' % (100.*newlen/oldlen), 'ignore' if newlen > oldlen else '')
			if newlen < oldlen:
				tjcache.add(path, data, newData=newData, tag='pngquant')
				data = newData
			else:
				tjcache.add(path, data, newData=data, tag='pngquant')
	elif ext == ".json":
		obj = json.loads(data)
		data = json.dumps(obj, separators=(',', ':'))

	# data -> output file
	if ext in ONLY_XXTEA_EXTS:
		md5 = tjutil.getMD5(data=data)
		tjz.encodeToFile(data, tjz.XXTEA_KEY, outputPath)
	else:
		md5 = tjutil.getMD5(data=data)
		tjz.encodeAndCompressToFile(data, tjz.XXTEA_KEY, outputPath, useLZ4=True)
	newlen = os.stat(outputPath).st_size

	tjlog.debug(path, '' if ext in ONLY_XXTEA_EXTS else 'compress and', 'encode ok')
	return oldlen, newlen, md5

def parallelPack(pf, ext, mappingPath):
	try:
		oldsize, newsize, md5 = pack(pf, ext, mappingPath)
		return pf, ext, mappingPath, oldsize, newsize, md5
	except Exception, e:
		# try twice
		try:
			oldsize, newsize, md5 = pack(pf, ext, mappingPath)
			return pf, ext, mappingPath, oldsize, newsize, md5
		except Exception, e:
			import traceback
			traceback.print_exc()
			raise Exception(pf + " %s" % str(e))


def walkFiles(rootDir, destDir):
	global NAME_SET
	global NAME_LIST
	global DIR_NAME_LIST
	tjlog.info('begin pack', rootDir, destDir)
	tjlog.info('XXTEA_KEY', tjz.XXTEA_KEY)
	if MAPP_REPO:
		destDir = os.path.join(destDir, 'repository')
	if not os.path.exists(destDir):
		os.makedirs(destDir)

	# oldlen = newlen = 0
	# cOldlen = cNewlen = 0
	# ignore = tjzsize = 0
	stat = {
		'oldlen': 0,
		'newlen': 0,
		'cOldlen': 0,
		'cNewlen': 0,
		'ignore': 0,
		'tjzsize': 0,
	}
	extSizes = {}
	ignoreExts = set()
	repo = {}
	allExts = EXTS | NO_PACK_EXTS | ONLY_XXTEA_EXTS

	resDirName = os.path.basename(rootDir) # 'res' or 'res_shenhe'
	listDirs = os.walk(rootDir)
	iFile, nFiles = 0, 0
	for root, dirs, files in listDirs:
		nFiles += len(files)
		for f in files:
			collecteName(os.path.join(root, f))
	stat['nFiles'] = nFiles

	if MAPP_REPO:
		for x in ('.', '..', 'res', 'cocos', 'src', 'updater', 'res_shenhe'):
			NAME_SET.discard(x)
		NAME_LIST = list(NAME_SET)
		DIR_NAME_LIST = random.sample(NAME_LIST, 64)


	pool = None
	parallel = {}
	if PARALLEL_PACK:
		def handle_signal():
			if pool:
				pool.terminate()
			exit(1)
		signal.signal(signal.SIGINT, handle_signal)
		signal.signal(signal.SIGTERM, handle_signal)
		print "The main PID is:", os.getpid()

		pool = multiprocessing.Pool(8)
	# params is `parallelPack` return value
	def onPackOK(returnVals, inSync=False):
		# print '!!! onPackOK', os.getpid(), returnVals
		if not inSync:
			tjlog.progress(cur=stat['nFiles']-len(parallel), max=stat['nFiles'], title='parallel_pack')

		pf, ext, mappingPath, oldsize, newsize, md5 = returnVals

		if pf in parallel:
			del parallel[pf]

		if ext in EXTS:
			stat['tjzsize'] += 1

		stat['oldlen'] += oldsize
		stat['newlen'] += newsize
		if oldsize != newsize:
			stat['cOldlen'] += oldsize
			stat['cNewlen'] += newsize
		if ext not in extSizes:
			extSizes[ext] = {
				'old_size': 0,
				'new_size': 0,
				'cnt': 0,
			}
		extSizes[ext]['cnt'] += 1
		extSizes[ext]['old_size'] += oldsize
		extSizes[ext]['new_size'] += newsize
		if MAPP_REPO:
			pfkey = os.path.relpath(pf, rootDir).replace('\\', '/')
			repo[pfkey] = {'mapping': "repository/%s" % key, 'size': oldsize, 'reposize': newsize}
		else:
			# for patch
			pfkey = os.path.join(resDirName, os.path.relpath(pf, rootDir)).replace('\\', '/')
			repo[pfkey] = {'name': pfkey, 'size': oldsize, 'md5': md5}


	# 遍历 rootDir
	listDirs = os.walk(rootDir)
	for root, dirs, files in listDirs:
		for f in files:
			tjlog.progress(cur=iFile, max=nFiles, title='res_pack')
			iFile += 1
			pf = os.path.join(root, f)
			checkName(pf)

			ext = getExt(pf)
			# lua be remove ext, like 'city.view'
			if ext not in allExts and (pf.find('/src/') >= 0 or pf.find('/updater/') >= 0 or pf.find('/cocos/') >= 0):
				ext = '.lua'

			if ext == '.plist':
				# ignore res/*.plist
				# but it easy be duplicate detected when apple audit
				if f in ('version.plist', 'channel.plist', 'language.plist', 'micro.plist'):
					tjlog.info('[ignore]', pf)
					continue

			elif ext == '.png':
				# ignore when existed the same name file with .pvr.ccz
				pvrcczPath = pf[:-4] + '.pvr.ccz'
				if os.path.exists(pvrcczPath):
					tjlog.info('[ignore]', pf, 'by', pvrcczPath)
					continue

			if MAPP_REPO:
				mappingPath, key = mapping(pf, destDir)
			else:
				key = os.path.relpath(pf, rootDir).replace('\\', '/')
				mappingPath = os.path.join(destDir, key).replace('\\', '/')

			mappingDir = os.path.dirname(mappingPath)
			if not os.path.exists(mappingDir):
				os.makedirs(mappingDir)

			# run task in parallel if PARALLEL_PACK
			inParallel = False
			oldsize, newsize, md5 = 0, 0, None
			if ext in EXTS:
				if PARALLEL_PACK:
					inParallel = True
					parallel[pf] = pool.apply_async(parallelPack, args=(pf, ext, mappingPath), callback=onPackOK)
				else:
					oldsize, newsize, md5 = pack(pf, ext, mappingPath)
					stat['tjzsize'] += 1

			else:
				oldsize = os.stat(pf).st_size
				newsize = oldsize
				md5 = tjutil.getMD5(pf)
				stat['ignore'] += 1
				shutil.copyfile(pf, mappingPath)
				ignoreExts.add(ext)

			if inParallel:
				pass
			else:
				onPackOK((pf, ext, mappingPath, oldsize, newsize, md5), inSync=True)

				# oldlen += oldsize
				# newlen += newsize
				# if oldsize != newsize:
				# 	cOldlen += oldsize
				# 	cNewlen += newsize
				# if ext not in extSizes:
				# 	extSizes[ext] = {
				# 		'old_size': 0,
				# 		'new_size': 0,
				# 		'cnt': 0,
				# 	}
				# extSizes[ext]['cnt'] += 1
				# extSizes[ext]['old_size'] += oldsize
				# extSizes[ext]['new_size'] += newsize
				# if MAPP_REPO:
				# 	pfkey = os.path.relpath(pf, rootDir).replace('\\', '/')
				# 	repo[pfkey] = {'mapping': "repository/%s" % key, 'size': oldsize, 'reposize': newsize}
				# else:
				# 	# for patch
				# 	pfkey = os.path.join(resDirName, os.path.relpath(pf, rootDir)).replace('\\', '/')
				# 	repo[pfkey] = {'name': pfkey, 'size': oldsize, 'md5': md5}

	if PARALLEL_PACK:
		results = parallel.values()
		for r in results:
			r.get()
		pool.close()
		pool.join()

	tjlog.hide_progress()
	data = json.dumps(repo, separators=(',', ':'))
	if MAPP_REPO:
		tjz.encodeAndCompressToFile(data, tjz.XXTEA_KEY, os.path.join(destDir, 'ffd8c30c8fb329c5213c2153b0c8a68f.png'), useLZ4=True)
	with open('repo_mapping.json', 'wb') as fp:
		fp.write(json.dumps(repo))

	tjlog.info('-'*16)
	tjlog.info('exts', EXTS)
	tjlog.info('ignoreExts', ignoreExts)
	tjlog.info('ignore count', stat['ignore'], 'tjz count', stat['tjzsize'], '%.2f%%' % (100.0 * stat['tjzsize'] / (stat['tjzsize'] + stat['ignore'] + 1)))
	tjlog.info('all old', stat['oldlen'], 'all new', stat['newlen'], '%.2f%%' % (100.0 * stat['newlen'] / stat['oldlen']) if stat['oldlen'] > 0 else '')
	tjlog.info('tjz old', stat['cOldlen'], 'tjz new', stat['cNewlen'], '%.2f%%' % (100.0 * stat['cNewlen'] / stat['cOldlen']) if stat['cOldlen'] > 0 else '')
	tjlog.info('extSizes')
	for k, v in extSizes.iteritems():
		ol = v['old_size']
		nl = v['new_size']
		tjlog.info(k, pprint.pformat(v, 2), '%.2f%%' % (100.0 * nl / ol) if ol > 0 else '', 'ratio', '%.2f%%' % (100.0 * ol / stat['oldlen']) if stat['oldlen'] > 0 else '')

def main():
	global SRC_PATH
	global MAPP_REPO
	global PNGQUANT
	global CACHE_PATH
	global CACHE_INFO
	global PNGQUANT_IGNORES
	global PARALLEL_PACK

	parser = argparse.ArgumentParser(prog='res_pack', description='resource packer')
	parser.add_argument('--res-path', dest='res_path', help=tjutil.utf2local('res路径'))
	parser.add_argument('--inplace', dest='inplace', action="store_true", default=False, help=tjutil.utf2local('在res目录里直接操作，不进行复制'))
	parser.add_argument('--nonrepo', dest='nonrepo', action="store_true", default=False, help=tjutil.utf2local('更新包非repo模式'))
	parser.add_argument('--nonpngquant', dest='nonpngquant', action="store_true", default=False, help=tjutil.utf2local('不使用pngquant压缩'))

	args = parser.parse_args(sys.argv[1:])

	tjlog.init(True, 'res_pack.log')
	tjlog.debug(args)

	tjcache.init()

	if args.res_path:
		SRC_PATH = args.res_path
	if args.nonrepo:
		MAPP_REPO = False
	else:
		PARALLEL_PACK = False
	if args.nonpngquant:
		PNGQUANT = False
	tjlog.info('SRC_PATH:', SRC_PATH)
	tjlog.info('ABS_SRC_PATH:', os.path.abspath(SRC_PATH))
	tjlog.info('INPLACE:', args.inplace)
	tjlog.info('MAPP_REPO:', MAPP_REPO)
	tjlog.info('PNGQUANT:', PNGQUANT)
	tjlog.info('PARALLEL_PACK:', PARALLEL_PACK)

	if os.path.exists(OUTPUT_PATH):
		shutil.rmtree(OUTPUT_PATH)
	os.makedirs(OUTPUT_PATH)

	if PNGQUANT:
		with open('ignore_pngquant.ini', 'rb') as fp:
			data = fp.read()
		lines = data.splitlines()
		for l in lines:
			l = os.path.normpath(l.strip()).replace('\\', '/')
			if l:
				PNGQUANT_IGNORES.append(l)

	with tjcache.record():
		walkFiles(SRC_PATH, OUTPUT_PATH)

	# copy res/*.plist
	plist = [os.path.join(SRC_PATH, x) for x in os.listdir(SRC_PATH) if x.endswith(".plist")]
	for f in plist:
		shutil.copy(f, OUTPUT_PATH)

	if args.inplace:
		shutil.rmtree(SRC_PATH)
		shutil.move(OUTPUT_PATH, SRC_PATH)


if __name__ == '__main__':
	main()