#-*- coding=utf-8 -*-
# csv2lua
# 递归扫描SRC_PATH目录，读取全部csv文件，生成lua
# csv路径名去掉.csv后缀后，将分隔符替换为.，即为lua table变量名
# 如bullet\fire.csv -> bullet.fire = {...}

# CSV 规范
# 1 开头是不留空，以行为单位。
# 2 可含或不含列名，含列名则居文件第一行。
# 3 一行数据不跨行，无空行。
# 4 以半角逗号（即,）作分隔符，列为空也要表达其存在。
# 5 列内容如存在半角逗号（即,）则用半角引号（即','）将该字段值包含起来。
# 6 列内容如存在半角引号（即"）则应替换成半角双引号（""）转义，并用半角引号（即""）将该字段值包含起来。
# 7 文件读写时引号，逗号操作规则互逆。
# 8 内码格式不限，可为 ASCII、Unicode 或者其他。
# 9 不支持特殊字符

import os
import re
import shutil
import traceback
import platform
from datetime import *
# from luacfg import *

#####################################
# 全局配置
LUA_BOOL = 1
LUA_NUM = 2
LUA_STRING = 3
LUA_ARRAY = 4
LUA_MAP = 5
LUA_CSV = 6
LUA_NIL = 7


#####################################
# 运行时全局变量
g_luaTableMap = {}

#####################################

def utf2local(s):
	if platform.system() == 'Windows':
		return s.decode('utf8').encode('gbk')
	return s

def utf2gbk(s):
	return s.decode('utf8').encode('gbk')

def isBool(s):
	return s in ('true', 'false', 'True', 'False', 'TRUE', 'FALSE')

def isInt(s):
	try:
		int(s)
		return True
	except Exception, e:
		# print e
		return False

def isFloat(s):
	try:
		float(s)
		return True
	except Exception, e:
		# print e
		return False

def isNumber(s):
	return isInt(s) or isFloat(s)

def isString(s):
	if len(s) == 0:
		return False
	return (s[0] == '"' and s.count('"') % 2 == 0 and s[-1] == '"')\
		or (s[0] == "'" and s.count("'") == 2 and s[-1] == "'")

def isCsv(s):
	return s.endswith(".csv")

def isNil(s):
	if len(s) == 0:
		return True

'''
Array:
<item1;item2;item3;item4>
item支持嵌套
'''
def isArray(s):
	return s[0] == '<' and s[-1] == '>'

'''
Map:
{key=value;key=value}
key: int, string
value支持嵌套

1 = 222 ;aaa =' 333 ';bbb= 'x;x;x'
'''
def isMap(s):
	return s[0] == '{' and s[-1] == '}'

def whatType(s):
	s = s.strip()
	if isNil(s):
		return LUA_NIL
	elif isCsv(s):
		return LUA_CSV
	elif isString(s):
		return LUA_STRING
	elif isBool(s):
		return LUA_BOOL
	elif isNumber(s):
		return LUA_NUM
	elif isMap(s):
		return LUA_MAP
	elif isArray(s):
		return LUA_ARRAY
	return LUA_STRING

def splitLine(line):
	# return [x.strip() for x in line.split(',')]
	ret = []
	tmp = ''
	strb = False
	ignore = False
	for i in xrange(len(line)):
		c = line[i]
		if ignore:
			tmp += c
			ignore = False
			continue

		if c == ',':
			if not strb:
				ret.append(tmp)
				tmp = ''
				continue
		elif c == '"':
			if strb:
				if i + 1 < len(line) and line[i+1] == '"':
					ignore = True
				else:
					strb = False
			else:
				strb = True

		tmp += c
	ret.append(tmp)
	return [x.strip() for x in ret]

