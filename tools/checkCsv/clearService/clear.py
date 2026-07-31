 #coding=utf-8
 # 清理 service.csv 配表中过期时间的配置，保留最近一次过期的配置

import os
import re
import sys
import datetime
import xlrd
from xlrd import *
import codecs
from collections import defaultdict
import tjutil
import argparse
import csv

checkServiceKeys = ['crosscraft', 'crossgym', 'crossmine', 'crossarena']

# 使得 sys.getdefaultencoding() 的值为 'utf-8'
reload(sys)                      # reload 才能调用 setdefaultencoding 方法
sys.setdefaultencoding('utf-8')  # 设置 'utf-8'


basePath =  os.path.dirname(os.path.abspath('__file__'))
basePath = basePath.replace('\\',"/")

def readCsv(fileName):
	ret = []
	with open(fileName, 'rb') as csvfile:
		spamreader = csv.reader(csvfile, delimiter=' ', quotechar='|')
		for row in spamreader:
			ret.append(','.join(row))
	return ret

def main():
	parser = argparse.ArgumentParser(prog='clear_service', description='clear service.csv')
	parser.add_argument('-p', dest='service_path', help=tjutil.utf2local('配表service的路径'))
	args = parser.parse_args(sys.argv[1:])
	print args

	# 升级一下pip的版本 低版本有些库没有
	os.popen('python pip install --upgrade pip')
	csvFilePath = basePath
	if args.service_path:
		csvFilePath = csvFilePath + "/" + args.service_path
	else:
		csvFilePath = csvFilePath + "/service.csv"
	print "path:", csvFilePath
	if not os.path.exists(csvFilePath):
		print "not service.csv exist!"
		return
	csvData = readCsv(csvFilePath)

	now = datetime.datetime.now()
	curDate = now.strftime('%Y%m%d')

	# print curDate, csvData[:100], len(csvData)

	print "check len:", len(csvData)
	dataMap = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
	for i in xrange(3, len(csvData)):
		lineMap = csvData[i].split(",")
		service, date, cross = lineMap[1], lineMap[3], lineMap[4]
		if service:
			crossMap = cross.split(".")
			if len(crossMap) > 1:
				cross = crossMap[1]
			dataMap[service][cross][date].append(i)
			# print i, service, date, cross, date < curDate

	deleteLines = []
	for service, serviceMap in dataMap.items():
		if service in checkServiceKeys:
			for cross, crossMap in serviceMap.items():
				# print cross, crossMap
				if cross != "dev":
					sortCrossList = sorted(crossMap.items(), reverse=True)
					flag = False # 标记是否后续的小于当前日期
					for i in xrange(0, len(sortCrossList)):
						date, dateList = sortCrossList[i][0], sortCrossList[i][1]
						if flag:
							for line in dateList:
								deleteLines.append(line)
						else:
							if date < curDate:
								flag = True

	newFile = None
	deleteCount = 0
	for i in xrange(0, len(csvData)):
		if i in deleteLines:
			lineMap = csvData[i].split(",")
			service, date, cross = lineMap[1], lineMap[3], lineMap[4]
			print "deleteLine:", i, service, date, cross
			deleteCount = deleteCount + 1
		else:
			if newFile == None:
				newFile = open(csvFilePath, "w")
			newFile.write(csvData[i] + '\n')
	if newFile != None:
		newFile.close()

	if deleteCount == 0:
		print "no change service"
	else:
		print "delete total count:", deleteCount

if __name__ == '__main__':
	try:
		main()

	except BaseException,e:
		print "error",str(e)
		raise
		append
