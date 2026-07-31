 #coding=utf-8 

import os
import sys
import re


basePath =  os.path.dirname(os.path.abspath('__file__'))
basePath = basePath.replace('\\',"/")

csv_path = basePath + "/"
lua_path = basePath + "/old_json_res/"

#判断是否为中文
regex = re.compile(u'[\u4e00-\u9fa5]+')  
def matchChinese(text):
	temp = text.decode("utf-8")
	global regex
	ret = regex.findall(temp)
	return not (ret == [])

#写入csv
def writeCsv(csvid,string):
	global csvFile
	csvFile.write(csvid)
	csvFile.write(",")
	string = string.replace(",","，")
	string = string.decode('utf8').encode('gb2312')
	csvFile.write(string)
	csvFile.write("\n")

#处理字符串中的双引号
def deleteMark(str):
	str = str[1:-1]
	str = str.replace("\\\"\"","\\\"")
	return str

try:
	csvFilePath = csv_path + "StringCfg.csv"
	csvFile = open(csvFilePath, 'a+')

	#保存所有的中文字符串做标记，避免重复写入
	keyMap = {}
	csvKeyStartIndex = 1
	for line in csvFile:
		lineMap = line.split(",")
		key = lineMap[1].decode("gb2312").encode("gb2312")
		val = lineMap[2].decode("gbk").encode("utf-8")[0:-1]
		if  key.find("\\\"\"") <> -1:
			key = deleteMark(key)
			val = deleteMark(val)

		keyMap[key] = 1
		csvKeyStartIndex += 1

	#需要翻译的都是文本，所以只用找json中的文本
	preStr = '"text"'
	strLen = len(preStr) + 1

	preStr1 = '"placeHolder"'
	strLen1 = len(preStr1) + 1

	fileList = os.listdir(lua_path)

	for filename in fileList:
		if filename.find(".json") == -1:
			continue

		absolutepath = lua_path + filename
		file = open(absolutepath, 'r')

		for line in file.readlines():

			ishave = line.find(preStr)
			ishave1 = line.find(preStr1)

			if ishave <> -1:
				index = line.find('"',ishave + strLen)

				text = line[index + 1:line.rfind('"')]

				text1 =  text.decode("utf-8").encode('gb2312')

				ret = matchChinese(text)

				if not ret:
					continue
				if not keyMap.has_key(text1):				
					
					writeCsv(str(csvKeyStartIndex),text)

					keyMap[text1] = 999

					csvKeyStartIndex += 1
			elif ishave1 <> -1:
				index = line.find('"',ishave1 + strLen1)

				text = line[index + 1:line.rfind('"')]
				text1 =  text.decode("utf-8").encode('gb2312')
				
				ret = matchChinese(text)

				if not ret:
					continue
				if not keyMap.has_key(text1):				
					
					writeCsv(str(csvKeyStartIndex),text)

					keyMap[text1] = 999

					csvKeyStartIndex += 1
				
		file.close()
	csvFile.close()

except BaseException,e:
	print "error",str(e)
else:
	print "success" 
