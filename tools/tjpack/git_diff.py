#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# only for lua source
#

import os
import sys
import json
import hashlib
import shutil

import tjlog


SERVERURL = "https://git.tianji-game.com/tjgame/LuaGameFramework.git"
LUA_SRCS = "MyLuaGame/src MyLuaGame/cocos"

BATTLEURL = "https://robot:robot@git.tianji-game.com/tjgame/pokemon_battle.git"

diffcmd = "git diff {begin} {end} --diff-filter=ACMRTUXB --name-only " + LUA_SRCS
archivecmd = "git archive --output=\"{zipname}\" {version} {files}"
clonecmd = "git clone {url} {dir}"

def get_file_list(begin, end):
	cmd = diffcmd.format(begin=begin, end=end)
	tjlog.info(cmd)
	out = os.popen(cmd).read().strip()
	files = []
	for line in out.split('\n'):
		filepath = line.strip()
		if filepath:
			tjlog.info(filepath)
			files.append(filepath)
	return files

def export_files(urls, begin, end):
	# if empty
	if not urls:
		return None
	urls = ' '.join(urls)
	zipname = '%s_%s.zip' % (begin[:8], end[:8])
	cmd = archivecmd.format(zipname=zipname, version=end, files=urls)
	tjlog.info(cmd)
	out = os.popen(cmd).read().strip()
	zippath = os.path.abspath(zipname)
	tjlog.info(zippath)
	return zippath

def export_all_files(version):
	zipname = '%s.zip' % version
	cmd = archivecmd.format(zipname=zipname, version=version, files=LUA_SRCS)
	tjlog.info(cmd)
	out = os.popen(cmd).read().strip()
	zippath = os.path.abspath(zipname)
	tjlog.info(zippath)
	return zippath

def export_battle_files(version="develop"):
	zipname = '%s.zip' % version
	cmd = archivecmd.format(zipname=zipname, version=version, files="")
	tjlog.info(cmd)
	out = os.popen(cmd).read().strip()
	zippath = os.path.abspath(zipname)
	tjlog.info(zippath)
	return zippath

def clone_battle():
	dirname = "pokemon_battle"
	if os.path.exists(dirname):
		shutil.rmtree(dirname)
	cmd = clonecmd.format(url=BATTLEURL, dir=dirname)
	tjlog.info(cmd)
	out = os.popen(cmd).read().strip()
	return dirname

def main():
	if len(sys.argv) == 1:
		begin_version = input('input being git version:')
		end_version = input('input end git version:')
	else:
		begin_version = sys.argv[1]
		end_version = sys.argv[2]

	urls = get_file_list(begin_version, end_version)
	zippath = export_files(urls, begin_version, end_version)

if __name__ == "__main__":
	GIT_REPO_PATH = os.path.abspath(os.getcwd() + '/../../client/LuaGameFramework').replace('\\', '/')
	os.chdir(GIT_REPO_PATH)
	main()

	# export_all_files(r'G:\pokemon_src\trunk\tools\tjpack', 'b2347519eea7bf91d1718a9e3ec29de7f210c8e3'))
