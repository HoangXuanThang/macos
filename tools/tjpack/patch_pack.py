#!/usr/bin/python
# -*- coding: utf-8 -*-
# python patch_pack.py --svn=28528 --git=5e234dbdab0c23df44986e0ea6d848c821429a28 --lang="cn tw"

import os
import sys
import time
import json
import hashlib
import shutil
import zipfile
import argparse
import datetime
# dir_util.copy_tree 支持覆盖
from distutils import dir_util

import tjz
import tjlog
import tjdef
import tjutil

import svn_diff
import git_diff

import langs_unopen_res_csv


JENKINS_RUN = bool(os.environ.get('JENKINS_RUN', False) in ('True', 'true', '1', 'on'))
COMMIT_SVN_PATCH = bool(os.environ.get('COMMIT_SVN_PATCH', False) in ('True', 'true', '1', 'on'))

VERSIONPLIST = 'res/version.plist'
TJPACK_PATH = tjutil.abspath('.')
TRUNK_PATH = tjutil.abspath('../../')
CONFIG_PATH = tjutil.abspath('../../config/game')
GIT_REPO_PATH = tjutil.abspath('../../MyLuaGame')
TEXTURE_PARK_PATH = tjutil.abspath('../texturePack2pvrccz')
PACK_OUT_DIR = tjutil.abspath('patch_output')
PACK_OUT_DIFF_DIR = tjutil.abspath('patch_output_diff')
SVN_PATH = tjutil.abspath('../../MyLuaGame')

# from texturePack2pvrccz/texture_pack.py
TEXTURE_PARK_ORIGINAL_PATH = tjutil.abspath('../texturePack2pvrccz/tp_tmp/res')
TEXTURE_PARK_OUTPUT_PATH = tjutil.abspath('../texturePack2pvrccz/tp_tmp/output')

# for raw size and md5
RAW_FILE_INFOS = {}

def svnUpdate():
	tjlog.info('*** 对 svn 和 git 目录执行 revert and update ***')

	with tjutil.cd('patch_pack'):
		os.system('svn revert -R .')
		os.system('svn update')
	if not JENKINS_RUN:
		with tjutil.cd(TRUNK_PATH):
			# os.system('svn revert -R .') # revert in jenkins, quickly in here
			os.system('svn update')
	with tjutil.cd(GIT_REPO_PATH):
		# reset in jenkins, quickly in here
		if JENKINS_RUN:
			os.system('git reset --hard HEAD')
		os.system('git pull')

def commitConfigAndVersion(svn_desc, svn_path):
	if not svn_path:
		return

	tjlog.info('*** patch_pack配表和版本提交svn ***')

	tjlog.info('*** log svn ci -m "%s" %s' % (svn_desc, svn_path))
	# for local test patch
	if JENKINS_RUN and COMMIT_SVN_PATCH:
		os.system('svn ci -m "%s" %s' % (svn_desc, svn_path))

def checkVersion(svnVersion, gitVersion):
	tjlog.info('*** 检查输入版本区间 ***')
	tjlog.info('svnVersion:', svnVersion)
	tjlog.info('gitVersion:', gitVersion)

	if svnVersion:
		svnVersion = svnVersion.strip()
		# 整包需要修正最后一个区间段为最新的svn version
		ranges = svnVersion.split(' ')
		if len(ranges) == 1 and ranges[0].find(':') < 0:
			with tjutil.cd(TRUNK_PATH):
				svninfo = os.popen('svn info').read().strip()
			tjlog.info("svn info", svninfo)
			d = {}
			for line in svninfo.split('\n'):
				info = line.split(':', 1)
				d[info[0]] = info[1].strip()
			svnEndVersion = d['Revision']
			tjlog.info('svnEndVersion:', svnEndVersion)
			ranges[0] += ":" + svnEndVersion
		ranges = [s if s.find(':') >= 0 else '%d:%d' % (int(s), int(s)+1) for s in ranges]
		ranges = [s.split(':') for s in ranges]
		svnVersion = [(int(t[0]), int(t[1])) for t in ranges]

	if gitVersion:
		gitVersion = gitVersion.strip()
		# LuaGameFramework不在svn，需要手动运行bat进行git clone
		with tjutil.cd(GIT_REPO_PATH):
			# 现在只支持区间段
			# (begin, end]
			ranges = gitVersion.split(' ')
			if len(ranges) == 1 and ranges[0].find(':') < 0:
				gitinfo = os.popen('git log -n 1').read().strip()
				tjlog.info("git info", gitinfo)
				for line in gitinfo.split('\n'):
					if line.find('commit ') >= 0:
						info = line.split(' ')
						gitEndVersion = info[1].strip()
						tjlog.info('gitEndVersion:', gitEndVersion)
						ranges[0] += ":" + gitEndVersion
						break
			gitVersion = [s.split(':') for s in ranges]

	tjlog.info('check svnVersion:', svnVersion)
	tjlog.info('check gitVersion:', gitVersion)
	return svnVersion, gitVersion

