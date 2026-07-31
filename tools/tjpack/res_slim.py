# 多语言资源去重

import sys
import os
import shutil
import argparse

import tjdef
import tjlog
import tjutil

# 移除 rootDir 目录中包含 targetDir 对比用的目录
def removeSameFile(rootDir, targetDir):
	if not os.path.exists(rootDir):
		return
	if not os.path.exists(targetDir):
		return
	for f in os.listdir(targetDir):
		rootpath = os.path.join(rootDir, f)
		filepath = os.path.join(targetDir, f)
		if os.path.isfile(filepath):
			if os.path.exists(rootpath):
				tjlog.info("step1 - removeSameFile:", rootpath)
				os.remove(rootpath)

		elif os.path.isdir(filepath):
			removeSameFile(rootpath, filepath)

# 将 rootDir 目录中的文件夹覆盖拷贝到 copyDir 目录下
def copyFile(rootDir, copyDir):
	if not os.path.exists(rootDir):
		return
	tjlog.info("step2 - copyFile %s to %s" % (rootDir, copyDir))
	for f in os.listdir(rootDir):
		filepath = os.path.join(rootDir, f)
		if os.path.isfile(filepath):
			if not os.path.exists(copyDir):
				os.makedirs(copyDir)
			copypath = os.path.join(copyDir, f)
			shutil.copy(filepath, copypath)
		elif os.path.isdir(filepath):
			copypath = os.path.join(copyDir, f)
			if not os.path.exists(copypath):
				os.makedirs(copypath)
			copyFile(filepath, copypath)

def main():
	parser = argparse.ArgumentParser(prog='res_slim', description='res slim')
	# parser.add_argument('--upack', dest='update_pack', help='更新包(y), 完整包(其他)?')
	parser.add_argument('--lang', dest='language', default='cn', help=tjutil.utf2local('语言'))
	# 导出资源目录，默认当前执行目录
	parser.add_argument('--out_res', default='./res', help=tjutil.utf2local('导出资源目录'))
	# 更新包需要和原始资源多语言目录去重比较
	parser.add_argument('--client_res', help=tjutil.utf2local('原始目录用于对比,如client/application/res'))

	args = parser.parse_args(sys.argv[1:])

	# 打包时可能会存放到patch_output目录
	# tjlog.init(True, 'res_slim.log')

	tjlog.init(True)
	tjlog.debug(args)

	lang = args.language
	rootRes = args.out_res
	postfix = "_" + lang
	if lang != 'cn':
		for dirname in tjdef.RES_LANGUAGES_DIRS:
			cnDir = rootRes + '/' + dirname
			multiDir = cnDir + postfix
			# 1、导出的cn资源目录里去掉包含原始多语言目录文件名的内容
			# 完整包不需要执行这一步
			if args.client_res:
				if not os.path.exists(args.client_res):
					raise Exception('client_res not exist')
				originMultiDir = args.client_res + '/' + dirname + postfix
				removeSameFile(cnDir, originMultiDir)

			# 2、将多语言目录资源覆盖到 cn 目录
			copyFile(multiDir, cnDir)

	# 3、去掉多语言目录资源
	for language in tjdef.ALL_LANGUAGES:
		if language != 'cn':
			for dirname in tjdef.RES_LANGUAGES_DIRS:
				removeDir = rootRes + "/%s_%s" % (dirname, language)
				if os.path.exists(removeDir):
					tjlog.info("step3 - removeDir:", removeDir)
					shutil.rmtree(removeDir, True)

if __name__ == '__main__':
	main()