def parseCsv(fileName, keys, vars, defs, lines):
	# 第一行为变量名（必须有）
	varList = [x.strip() for x in vars.split(',')]

	# 第二行为默认值（选项）
	defList = [x.strip() for x in defs.split(',')]

	# 第二（或三）行为属性名，忽略空的列
	keyList = [x.strip() for x in keys.split(',')]

	# keys和vars长度必须一致，取小的值
	if len(varList) != len(keyList):
		for i in range(max(len(varList), len(keyList))):
			print varList[i], keyList[i].decode('gb2312')
		raise Exception("varList %d, keyList %d, there length must be equal!" % (len(varList), len(keyList)))

	varFilter = None
	for ffilter, vfilter in IGNORE_KEYS:
		if re.search(ffilter, fileName):
			varFilter = vfilter

	# 忽略变量名以下划线开始的列（比如_comment，只是注释功能）
	ignoreList = [False] * len(varList)
	for i in xrange(1, len(varList)):

		if len(varList[i]) == 0 or len(keyList[i]) == 0:
			print '==============='
			print varList[i]
			raise Exception("column %d is invalid!" % i)
		if varList[i][0] == '_':
			ignoreList[i] = True
			continue
		if varFilter and re.search(varFilter, varList[i]):
			# print varList[i], '字段忽略'
			ignoreList[i] = True

	defList = defList[:len(varList)]
	defList = [None if len(x) == 0 else x for x in defList]
	if len(varList) != len(defList):
		defList += [None] * (len(varList) - len(defList))

	# 忽略第一列为空的行
	validLines = []
	for line in lines:
		valueList = splitLine(line)
		if len(valueList[0]) == 0:
			continue
		validLines.append(valueList)

	# 组装字符串矩阵
	validMat = [[None for col in xrange(len(keyList))] for row in xrange(len(validLines))]
	for row in xrange(len(validLines)):
		for col in xrange(len(keyList)):
			if col >= len(validLines[row]):
				break
			if ignoreList[col]:
				continue
			# 空串设置为None，如果真需要空串，要使用LUA_STRING方式定义''
			if len(validLines[row][col]) == 0:
				continue
			validMat[row][col] = validLines[row][col]

	# 去除注释列
	for i in xrange(len(ignoreList) - 1, 0, -1):
		if not ignoreList[i]:
			continue
		# print 'ignore', varList[i]
		del keyList[i]
		del varList[i]
		del defList[i]
		for row in xrange(len(validMat)):
			del validMat[row][i]

	# 判断列数据类型
	for col in xrange(len(keyList)):
		luaType = 0
		# 先获取默认值的lua type
		if (col != 0) and (not defList[col] is None):
			luaType = whatType(defList[col])
		for row in xrange(len(validMat)):
			if validMat[row][col] == None:
				continue
			elemType = whatType(validMat[row][col])
			luaType = max(luaType, elemType)
		# 空列忽略
		# if luaType == 0:
		# 	raise Exception('column [%d] %s can not be recognize!' % (col, keyList[col]))
		keyList[col] = (keyList[col], varList[col], luaType, defList[col])

	# 第一列不需要变量名和默认值
	luaType = keyList[0][2]
	keyList[0] = (keyList[0][0], None, luaType, None)

	# 第一列只能是整数
	if not keyList[0][2] in (LUA_NUM,):
		raise Exception('first column must be number, now is %d!' % keyList[0][2])

	# debug
	# for i in keyList:
	# 	print i[0], i[1]
	# print keyList

	return keyList, validMat, defList

def autoMake(s):
	# print 'autoMake',repr(s)
	luaType = whatType(s)
	return makeElem(luaType, s)

DELIM_MATCH = {'"':'"', "'":"'", '<':'>', '{':'}'}
RECUR_MATCH = ('<', '{')

def makeArray(s):
	# print 'makeArray', s
	s = s.strip()[1:-1]
	delim, part, array = [], '', []
	for i in s:
		part += i
		# print i, delim
		if len(delim) > 0:
			if i == delim[-1]:
				del delim[-1]
			elif i in RECUR_MATCH:
				delim.append(DELIM_MATCH[i])
		elif i in DELIM_MATCH:
			delim.append(DELIM_MATCH[i])
		elif i == ';':
			array.append(autoMake(part[:-1]))
			part = ''
	if len(part) > 0:
		array.append(autoMake(part))

	# print array
	# for i in xrange(len(array)):
	# 	part = ['\t' + x for x in array[i].split('\r\n')]
	# 	array[i] = '\r\n'.join(part)
	# ret = '{\r\n%s\r\n}' % ',\r\n'.join(array)

	# nilLen = 0
	# for i in xrange(len(array)):
	# 	if array[i] is None:
	# 		nilLen += 1
	# if nilLen == len(array):
	# 	return None

	# array中间为空的需要保留nil
	array = [LUA_NIL_VALUE if x is None else x for x in array]
	ret = LUA_ARRAY_FUNC(array)
	# print ret
	return ret


