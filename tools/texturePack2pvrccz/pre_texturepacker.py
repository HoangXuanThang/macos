#-*- coding=utf-8 -*-
# 把png小图重新打包成atlas和pvr.ccz文件
# 递归扫描TEXTURE_PATH目录
#!/usr/bin/env python

import os
import os.path
import binascii
import base64
import subprocess
import shutil
import md5
import csv
import json

#####################################
# 全局配置
PACKINPUTFLAG = raw_input('full package or update package? full package(y), update package(n)?(y/n)')
# PACKINPUTFLAG = 'y'
print 'PACKINPUTFLAG: ',PACKINPUTFLAG
ORIGINAL_PATH = '../../client/game01/res/spine'
TEXTURE_PATH = '../../../../pokemon_art/TexturePack/spine'
if PACKINPUTFLAG == 'n':  #是否是更新包
	#游戏里相关的json等复制到TexturePack/updatePack/
	ORIGINAL_PATH = '../../../../pokemon_art/TexturePack/updatePack/'
OUTPUT_PATH = '../../../../pokemon_art/TexturePack/output'
KEY = "erriyue&You_Misdfa_1.1351fsjfdas_kjfdaj;;;fd555kljdfsn"

#####################################
global g_scaleJsons #缓存exportJson里的缩放系数
HAS_ERRORR = False
g_scaleJsons = {} #缓存exportJson里的缩放系数
def getMd5(str) :
	hash = md5.new()
	hash.update(str)
	return hash.hexdigest()
PWD = getMd5(KEY)
print "TexturePacker pvr.ccz KEY: ",PWD

def getCsvProject(project):
	for k,v in csv.csv['pack_info'].items():
		if type(k) == type(0) and v.project == project:
			cfg = {'opt':None}
			if v.opt == None:
				cfg['opt'] = csv.csv['pack_info']['__default'].opt
			else:
				cfg['opt'] = v.opt
			return cfg
	return {'opt': 'RGBA4444'}  #默认


def process(Dir,project,filepath):
	newProject = Dir + "/" + project
	print "starting process ",newProject
	cmd = "TexturePacker " + filepath + \
		" --data " + OUTPUT_PATH + "/" + Dir + "/" + project + "{n}.atlas" + \
		" --sheet " + OUTPUT_PATH + "/" + Dir + "/" + project + "{n}.pvr.ccz" + \
		" --scale-mode Smooth --max-size 2048 --format spine \
--trim-mode Trim --algorithm MaxRects --maxrects-heuristics Best --dither-fs \
--content-protection " + PWD + " --pack-mode Best --size-constraints AnySize --enable-rotation --multipack \
--premultiply-alpha" #pvr格式一定要加上这个 代码里也设置PVRImagesHavePremultipliedAlpha(true)后 就不存在边缘黑边问题了！！
	cfg = getCsvProject(newProject)
	cmd = cmd + " --opt " + cfg['opt'] + " --scale " + str(g_scaleJsons[newProject])
	#cmd = cmd + " --opt PVRTC4 --force-squared" + " --scale " + str(g_scaleJsons[newProject])
	try:
		os.system(cmd)
	except Exception, e:
		print e,"process ",newProject," error!!!!!!"
		global HAS_ERRORR
		HAS_ERRORR = True
		return False
	return True

def mergeAtlas(Dir,project):
	tmp = OUTPUT_PATH + "/" + Dir + "/" + project
	try:
		newFileName = tmp+".atlas"
		newFile = open(newFileName, "wt")
		for x in xrange(99):
			fileName = tmp + str(x) + ".atlas"
			if os.path.exists(fileName) == False:
				break
			f = open(fileName,"r")
			shutil.copyfileobj(f, newFile)
			f.close()
			os.remove(fileName)
			newFile.write('\n')

	except Exception, e:
		print e,"mergeAtlas ",tmp," error!!!!!!"
		global HAS_ERRORR
		HAS_ERRORR = True
		newFile.close()
		return None
		
	newFile.close()
	return newFileName


def checkCanRun(rootDir, ext = None):
	list_dirs = os.listdir(rootDir)
		
	_hashProject = {}
	for Dir in list_dirs:
		path1 = os.path.join(rootDir,Dir)
		for Dir2 in os.listdir(path1):
			filepath = os.path.join(path1,Dir2)
			if os.path.isdir(filepath):
				filepath = os.path.join(filepath,"images")
				if os.path.isdir(filepath):
					project = Dir + "/" + Dir2
					_hashProject[project] = True
						
	global HAS_ERRORR
	flag = True	
	for project,v in g_scaleJsons.iteritems():
		if project not in _hashProject:
			print "!!!!!",project
			HAS_ERRORR = True
			flag = False
	return flag


