#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import json
import hashlib
import shutil

SERVERURL = "https://127.0.0.1/svn/cnkdjx/Client/MyLuaGame"
diffcmd = "svn diff --summarize {url}@%d {url}@%d".format(url=SERVERURL)


def get_md5(filepath):
	with open(filepath, 'rb') as fp:
		m = hashlib.md5()
		m.update(fp.read())
		code = m.hexdigest()
	return code

def get_file_list(begin, end):
	cmd = diffcmd % (begin, end)
	print cmd
	out = os.popen(cmd).read().strip()
	files = []
	for line in out.split('\n'):
		if line[0] == 'D':
			continue
		print line
		filepath = line[1:].strip().replace('\\', '/')
		if os.path.isdir(filepath):
			continue
		files.append(filepath)
	return files

def export_files(export_dir, urls, version):
	if os.path.exists(export_dir):
		shutil.rmtree(export_dir)

	for url in urls:
		path = url[len(SERVERURL)+1:]
		path = os.path.join(export_dir, path).replace('\\', '/')
		parent = os.path.dirname(path)
		if not os.path.exists(parent):
			os.makedirs(parent)
		export_cmd = 'svn export --depth empty -q --force -r %d %s@ %s@' % (version, url, path)
		print export_cmd
		os.system(export_cmd)

	# TODO: 校验

def dump_patch_json(patch):
	patchfiles = []
	old = os.getcwd()
	os.chdir('%s' % patch)
	for root, dirs, files in os.walk('./'):
		for name in files:
			filepath = os.path.join(root, name).replace('\\', '/')
			size = os.path.getsize(filepath)
			patchfiles.append({
			'md5': get_md5(filepath),
			"name": filepath[2:],
			"size": size,
		})
	os.chdir(old)
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

	main()