def unzipGitArchiveTo(zippath, outdir):
	if zippath:
		zfile = zipfile.ZipFile(zippath, "r")
		for fileM in zfile.namelist():
			zfile.extract(fileM, outdir)
		zfile.close()
		os.remove(zippath)

		myluapath = os.path.join(outdir, 'MyLuaGame')
		if os.path.exists(myluapath):
			dir_util.copy_tree(myluapath, outdir)
			dir_util.remove_tree(myluapath)

def exportVCS(svnVersion, gitVersion, langs, shenhe=False):
	tjlog.info('*** 导出版本 ***')
	tjlog.info('export svnVersion:', svnVersion)
	tjlog.info('export gitVersion:', gitVersion)

	if os.path.exists(PACK_OUT_DIFF_DIR):
		shutil.rmtree(PACK_OUT_DIFF_DIR)
	os.makedirs(PACK_OUT_DIFF_DIR)

	svn_diff.export_all_files(PACK_OUT_DIFF_DIR, svnVersion, langs)

	with tjutil.cd(GIT_REPO_PATH):
		zippath = git_diff.export_all_files(gitVersion)
		unzipGitArchiveTo(zippath, PACK_OUT_DIFF_DIR)

	# shenhe 不更新 src/app/sdk 下的文件
	# 按母包里作为最新
	if shenhe:
		sdkPath = os.path.join(PACK_OUT_DIFF_DIR, 'src/app/sdk')
		if os.path.exists(sdkPath):
			shutil.rmtree(sdkPath)

def exportVCSDiff(svnVersion, gitVersion, langs):
	tjlog.info('*** 导出版本diff ***')

	if os.path.exists(PACK_OUT_DIFF_DIR):
		shutil.rmtree(PACK_OUT_DIFF_DIR)
	os.makedirs(PACK_OUT_DIFF_DIR)

	if gitVersion:
		tjlog.info('*** git diff version is', gitVersion)
		with tjutil.cd(GIT_REPO_PATH):
			for begin_version, end_version in gitVersion:
				urls = git_diff.get_file_list(begin_version, end_version)
				zippath = git_diff.export_files(urls, begin_version, end_version)
				unzipGitArchiveTo(zippath, PACK_OUT_DIFF_DIR)

	if svnVersion:
		tjlog.info('*** svn diff version is', svnVersion)
		for begin_version, end_version in svnVersion:
			urls = svn_diff.get_file_list(begin_version, end_version, langs)
			svn_diff.export_files(PACK_OUT_DIFF_DIR, urls, end_version)

	if not os.path.exists(os.path.join(PACK_OUT_DIFF_DIR, 'res')):
		os.makedirs(os.path.join(PACK_OUT_DIFF_DIR, 'res'))

def texturePack():
	# spine要经过texturePack处理
	# ui资源都不用
	tjlog.info('*** texturePack压缩spine ***')

	diffres = os.path.join(PACK_OUT_DIFF_DIR, 'res/spine')
	if not os.path.exists(diffres):
		tjlog.warning("%s is empty, pass texturePack" % diffres)
		return

	if os.path.exists(TEXTURE_PARK_ORIGINAL_PATH):
		shutil.rmtree(TEXTURE_PARK_ORIGINAL_PATH)
	shutil.copytree(diffres, TEXTURE_PARK_ORIGINAL_PATH)
	with tjutil.cd(TEXTURE_PARK_PATH):
		os.system('run_texture.bat n')
	filesTotal = len(tjutil.listFiles(diffres))
	filesTotal2 = len(tjutil.listFiles(TEXTURE_PARK_OUTPUT_PATH))
	if filesTotal != filesTotal2:
		raise Exception(tjutil.utf2local("texturePack后数量不一致 %d output=%d" % (filesTotal, filesTotal2)))

	shutil.rmtree(diffres)
	shutil.move(TEXTURE_PARK_OUTPUT_PATH, diffres)