def getJsonImages(d):
	ret = []
	for slot, v in d.iteritems():
		for img, vv in v.iteritems():
			if 'path' in vv:
				ret.append(vv['path'])
			else:
				ret.append(img)
	return ret



def run(rootDir, ext = None): 
	global HAS_ERRORR
	list_dirs = os.listdir(rootDir)
	cnt1,cnt2= 0,0
	for Dir in list_dirs:
		path1 = os.path.join(rootDir,Dir)
		for Dir2 in os.listdir(path1):
			if (Dir + "/" + Dir2) in g_scaleJsons:
				cnt1 += 1
				flag = False
				filepath = os.path.join(path1,Dir2)
				if os.path.isdir(filepath):
					filepath = os.path.join(filepath,"images")
					if os.path.isdir(filepath):
						if process(Dir,Dir2,filepath):
							atlaspath = mergeAtlas(Dir,Dir2)
							if atlaspath:
								jsonpath = atlaspath[:-5] + 'json'

								# special
								if jsonpath.find('guochangdi.json') != -1:
									jsonpath = jsonpath[:-len('guochangdi.json')] + 'huo_di.json'

								with open(atlaspath, 'rb') as af:
									adata = af.read()
								with open(jsonpath, 'rb') as jf:
									jdata = jf.read()

								jd = json.loads(jdata)
								images = []
								for k, v in jd['skins'].iteritems():
									images += getJsonImages(v)
								images = [x.encode('utf8') for x in images]
								# print images

								# animations.animation 存在可能有问题
								if 'animation' in jd['animations']:
									print 'animation warning!!!', jsonpath

								try:
									for img in images:
										pos1 = adata.find(img + '\r')
										pos2 = adata.find(img + '\n')
										if pos1 == -1 and pos2 == -1:
											print 'not have img:', img
											raise Exception('')
								except:
									flag = False
								else:
									flag = True
									cnt2 += 1

				if flag == False:
					HAS_ERRORR = True
					print "run error!!!",Dir,Dir2

	if cnt1 != cnt2 or cnt2 != len(g_scaleJsons):
		HAS_ERRORR = True
		print cnt1,cnt2,len(g_scaleJsons), 'run error!'
	else:
		print "TEXTURE_PACK RUN OK ~~~~"


def listFilesRemove(rootDir, ext = None): 
	list_dirs = os.walk(rootDir) 
	for root, dirs, files in list_dirs: 
		for f in files:
			if ext and f.endswith(ext):
				os.remove(os.path.join(root, f))

def getExportJsonScale(rootDir):
	global HAS_ERRORR
	list_dirs = os.listdir(rootDir)
	for Dir in list_dirs:
		path1 = os.path.join(rootDir,Dir)
		for Dir2 in os.listdir(path1):
			filepath = os.path.join(path1,Dir2)
			if filepath.endswith(".json"):
				project = Dir + "/" + Dir2[:-5]
				if Dir == "skill2_cutscreen" and Dir2.find("_di") != -1: 
					project = Dir + "/guochangdi" #skill2_cutscreen 大招切屏特殊处理 有共用atlas
				file_object = open(filepath)
				try:
					pstr = file_object.read()
					posImage = pstr.find("\"images\":\"./images/\"}")
					if posImage == -1:
						posImage = pstr.find("\"images\": \"./images/\" }")
						if posImage == -1:
							print "getExportJsonScale get path images",filepath," error!!!!!!"
							HAS_ERRORR = True

					jd = json.loads(pstr)
					sv = 1
					for v in jd["bones"]:
						if v["name"] == 'root':
							sv = v.get("scaleX", 1)
							break
					g_scaleJsons[project] = sv
				except Exception, e:
					HAS_ERRORR = True
					print e,"getExportJsonScale get ",filepath," error!!!!!!"
				finally:
					file_object.close()



def main():
	#先删除output下所有文件
	if os.path.exists(OUTPUT_PATH):
		shutil.rmtree(OUTPUT_PATH)

	#把游戏目录里的ExportJson拷贝过来，把.png .plist全删掉
	shutil.copytree(ORIGINAL_PATH,OUTPUT_PATH)
	listFilesRemove(OUTPUT_PATH,'.png')
	listFilesRemove(OUTPUT_PATH,'.atlas')

	getExportJsonScale(OUTPUT_PATH)
	print "start process HERO_TEXTURE $$$"
	if HAS_ERRORR == False and checkCanRun(TEXTURE_PATH):
		print "run TEXTURE_PATH"
		run(TEXTURE_PATH)

	if HAS_ERRORR :
		print "has_error!!!!!!!!!"
	else:
		print "over ~~~~~~~~~~~"

if __name__ == '__main__':
	main()