#-*- coding=utf-8 -*-

import os
import json
import shutil

import tjlog
import tjutil

# print __file__, os.getcwd()
envpath = os.environ.get('TJ_CACHE_PATH', os.path.dirname(__file__))
cachepath = os.path.join(os.path.abspath(envpath), './.cache')
cacheindex = os.path.join(cachepath, 'index.json')
cacheinfo = {}
inited = False

def init(path=None):
	global cachepath
	global cacheindex
	global cacheinfo

	if path:
		cachepath = os.path.join(os.path.abspath(path), './.cache')
		cacheindex = os.path.join(cachepath, 'index.json')
	tjlog.info('CACHE_PATH:', cachepath)

	if not os.path.exists(cachepath):
		os.makedirs(cachepath)
	else:
		if os.path.exists(cacheindex):
			with open(cacheindex, 'rb') as fp:
				cacheinfo = json.load(fp)
	inited = True


def save():
	tjlog.info('CACHE BE SAVED IN', cacheindex)
	if os.path.exists(cachepath):
		with open(cacheindex + ".new", 'wb') as fp:
			json.dump(cacheinfo, fp)
		shutil.move(cacheindex + ".new", cacheindex)


class record(object):
	def __init__(self):
		pass

	def __enter__(self):
		pass

	def __exit__(self, exc_type, exc_value, exc_tb):
		save()


def path2key(path, relpath=None):
	path = os.path.normcase(os.path.normpath(path))
	if relpath:
		path = os.path.relpath(path, relpath)
	return path


def query(path, data=None, key=None, tag=''):
	global cacheinfo
	if key is None:
		key = path2key(path)
	if key not in cacheinfo or tag not in cacheinfo[key]:
		return None

	if not data:
		with open(path, 'rb') as fp:
			data = fp.read()
	size = len(data)
	md5 = tjutil.getMD5(data=data)
	info = cacheinfo[key][tag]
	if info['md5'] == md5 and info['size'] == size:
		cachePath = info['cache']
		if os.path.exists(cachePath):
			return cachePath
	# delete old cache
	del cacheinfo[key][tag]
	return None


# path, data: raw
# newPath, newData: converted
def add(path, data=None, newPath=None, newData=None, key=None, tag=''):
	global cacheinfo
	if key is None:
		key = path2key(path)
	if not data:
		with open(path, 'rb') as fp:
			data = fp.read()
	size = len(data)
	md5 = tjutil.getMD5(data=data)
	# write new data in cache
	ext = path[path.rfind('.'):]
	if newPath:
		# png -> pvr.ccz
		ext = newPath[newPath.rfind('.'):]
	pathInCache = os.path.join(cachepath, md5[0], md5[1])
	if not os.path.exists(pathInCache):
		os.makedirs(pathInCache)
	pathInCache = os.path.join(pathInCache, md5 + ext)
	if newPath:
		shutil.copyfile(newPath, pathInCache)
	elif newData:
		with open(pathInCache, 'wb') as fp:
			fp.write(newData)
	else:
		raise Exception("no data or path to save in cache!!!")
	# cache new or old path
	if key not in cacheinfo:
		cacheinfo[key] = {}
	cacheinfo[key][tag] = {
		'path': path,
		'md5': md5,
		'size': size,
		'cache': pathInCache,
	}
	tjlog.debug("[tjcache]", tag, key, "->", pathInCache)