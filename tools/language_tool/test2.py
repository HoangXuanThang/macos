import os
import sys
import re

basePath =  os.path.dirname(os.path.abspath('__file__'))
basePath = basePath.replace('\\',"/")

path = basePath + "/"

#匹配中文
regex = re.compile(u'[\u4e00-\u9fa5]+')  
def matchChinese(text):
	temp = text.decode("utf-8")
	global regex
	ret = regex.findall(temp)
	return not (ret == [])


try:
	#打开翻译表
	csvFilePath = path + "StringCfg.csv"
	csvFile = open(csvFilePath, 'r')


	#处理字符串中的双引号
	def deleteMark(str):
		str = str[1:-1]
		str = str.replace("\\\"\"","\\\"")
		return str

	#csvMap key：被替换串，lineMap[2...]表示替换串
	csvMap = {}
	for line in csvFile:
		lineMap = line.split(",")
		key = lineMap[1].decode("gb2312").encode("gb2312")
		val = lineMap[2].decode("gbk").encode("utf-8")[0:-1]
		if  key.find("\\\"\"") <> -1:
			key = deleteMark(key)
			val = deleteMark(val)

		csvMap[key] = val

	#优化：替换的字符串基本为label的文本，所以这里只需要匹配text文本对应的值是否为中文即可
	#对应格式为："text": "xxxxxxxxxxx",
	preStr = '"text"'
	strLen = len(preStr) + 1

	preStr1 = '"placeHolder"'
	strLen1 = len(preStr1) + 1

	#打开文件夹并且遍历所有文件
	fileList = os.listdir(path + "old_json_res")
	for filename in fileList:

		
		#打开被替换文件
		absolutepath = path + "old_json_res/" + filename
		file = open(absolutepath, 'r')
		#打开替换成文件
		absolutepath_new = path + "new_json_res/" + filename
		file_new = open(absolutepath_new, 'w+')

		for line in file.readlines():

			#判断是否为text文本
			ishave = line.find(preStr)

			ishave1 = line.find(preStr1)

			if ishave <> -1:
				index = line.find('"',ishave + strLen)

				text = line[index + 1:line.rfind('"')]

				text1 =  text.decode("utf-8").encode('gb2312')

				#判断是否为中文 如果不是就不做操作，是就先判断在中文翻译表中是否存在，存在就替换成翻译的文本，不存在就输出不存在
				ret =  matchChinese(text)
				if not ret:
					kk = ""
				elif csvMap.has_key(text1):	
					line = line.replace(text,csvMap[text1])
				else:
					text1 = text1.replace(",".decode("utf-8").encode('gb2312'),"，".decode("utf-8").encode('gb2312'))
					if csvMap.has_key(text1):	
						line = line.replace(text,csvMap[text1])
					else:
						print "not found :" + text1
			elif ishave1 <> -1:
				index = line.find('"',ishave1 + strLen1)

				text = line[index + 1:line.rfind('"')]

				text1 =  text.decode("utf-8").encode('gb2312')

				#判断是否为中文 如果不是就不做操作，是就先判断在中文翻译表中是否存在，存在就替换成翻译的文本，不存在就输出不存在
				ret =  matchChinese(text)
				if not ret:
					kk = ""
				elif csvMap.has_key(text1):	
					line = line.replace(text,csvMap[text1])
				else:
					text1 = text1.replace(",".decode("utf-8").encode('gb2312'),"，".decode("utf-8").encode('gb2312'))
					if csvMap.has_key(text1):	
						line = line.replace(text,csvMap[text1])
					else:
						print "not found :" + text1
			file_new.write(line)

		file.close()
		file_new.close()
		
	csvFile.close()
except BaseException,e:
	print "error",str(e)
else:
	print "success" 