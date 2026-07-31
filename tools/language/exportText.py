 #coding=utf-8

import os
import sys
import re
import sys
import xlrd
import xlwt
from xlrd import *
from xlwt import Workbook

# 使得 sys.getdefaultencoding() 的值为 'utf-8'
reload(sys)                      # reload 才能调用 setdefaultencoding 方法
sys.setdefaultencoding('utf-8')  # 设置 'utf-8'


basePath =  os.path.dirname(os.path.abspath('__file__'))
basePath = basePath.replace('\\',"/")

csv_path = basePath
new_str_path = basePath + "/"
lua_path = basePath + "/old_json_res/"

csvFile = None

#判断是否为中文
regex = re.compile(u'[\u4e00-\u9fa5]+')

def readExcel(fileName):
	book = xlrd.open_workbook(fileName)
	sheet = book.sheet_by_index(0)
	lines = []
	for rx in xrange(sheet.nrows):
		line = []
		for cy in xrange(sheet.ncols):
			cell = sheet.cell(rx, cy)
			val = cell.value
			if cell.ctype in (2,3):
				if int(val) == val:
					val = unicode(int(val))
				else:
					val = unicode(val)
			line.append(val)
		lines.append(line)

	return lines

def matchChinese(text):
	global regex
	temp = text.decode("utf-8")
	ret = regex.findall(temp)
	if ret:
		for i in ret:
			if i.find(',') >= 0:
				raise Exception('存在英文逗号 [%s]' % text)
	return not (ret == [])

def parseCsvValue(s):
	if s[0] == "\"":
		if len(s) > 2 and s[1] == "\"" and s[2] == "\"" :
			s = s[3:-3]
		else :
			s = s[1:-1]
	s = s.replace("\"\"", "\"")
	return s

def parseJsonValue(s):
	s = s.replace("\\\"", "\"")
	return s

def readCsvLine(line):
	segs = line.split(",")
	lineMap = []
	merge = False
	for s in segs:
		if merge:
			lineMap[-1] += ',%s' % s
			if len(s) == 0:
				continue
			if s[-1] == "\"":
				merge = False
		else:
			lineMap.append(s)
			if len(s) == 0:
				continue
			if s[0] == "\"":
				merge = True
			if len(s) > 1 and s[-1] == "\"":
				merge = False
	key = lineMap[1]
	return parseCsvValue(key), lineMap[0].isdigit()

#写入csv
def writeCsv(csvid,string):
	global csvFile
	csvFile.write(csvid)
	csvFile.write(",")
	# json -> csv
	if string.find("<") >= 0 or string.find("{") >= 0 or string != string.strip():
		string = '"""%s"""' % string
	elif string.find(',') >= 0 or string.find("\\\"") >= 0 :
		string = '"%s"' % string

	string = string.replace("\\\"", "\"\"")
	string = string
	csvFile.write(string)
	csvFile.write("\n")

def writeTxt(csvid,string):
	global txtFile
	txtFile.write(csvid)
	txtFile.write("\t")
	# json -> csv
	if string.find("<") >= 0 or string.find("{") >= 0 or string != string.strip():
		string = '"""%s"""' % string
	elif string.find(',') >= 0 or string.find("\\\"") >= 0 :
		string = '"%s"' % string

	string = string.replace("\\\"", "\"\"")
	string = string.decode('utf8').encode('gbk')
	txtFile.write(string)
	txtFile.write("\n")

def main():
	# 升级一下pip的版本 低版本有些库没有
	os.popen('python pip install --upgrade pip')
	global csvFile
	global lua_path
	csvFilePath = csv_path + "/temp.xls"
	if not os.path.exists(csvFilePath):
		print "not excel "
		return
	csvFile = readExcel(csvFilePath)

	global txtFile
	txtFilePath = new_str_path + "log.txt"
	if os.path.exists(txtFilePath):
		os.remove(txtFilePath)
	txtFile = open(txtFilePath, 'a+')
	txtFile.write("Add")
	txtFile.write("\n")

	book = Workbook(encoding = 'gbk') # 后面用了gbk编码所以这边要用gbk
	sheet1 = book.add_sheet('sheet1')

	#保存所有的中文字符串做标记，避免重复写入
	keyMap = set()
	addList = set()
	commonList = set()
	oldTextMap = {}
	csvKeyStartIndex = 1
	r = 0
	for line in csvFile:
		if len(line) == 0:
			continue
		# 先把之前的excel中的写入到新的excel中
		# 用旧的excel无法中文 默认是ascII格式的
		c = 0
		for v in line:
			sheet1.write(r, c, v)
			c += 1
		r += 1
		key, flag = parseCsvValue(line[1].decode("utf8").encode('gbk')), line[0].isdigit()
		if flag:
			keyMap.add(key)
			oldTextMap[key] = line[0]
			csvKeyStartIndex += 1

	#需要翻译的都是文本，所以只用找json中的文本
	preStr = '"text"'
	strLen = len(preStr) + 1
	preStr1 = '"placeHolder"'
	strLen1 = len(preStr1) + 1
	fileList = os.listdir(lua_path)
	csvLen = len(csvFile)

	for filename in fileList:
		if filename.endswith(".json") == -1:
			continue

		absolutepath = lua_path + filename
		file = open(absolutepath, 'r')

		for line in file.readlines():
			ishave = line.find(preStr)
			ishave1 = line.find(preStr1)

			if ishave != -1:
				index = line.find('"',ishave + strLen)
				text = line[index + 1:line.rfind('"')]
				text1 = parseJsonValue(text.decode("utf8").encode('gbk'))
				ret = matchChinese(text)

				if not ret:
					continue
				if not text1 in keyMap:
					sheet1.write(csvLen, 0, str(csvKeyStartIndex))
					sheet1.write(csvLen, 1, text1)
					writeTxt(str(csvKeyStartIndex),text)
					keyMap.add(text1)
					addList.add(text1)
					csvKeyStartIndex += 1
					csvLen += 1
				else:
					commonList.add(text1)

			elif ishave1 != -1:
				index = line.find('"',ishave1 + strLen1)
				text = line[index + 1:line.rfind('"')]
				text1 = parseJsonValue(text.decode("utf8").encode('gbk'))
				ret = matchChinese(text)

				if not ret:
					continue
				if not text1 in keyMap:
					sheet1.write(csvLen, 0, str(csvKeyStartIndex))
					sheet1.write(csvLen, 1, text1)
					writeTxt(str(csvKeyStartIndex),text)
					keyMap.add(text1)
					addList.add(text1)
					csvKeyStartIndex += 1
					csvLen += 1
				else:
					commonList.add(text1)

		file.close()

	notUseList = keyMap - addList - commonList
	txtFile.write("not Use")
	txtFile.write("\n")
	for k in notUseList:
		oldIndex = oldTextMap[k]
		txtFile.write(str(oldIndex))
		txtFile.write("\t")
		txtFile.write(k)
		txtFile.write("\n")
	os.remove(csvFilePath)
	book.save(csvFilePath)
	txtFile.close()


if __name__ == '__main__':
	try:
		lua_path = basePath + "/../../client/application/res/uijson/"
		main()

	except BaseException,e:
		print "error",str(e)
		raise