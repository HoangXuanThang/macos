#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import json
import hashlib
import shutil
import subprocess

import tjlog
import tjutil
import tjdef




SERVERURL = os.environ.get('SERVERURL', 'https://127.0.0.1/svn/cnkdjx/Client/MyLuaGame')
diffcmd = "svn diff --summarize {url}@{begin} {url}@{end}"
localdiffcmd = "svn diff --summarize"
exportcmd = "svn export --depth {depth} -q --force -r {version} {url}@ {path}@"
exportallcmd = "svn export -q --force -r {version} {url}@ {path}@"

IGNORE_FILES = set([
	"build.bat",
	"build_v2.bat",
	"build.sh",


	"res/version_cn.plist",
	"res/version_en.plist",
	"res/version_en_test.plist",
	"res/version_en_shenhe2.plist",
	"res/version_en_shenhe3.plist",
	"res/version_en_shenhe_test.plist",
	"res/version_kr.plist",
	"res/version_test.plist",
	"res/version_trial.plist",
	"res/version_tw_shenhe_test.plist",
	"res/version_vn_shenhe_test.plist",
	"res/version_xy.plist",
	"res/version_tw.plist",
	"res/README.md",

	# 不能覆盖
	"res/channel.plist",
	"res/language.plist",

	# 忽略特殊logo不更新
	"login/icon_logo.png",
	"res/resources/login/icon_logo.png",

	# 忽略开发目录
	"dev/",
])

def parse_svn_diff_summary(out, langs=None):
	files = []
	for line in out.split('\n'):
		line = line.strip()
		if not line:
			continue
		if line[0] == 'D':
			continue
		tjlog.info(line)
		filepath = line[1:].strip().replace('\\', '/')
		if os.path.isdir(filepath):
			continue
		# filename = os.path.basename(filepath)
		ignore = False
		for filename in IGNORE_FILES:
			if filepath.find(filename) >= 0:
				ignore = True

		if langs and not ignore:
			for dirname in tjdef.RES_LANGUAGES_DIRS:
				prefix = "res/" + dirname + "_"
				if filepath.find(prefix) >= 0:
					ignore = True
					for language in langs:
						if filepath.find(prefix + language) >= 0:
							ignore = False
							break
					break

		if ignore:
			tjlog.info("svn_diff skip file:", filepath)
			continue

		files.append(filepath)
	return files

def get_file_list(begin, end, langs):
	cmd = diffcmd.format(url=SERVERURL, begin=begin, end=end)
	tjlog.info(cmd)
	out = os.popen(cmd).read().strip()
	return parse_svn_diff_summary(out, langs)

def get_local_file_list():
	cmd = localdiffcmd
	tjlog.info(cmd)
	out = os.popen(cmd).read().strip()
	return parse_svn_diff_summary(out)

# lang参数用于导出多语言, 不留只按urls导出
# 关于 depth 几个参数的含义:
# –depth empty：只包含目录自身，不包含目录下的任何文件和子目录。
# –depth files：包含目录和目录下的文件，不包含子目录。
# –depth immediates：包含目录和目录下的文件及子目录。但不对子目录递归。
# –depth infinity：这是默认的，包含整个目录树。
def export_files(export_dir, urls, version, lang=None, depth='empty'):
	# if os.path.exists(export_dir):
	# 	shutil.rmtree(export_dir)
	for i, url in enumerate(urls):
		tjlog.progress(cur=i, max=len(urls), title='svn_export_files')
		path, partPath, prefix = url, None, None
		if path.startswith(SERVERURL):
			prefix = SERVERURL
			path = url[len(SERVERURL)+1:]
			partPath = path.replace('\\', '/')
		else:
			path = path.replace('\\', '/')
			if path.find('res/'):
				prefix = path[:path.find('res/')-1]
				partPath = path[path.find('res/'):]
		path = os.path.join(export_dir, path).replace('\\', '/')
		parent = os.path.dirname(path)
		if not os.path.exists(parent):
			os.makedirs(parent)
		if version:
			export_cmd = exportcmd.format(version=version, url=url, path=path, depth=depth)
			tjlog.info(export_cmd)
			os.system(export_cmd)
		else:
			# local diff file
			tjlog.info('copy', url, path)
			shutil.copy(url, path)

		if partPath and lang and lang != 'cn':
			dirs = partPath.split('/')
			if len(dirs) >= 2 and dirs[0] == "res" and dirs[1] in tjdef.RES_LANGUAGES_DIRS:
				dirs[1] = '%s_%s' % (dirs[1], lang)
				langPath = '/'.join(dirs)
				url = '%s/%s' % (prefix, langPath)
				tjlog.info('cover with lang', url, path)
				if version:
					export_cmd = exportcmd.format(version=version, url=url, path=path, depth=depth)
					tjlog.info(export_cmd)
					os.system(export_cmd)
				else:
					# local diff file
					tjlog.info('copy', url, path)
					shutil.copy(url, path)

	tjlog.hide_progress()

	# TODO: 校验

def export_all_files(export_dir, version, langs=None):
	# if os.path.exists(export_dir):
	# 	shutil.rmtree(export_dir)
	export_cmd = exportallcmd.format(version=version, url=SERVERURL, path=export_dir)
	tjlog.info(export_cmd)
	ret = os.system(export_cmd)
	if ret != 0:
		tjlog.error('export_all_files may be error !!!')

	with tjutil.cd(export_dir):
		for filename in IGNORE_FILES:
			if os.path.exists(filename):
				if os.path.isdir(filename):
					tjlog.info("export_all_files remove dir:", filename)
					shutil.rmtree(filename)
				else:
					tjlog.info("export_all_files remove file:", filename)
					os.remove(filename)

		if langs:
			for dirname in tjdef.RES_LANGUAGES_DIRS:
				prefix = "res/" + dirname + "_"
				for language in tjdef.ALL_LANGUAGES:
					if language in langs:
						continue
					# 移除其它多语言目录
					dirpath = prefix + language
					if os.path.exists(dirpath):
						tjlog.info("export_all_files remove dir:", dirpath)
						shutil.rmtree(dirpath)


def join_url(path):
	path = path.replace("\\", "/")
	if path[0] == "/":
		return SERVERURL + path
	return SERVERURL + "/" + path

def dump_patch_json(patch):
	patchfiles = []
	with tjutil.cd('%s' % patch):
		for root, dirs, files in os.walk('./'):
			for name in files:
				filepath = os.path.join(root, name).replace('\\', '/')
				size = os.path.getsize(filepath)
				patchfiles.append({
				'md5': tjutil.getMD5(filepath),
				"name": filepath[2:],
				"size": size,
			})
	with open('%d.json' % patch, 'w') as fp:
		json.dump(patchfiles, fp)

def main():
	if len(sys.argv) == 1:
		begin_version = input('input being svn version:')
		end_version = input('input end svn version:')
		patch = input('input patch number:')
	else:
		begin_version = int(sys.argv[1])
		end_version = int(sys.argv[2])
		patch = int(sys.argv[3])

	urls = get_file_list(begin_version, end_version)
	export_files('%s' % patch, urls, end_version)
	dump_patch_json(patch)


if __name__ == "__main__":
	# begin_version = 7217
	# end_version = 7261
	# patch = 3
	# urls = get_file_list(begin_version, end_version)
	# export_files('%s' % patch, urls, end_version)
	# dump_patch_json(patch)

	# main()

	export_all_files("test_export", 12921)