def makeMap(s):
	# print 'makeMap', s
	s = s.strip()[1:-1]
	delim, part, array = [], '', []
	for i in s:
		part += i
		# print i, delim
		if len(delim) > 0:
			if i == delim[-1]:
				del delim[-1]
			elif i in RECUR_MATCH:
				delim.append(DELIM_MATCH[i])
		elif i in DELIM_MATCH:
			delim.append(DELIM_MATCH[i])
		elif i == ';':
			array.append(part[:-1])
			part = ''
	if len(part) > 0:
		array.append(part)

	mapp = {}
	cnt = 0
	for i in array:
		if len(i.strip()) == 0:
			continue
		pos = i.find('=')
		if pos == -1:
			raise Exception('map k-v must be split by "="!')
		k, v = i[:pos], i[pos+1:]
		kType = whatType(k)
		if (kType != LUA_NUM) and (kType != LUA_STRING):
			raise Exception('key must be integer or string!')
		k, v = autoMake(k), autoMake(v)
		if v is None:
			continue
		if k in mapp:
			raise Exception('map key %s deuplicated!' % k)
		mapp[k] = LUA_MAP_KV_FUNC(k, v)
		cnt += 1

	# if 0 == len(mapp):
	# 	return None

	if cnt != len(mapp):
		raise Exception('map key deuplicated!')

	ret = LUA_MAP_FUNC(mapp.values())
	# print ret
	return ret


def splitFilePath(filePath):
	filePath = os.path.splitdrive(filePath)[1]
	(filePath, fileName) = os.path.split(filePath)
	dirList = []
	while len(filePath) > 0:
		(filePPath, dirName) = os.path.split(filePath)
		if filePPath == filePath:
			break
		filePath = filePPath
		dirList.append(dirName)
	dirList.reverse()
	return dirList, fileName

# 现在只有csv配表内LUA_CSV数值是相对目录
# 生成文件时是完整路径，g_luaTableMap遇到完整路径时认为是生成文件
# @return csv路径前缀构造，csv路径，csv引用路径
def makeCsvVar(fileName, isRel = False):
	fileName = fileName.replace('\\', '/')
	fileName = os.path.normpath(fileName)
	if not isRel:
		fileName = os.path.relpath(fileName, SRC_PATH)
	dirList, fileName = splitFilePath(fileName)
	fileName = fileName[:-4]
	if len(dirList) == 0:
		g_luaTableMap[LUA_MODULE_NAME + "." + fileName] = True
		return '', LUA_DIR_FUNC(LUA_MODULE_NAME, fileName), LUA_MODULE_NAME + "." + fileName

	varPerList = []
	dirList.append(fileName)
	varName = LUA_MODULE_NAME
	luaVarPath = LUA_MODULE_NAME
	for i in xrange(0, len(dirList)):
		if luaVarPath not in g_luaTableMap:
			varPerList.append("%s = {}\r\n" % varName)
			if not isRel:
				g_luaTableMap[luaVarPath] = True
		varName = LUA_DIR_FUNC(varName, dirList[i])
		# varName = varName + "['%s']" % dirList[i]
		luaVarPath = luaVarPath + '.' + dirList[i]
	return "".join(varPerList), varName, LUA_CSV_FUNC([LUA_MODULE_NAME] + dirList)

def makeDef(keyList, defList):
	elem = []
	defs = [None for i in defList]
	idx = 0
	for keyT in keyList[1:]:
		name, varName, luaType, defVar = keyT
		idx += 1

		if PY_NAMETUPLE:
			if defVar is None:
				elem.append(LUA_ELEM_KV_FUNC(varName, None))
				continue
			value = makeElem(luaType, defVar)
			elem.append(LUA_ELEM_KV_FUNC(varName, value))
			defs[idx] = value

		else:
			if defVar is None:
				continue
			value = makeElem(luaType, defVar)

			if value is None:
				continue
			elem.append(LUA_ELEM_KV_FUNC(varName, value))
			defs[idx] = value
	# elem = ',\r\n\t\t\t'.join(elem)
	return elem, defs