def tjResPack(path):
	with tjutil.cd(TJPACK_PATH):
		ret = os.system('python res_pack.py --res-path="%s" --inplace --nonrepo' % path)
		if ret != 0:
			raise Exception("tjResPack error %d" % ret)
		with open('repo_mapping.json', 'rb') as fp:
			d = json.load(fp)
			return d

def tjSrcPack(path, oneByOne=False):
	with tjutil.cd(TJPACK_PATH):
		ret = os.system('python src_pack.py n --src-path="%s" --inplace %s' % (path, '--onebyone' if oneByOne else ''))
		if ret != 0:
			raise Exception("tjSrcPack error %d" % ret)
		with open('src_mapping.json', 'rb') as fp:
			d = json.load(fp)
			return d

def addToFileInfo(files, dirpath, infos):
	for path in files:
		relpath = os.path.relpath(path, dirpath).replace('\\', '/')
		infos[relpath] = {
			'name': relpath,
			'md5': tjutil.getMD5(path),
			'size': os.path.getsize(path),
		}
	return infos

def removeSrcFileAndDir():
	srcPath = os.path.join(PACK_OUT_DIR, 'src')
	if os.path.exists(srcPath):
		paths = os.listdir(srcPath)
		for name in paths:
			# skip `config`
			if name == 'config':
				continue
			path = os.path.join(srcPath, name)
			if os.path.isdir(path):
				tjlog.debug('skipsrc dir', path)
				shutil.rmtree(path)
			else:
				tjlog.debug('skipsrc file', path)
				os.remove(path)

def gitCloneBattleDev():
	dirname = git_diff.clone_battle()
	dirname = tjutil.abspath(dirname)

	with tjutil.cd(dirname):
		zippath = git_diff.export_battle_files()

	srcPath = os.path.join(PACK_OUT_DIFF_DIR, 'src', 'battle')
	if not os.path.exists(srcPath):
		os.makedirs(srcPath)

	unzipGitArchiveTo(zippath, srcPath)
	shutil.rmtree(dirname, True)


def langResSlimAndOpen(lang, shenhe):
	# 多语言资源去重
	ret = os.system('python ../res_slim.py --lang %s --out_res %s --client_res %s' % (lang, PACK_OUT_DIR + '/res', SVN_PATH + '/res'))
	if ret != 0:
		raise Exception("res_slim.py error %d" % ret)

	# TODO: 暂时关闭, 发现cards未投放, 但以太关卡有此怪在用
	if True or lang == "cn":
		return

	# 精简多语言未开放资源
	langsRes = langs_unopen_res_csv.getAllLangsRes()
	unopen = langs_unopen_res_csv.calcUnopen(lang, langsRes)
	for d in unopen:
		path, _ = langs_unopen_res_csv.getPath(d)
		if not path:
			continue
		if not os.path.exists(path):
			continue
		if os.path.isdir(path):
			tjlog.debug("remove unopen dir:", path)
			shutil.rmtree(path, True)
		else:
			tjlog.debug("remove unopen file:", path)
			os.remove(path)

	# 增量更新包多语言开放(排除 patch 0)
	if shenhe:
		return

	# 现在多语言增量更新只有svn资源
	curDir = os.getcwd()
	publish = langs_unopen_res_csv.publishWithOldPatch(lang, langs_unopen_res_csv.readLangsCsv(), langsRes)
	for d in publish:
		path, pathType = langs_unopen_res_csv.getPath(d)
		if not path:
			continue
		url = svn_diff.join_url(path)
		tjlog.debug("add open %s:" % pathType, url)
		svn_diff.export_files(curDir, [url], "HEAD", lang=lang, depth="infinity")


