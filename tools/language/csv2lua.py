 #coding=utf-8

import sys
import os
import xlrd
from xlrd import *

reload(sys) # reload 才能调用 setdefaultencoding 方法
sys.setdefaultencoding('utf-8') # 设置 'utf-8'

basePath = os.path.dirname(os.path.abspath('__file__'))
basePath = basePath.replace("\\", "/")
targetPath = basePath + "/../../client/application/src/app/defines/l10n/"
# print targetPath
fileAbsPath = basePath + "/temp.xls"

def readExcel():
	book = xlrd.open_workbook(fileAbsPath)
	sheet = book.sheet_by_index(0)
	lines = []
	index = 1
	for rx in xrange(sheet.nrows):
		line = []
		for cy in xrange(sheet.ncols):
			cell = sheet.cell(rx, cy)
			val = cell.value
			if type(val) == type(12.3):
				print str(rx) + " " + str(cy) + " error float type"
			ret = val.strip()
			# 前3行不处理，以下结构转换处理成csv存储结构
			if index > 3 :
				ret = ret.replace('"', '""')
				ret = '"%s"' % ret
				ret = ret.replace('"""', '"')
			line.append(ret)
		lines.append(line)
		index = index + 1
	return lines

def main():
	if not os.path.exists(fileAbsPath):
		print "file not exist"
		return
	lines = readExcel()
	# print lines

	if lines[0][0].strip() != u'变量名':
		print utf2local('第一行不是“变量名”，文件无法被生成！')
		return

	for i in xrange(2, len(lines[0])):
		fileName = lines[0][i]
		if not fileName or fileName == "":
			continue
		fileName += ".lua"
		fileName = targetPath + fileName
		if os.path.exists(fileName):
			os.remove(fileName)
		luaFile = open(fileName, "w")
		writeData = '''--
--Copyright (c) 2014 YouMi Information Technology Inc.
--Copyright (c) 2017 TianJi Information Technology Inc.
--
local config = {
'''
		for j in xrange(3, len(lines)):
			writeData = writeData + "\t[" + lines[j][1] + "] = "
			writeData = writeData + lines[j][i] + ",\n"
		writeData = writeData + "}\n\nreturn config"
		luaFile.write(writeData)
		luaFile.close()

	os.system("start " + targetPath)

if __name__ == "__main__":
	main()