def makeElem(luaType, strValue):
	# print 'makeElem', luaType, strValue

	ret = None
	if luaType == LUA_NIL:
		return None
	elif luaType == LUA_BOOL:
		if strValue in ('true', 'True', 'TRUE'):
			ret = LUA_TRUE_VALUE
		else:
			ret = LUA_FALSE_VALUE
	elif luaType == LUA_NUM:
		ret = strValue.strip()
	elif luaType == LUA_STRING:
		# csv """" -> str " -> val '"'
		# csv """""" -> str "" -> val ''
		# csv """1    2""" -> str "1    2" -> val '1    2'
		# csv """1    2""3" -> str "1    2"3 -> val '"1    2"3'
		strValue = strValue.strip()
		if strValue[0] == '"' and strValue[-1] == '"':
			strValue = strValue[1:-1].replace('""', '"')
			if len(strValue) > 1 and strValue[0] == '"' and strValue[-1] == '"':
				ret = "'%s'" % strValue[1:-1].replace("'", "\\'")
			else:
				ret = "'%s'" % strValue.replace("'", "\\'")
		elif len(strValue) > 1 and strValue[0] == "'" and strValue[-1] == "'":
			ret = "'%s'" % strValue[1:-1].replace("'", "\\'")
		else:
			ret = "'%s'" % strValue.replace("'", "\\'")

	elif luaType == LUA_CSV:
		_, _, value = makeCsvVar(strValue, True)
		# csv 引用使用字符串，后期在lua延迟调用
		ret = "'%s'" % value
		# print strValue, ret
	elif luaType == LUA_ARRAY:
		ret = makeArray(strValue)
	elif luaType == LUA_MAP:
		ret = makeMap(strValue)
	else:
		raise Exception('luaType %d is invalid!' % luaType)

	# print '->', ret

	# if ret is None:
	# 	raise Exception('makeElem(%d, "%s") is error!' % (luaType, strValue))
	return ret

def makeLua(csvName, keyList, strMat, defList):
	varPreName, varName, varPath = makeCsvVar(csvName)
	defElems, defvList = makeDef(keyList, defList)

	data = []
	for row in xrange(len(strMat)):
		elem = []
		elemLine = strMat[row]
		try:
			for col in xrange(1, len(keyList)):
				luaType = keyList[col][2]
				value = elemLine[col]

				if PY_NAMETUPLE:
					# 没有值
					if value is None:
						value = None
					else:
						# array和map可能返回None，相当于LUA_NIL
						value = makeElem(luaType, value)

						# 等于默认值时优化
						if value == defvList[col]:
							value = None

				else:
					# 无数据，并且无默认值，跳过生成
					if (elemLine[col] is None) and (defvList[col] is None):
						continue

					# 没有值
					if value is None:
						continue

					# array和map可能返回None，相当于LUA_NIL
					value = makeElem(luaType, value)
					if value is None:
						continue

					# 等于默认值时优化
					if value == defvList[col]:
						continue

				elem.append(LUA_ELEM_KV_FUNC(keyList[col][1], value))
			luaType = keyList[0][2]
			elem = LUA_ROW_FUNC(makeElem(luaType, elemLine[0]), elem)
			data.append(elem)

		except Exception, e:
			exStr = utf2local("异常：%s.csv (%d, %d)\r\n异常行：%s\r\n异常列：%s\r\n\r\n%s" % (csvName, row, col, elemLine, elemLine[col], traceback.format_exc()))
			raise Exception(exStr)

	namedT = ''
	if PY_NAMETUPLE:
		namedT = LUA_MODULE_NAMETUPLE_FUNC(varName, keyList)
	#return varPreName + namedT + LUA_MODULE_FUNC(varName, data, defElems), varPath
	return namedT + LUA_MODULE_FUNC(varName, data, defElems), varPath


def listFiles(rootDir, ext = None):
	list_dirs = os.walk(rootDir)
	list_ret = []
	for root, dirs, files in list_dirs:
		for f in files:
			pf = os.path.join(root, f)
			if not ext is None:
				if not f.endswith(ext):
					# print pf, '文件忽略'
					continue
			flag = True
			for reF in IGNORE_FILES:
				if re.search(reF, pf):
					print pf, '文件忽略'
					flag = False
					break
			if flag:
				list_ret.append(pf)
	return list_ret