def package(lang, svnVersion, gitVersion, manual, patch, shenhe, skipsrc):
	global RAW_FILE_INFOS
	RAW_FILE_INFOS = {}
	tjlog.info('*** 打 %s 包 ***' % lang)

	if not manual:
		if os.path.exists(PACK_OUT_DIR):
			shutil.rmtree(PACK_OUT_DIR)
		shutil.copytree(PACK_OUT_DIFF_DIR, PACK_OUT_DIR)

	with tjutil.cd(PACK_OUT_DIR):
		langResSlimAndOpen(lang, shenhe)
		if skipsrc:
			removeSrcFileAndDir()

		d1 = tjResPack(os.path.join(PACK_OUT_DIR, 'res'))

		bPack = False		
		if os.path.exists(PACK_OUT_DIR + '/src'):
			tmpPath = os.path.join(PACK_OUT_DIR, 'src')
			tmpPathx64 = os.path.join(PACK_OUT_DIR, 'x64/src')
			os.makedirs(tmpPathx64)
			dir_util.copy_tree(tmpPath, tmpPathx64)
			bPack = True
		
		if os.path.exists(PACK_OUT_DIR + '/updater'):
			tmpPath = os.path.join(PACK_OUT_DIR, 'updater')
			tmpPathx64 = os.path.join(PACK_OUT_DIR, 'x64/updater')
			os.makedirs(tmpPathx64)
			dir_util.copy_tree(tmpPath, tmpPathx64)
			bPack = True


		if bPack:
			tmpPathx64 = os.path.join(PACK_OUT_DIR, 'x64')
			tjSrcPack(tmpPathx64)
			
			
		d2 = tjSrcPack(PACK_OUT_DIR)
		
		RAW_FILE_INFOS.update(d1)
		RAW_FILE_INFOS.update(d2)

		# tjlog.debug('RAW_FILE_INFOS:')
		# for k, v in RAW_FILE_INFOS.iteritems():
		# 	tjlog.debug(k, ':', v)

		langDir = tjutil.abspath('../patch_pack/%s/' % lang)
		fileinfos = {}

		# copy version.plist
		if not manual or os.path.exists(VERSIONPLIST):
			shutil.copy(os.path.join(langDir, VERSIONPLIST), 'res')
		if not patch:
			patch = int(tjutil.readPlist('res/version.plist', 'patch'))
			tjlog.info('***', lang, 'old patch is', patch, 'in version.plist')
			# shenhe is 0 patch, but the patch in version.plist is the newest patch
			if not shenhe:
				patch += 1
		patch = int(patch)
		tjlog.info('*** package for patch', patch)

		# delete old patch json
		jsonName = '%d.json' % patch
		if shenhe:
			jsonName = '0.json'
		if os.path.exists(jsonName):
			os.remove(jsonName)

		# version.plist
		RAW_FILE_INFOS.pop(VERSIONPLIST, None)
		tjutil.writePlist(VERSIONPLIST, 'patch', str(patch))
		newestSvnVersion = None
		newestGitVersion = None
		if not manual:
			newestSvnVersion = max([t[1] for t in svnVersion])
			if gitVersion:
				newestGitVersion = gitVersion[-1][1]
			appVersion = tjutil.readPlist(VERSIONPLIST, 'app_version')
			vs = appVersion.split('.')
			# skipsrc不改变svn版本号, +1只是标识
			if skipsrc:
				newestSvnVersion = int(vs[-1]) + 1
				newestGitVersion = None
			vs[-1] = str(newestSvnVersion)
			appVersion = '.'.join(vs)
			tjutil.writePlist(VERSIONPLIST, 'app_version', appVersion)
			if newestGitVersion:
				tjutil.writePlist(VERSIONPLIST, 'git_version', newestGitVersion)
			shutil.copy(VERSIONPLIST, os.path.join(langDir, 'res'))
		tjlog.debug(tjutil.readFile(VERSIONPLIST))
		addToFileInfo([VERSIONPLIST], '.', fileinfos)

		# 更新包不能更新channel和language
		# if shenhe:
		# 	addToFileInfo(['res/channel.plist', 'res/language.plist'], '.', fileinfos)

		# patch json - raw size and md5
		fileinfos.update(RAW_FILE_INFOS)
		# check
		files = tjutil.listFiles(PACK_OUT_DIR, ignoreExt=".bat")
		files = [os.path.relpath(s, PACK_OUT_DIR).replace('\\', '/') for s in files]
		filesSet, fileinfosSet = set(files), set(fileinfos.keys())
		if filesSet != fileinfosSet:
			diffs = filesSet ^ fileinfosSet
			tjlog.error('the patch diff with base, %d files' % len(diffs))
			for file in diffs:
				tjlog.error("%s: %s %s" % (PACK_OUT_DIR, "+" if file in filesSet else "-", file))
			#raise Exception(tjutil.utf2local("文件数量不一致"))

		# new fileinfos - for patch json
		fileinfos = {}
		addToFileInfo(files, '.', fileinfos)
		for k, v in fileinfos.iteritems():
			tjlog.debug(k, ':', v)
		patchDir = '%s/' % str(patch)
		if shenhe:
			# avoid 0 cdn cache in shenhe
			patchDir = '%s/%s/' % (jsonName[:-5], str(newestSvnVersion))
		filePairs = [(tjutil.abspath(d['name']), patchDir + d['name']) for k, d in fileinfos.iteritems()]
		with open(jsonName, 'wb') as fp:
			d = {
				"svn_version": str(newestSvnVersion),
				"git_version": str(newestGitVersion),
				"files": fileinfos.values(),
			}
			json.dump(d, fp)
		filePairs.append((tjutil.abspath(jsonName), jsonName))
		for v in fileinfos.values():
			tjlog.debug('%s:' % jsonName, v)

	# zip
	tjutil.zipFiles('%s_%s.zip' % (lang, jsonName[:-5]), filePairs)

	if not manual:
		shutil.rmtree(PACK_OUT_DIR)

