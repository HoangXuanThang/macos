#coding=utf-8

import os
import re
import sys
import xlwt
from xlwt import *

reload(sys)
sys.setdefaultencoding('utf-8')  # 设置 'utf-8'

basePath =  os.path.dirname(os.path.abspath('__file__'))
basePath = basePath.replace('\\',"/")

csv_path = basePath + "/temp.xls"
text_path = basePath + "/temp.txt"

#判断是否为中文
regex = re.compile(u'[\u4e00-\u9fa5]+')

def matchChinese(text):
	global regex
	temp = text.decode("utf-8")
	ret = regex.findall(temp)
	if ret:
		for i in ret:
			if i.find(',') >= 0:
				raise Exception('存在英文逗号 [%s]' % text)
	return not (ret == [])

def checkStrIsSpe(val):
	isSpe = True
	isChines = matchChinese(val)
	if isChines:
		return val
	if len(val) == 6:
		for i in xrange(1, 6):
			if val[i] != "\"":
				isSpe = False
	else:
		isSpe = False
	if isSpe:
		val = val[2:-2]
		# print "spe val is ", val
	return val

def main():
	if not os.path.exists(text_path):
		print "not exist txt file"
		return
	txtFile = open(text_path, 'r')
	lines = txtFile.readlines()
	if os.path.exists(csv_path):
		os.remove(csv_path)
	book = Workbook(encoding = 'utf-8')
	sheet1 = book.add_sheet('sheet1')

	nr = 0
	for line in lines:
		line = line.strip().split('\t')
		# print line
		nc = 0
		for v in line:
			v = checkStrIsSpe(v)
			sheet1.write(nr, nc, v)
			nc += 1
		nr += 1
	txtFile.close()
	book.save(csv_path)
	os.remove(text_path)

if __name__ == "__main__":
	main()