def normalPaths(fileLst, rootDir):
	return [os.path.join(rootDir, i) for i in fileLst]

def getDirFiles(rootDir,module):
	list_dirs = os.listdir(rootDir)
	varPerList = []
	for Dir in list_dirs:
		path1 = os.path.join(rootDir,Dir)
		if os.path.isdir(path1) and path1.endswith(".svn") == False:
			varName = LUA_DIR_FUNC(module, Dir)
			varPerList.append("%s = {}\r\n" % varName)
			varPerList.append(getDirFiles(path1,varName))
	return "".join(varPerList)

def writeSrc(luaSrc):
	if FOR_LUA:
		luaSrc = ['require "%s"' % f for f in luaSrc]
		luaSrc = '\r\n'.join(luaSrc)

	else:
		luaSrc = '\r\n'.join(luaSrc)

	# gbk to utf8
	dirFiles = getDirFiles(SRC_PATH, LUA_MODULE_NAME)
	luaSrc = LUA_HEAD_SRC + LUA_OTHER_SRC + ("%s = {}\r\n" % LUA_MODULE_NAME) + dirFiles + luaSrc + LUA_OTHER_SRC2
	luaSrc = luaSrc.decode('gbk').encode('utf8')

	fp = open(LUA_FILE_NAME, 'wb')
	fp.write(luaSrc)
	fp.close()

def writeOneSrc(luaSrc, fileName):
	try:
		path = os.path.dirname(fileName)
		if path:
			os.makedirs(path)
	except:
		pass

	# gbk to utf8
	luaSrc = '\r\n'.join(luaSrc)
	luaSrc = LUA_HEAD_SRC + luaSrc
	luaSrc = luaSrc.decode('gbk').encode('utf8')

	fp = open(fileName, 'wb')
	fp.write(luaSrc)
	fp.close()


def main():
	global g_luaTableMap
	g_luaTableMap = {}

	print utf2local('csv2src工作目录：'), os.getcwd()
	print utf2local('csv2src配置源目录：'), SRC_PATH

	fileList = normalPaths(SRC_FILE_LIST, SRC_PATH) if SRC_FILE_LIST else listFiles(SRC_PATH, '.csv')
	luaSrc = []

	for fileName in fileList:
		fp = open(fileName, 'rb')
		lines = fp.readlines()
		fp.close()

		if len(lines) <= 2:
			continue

		if lines[0].split(',')[0].strip() != utf2gbk('变量名'):
			print fileName, utf2local('第一行不是“变量名”，文件无法被生成！')
			continue

		# 默认值，该行可有可无
		beginLine, defs = 1, ''
		if lines[1].split(',')[0].strip() == utf2gbk('默认值'):
			defs = lines[1]
			beginLine = 2

		g_luaTableMap[LUA_MODULE_NAME] = True
		try:
			luaCsv, luaPath = makeLua(fileName, *parseCsv(fileName, lines[beginLine], lines[0], defs, lines[beginLine+1:]))
			# print luaPath
			# print luaCsv
			luaOneSrc = []
			if FOR_LUA:
				luaOneSrc.append(luaCsv)
				# lua使用单文件形式
				tmp = path = os.path.normpath(os.path.dirname(LUA_FILE_NAME))
				paths = []
				while tmp:
					tmp, d = os.path.split(tmp)
					paths.append(d)
				luaSrc.append('.'.join(paths) + luaPath[3:])
				luaPath = luaPath.replace('.', '/')[4:] + '.lua'
				luaPath = os.path.join(path, luaPath)
				writeOneSrc(luaOneSrc, luaPath)

			# no for lua
			else:
				luaSrc.append(luaCsv)

			#print fileName, utf2local('文件生成完毕.')

		except Exception, e:
			print '[', '-'*50, 'begin exception'
			# print lines
			print e
			traceback.print_exc()
			print '-'*50, ']', 'end exception'
			print fileName, utf2local('文件无法被生成！')

	writeSrc(luaSrc)
	print LUA_FILE_NAME, 'finished'


if __name__ == '__main__':

	if FOR_LUA:
		try:
			shutil.rmtree('./config')
		except Exception, e:
			pass

	try:
		os.remove(LUA_FILE_NAME)
	except Exception, e:
		pass

	main()