#
# 0号审核更新包
# python .\patch_pack.py --shenhe --svn=47236 --git=0da74758eecb5508ec22a241211e20bdb9d889da --lang=tw
#
def main():
	parser = argparse.ArgumentParser(prog='patch_pack', description='patch packer')
	parser.add_argument('--svn', dest='svn_version', help=tjutil.utf2local('svn版本。如果是完整更新包只填一个起始版本即可。支持a:b c d:e（] 不包含a, 包含b'))
	parser.add_argument('--git', dest='git_version', help=tjutil.utf2local('git版本'))
	parser.add_argument('--manual', action="store_true", default=False, help=tjutil.utf2local('手动打包'))
	parser.add_argument('--shenhe', action="store_true", default=False, help=tjutil.utf2local('审核用的完整更新包'))
	parser.add_argument('--patch', help=tjutil.utf2local('手动指定patch'))
	parser.add_argument('--lang', dest='language', help=tjutil.utf2local('空格分割, 空表示打全语言包 如:cn tw'))
	parser.add_argument('--skipsrc', action="store_true", default=False, help=tjutil.utf2local('体验版跳过代码更新'))
	parser.add_argument('--trial', action="store_true", default=False, help=tjutil.utf2local('体验版战斗代码从git/develop获取'))


	args = parser.parse_args(sys.argv[1:])

	tjlog.init(True, 'patch_pack.log')
	tjlog.debug(args)

	tjlog.info("JENKINS_RUN:", JENKINS_RUN)
	tjlog.info("TRUNK_PATH:", TRUNK_PATH)
	tjlog.info("CONFIG_PATH:", CONFIG_PATH)
	tjlog.info("GIT_REPO_PATH:", GIT_REPO_PATH)

	for path in (TRUNK_PATH, CONFIG_PATH, GIT_REPO_PATH):
		if not os.path.exists(path):
			tjlog.error(path, 'not exists')
			raise Exception(tjutil.utf2local('路径不存在'))

	# 资源和一般性代码不区分语言
	# 配表生成的代码要分不同语言
	langs = tjdef.ALL_LANGUAGES
	if args.language:
		langs = args.language.split(' ')

	if args.manual:
		if not args.patch:
			raise Exception(tjutil.utf2local('手动更新包必须配置patch'))
		if args.shenhe:
			raise Exception(tjutil.utf2local('审核用的完整更新包不能手动'))
	else:
		if not (args.svn_version or args.git_version):
			raise Exception(tjutil.utf2local('自动更新包必须配置svn或git版本号'))

	if not args.manual:
		# 自动模式
		# svn up，生成配置，自动commit，获取最新svn版本号
		svnUpdate()
		if args.shenhe:
			svnVersion, gitVersion = [(0, int(args.svn_version))], [('', args.git_version)]
			exportVCS(args.svn_version, args.git_version, langs, args.shenhe)
		else:
			svnVersion, gitVersion = checkVersion(args.svn_version, args.git_version)
			exportVCSDiff(svnVersion, gitVersion, langs)
	else:
		backup = 'patch_output_manual_backup%d' % int(time.time())
		if os.path.exists(backup):
			shutil.rmtree(backup)
		shutil.copytree(PACK_OUT_DIR, backup)
		svn_desc, svn_path = '', ''
		svnVersion, gitVersion = checkVersion(args.svn_version, args.git_version)

	if args.trial and not args.skipsrc:
		gitCloneBattleDev()

	for lang in langs:
		if lang not in tjdef.ALL_LANGUAGES:
			tjlog.warning(lang, 'is not support')
			continue
		package(lang, svnVersion, gitVersion, args.manual, args.patch, args.shenhe, args.skipsrc)

	if not args.manual:
		shutil.rmtree(PACK_OUT_DIFF_DIR)



if __name__ == '__main__':
	startTime = datetime.datetime.now()
	main()
	print 'cost time', datetime.datetime.now() - startTime
