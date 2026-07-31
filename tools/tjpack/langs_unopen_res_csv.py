#!/usr/bin/python
# -*- coding: utf-8 -*-
#

import os
import csv
from collections import namedtuple

import tjlog
import tjutil

# 18M     ./src
# 132K    ./updater
# 128K    ./res/shader
# 9.7M    ./res/video
# 81M     ./res/sound
# 4.6M    ./res/uijson
# 238M    ./res/spine
# 193M    ./res/resources
# 828K    ./res/img
# 527M    ./res
# 308K    ./cocos
# 545M    .


####
# unit.csv
####
# icon
# cardIcon
# cardIcon2
# iconSimple
# cardShow
# unitRes
# show

####
# skill.csv
####
# sound	{res=hero_sound/miaowazhongzi_skill1.mp3;loop=0;delay=0}


CSV_PATH = tjutil.abspath('../../config/game/')
UNOPEN_CSV_PATH = tjutil.abspath('./patch_pack/langs_unopen_res.csv')
UNOPEN_CSV_ROW = ("path", "languages", "name", "type", "source")
UNIT_PNG_FIELDS = ("icon", "cardIcon", "cardIcon2", "iconSimple", "cardShow", "show")


def readCSV(name):
	path = os.path.join(CSV_PATH, name)
	index = {}
	content = {}
	with open(path, 'rb') as csvfile:
		dialect = csv.Sniffer().sniff(csvfile.read(1024))
		csvfile.seek(0)
		reader = csv.reader(csvfile, dialect)
		for i, row in enumerate(reader):
			if i == 0:
				for j, field in enumerate(row):
					index[field] = j
				continue
			if i < 3:
				continue
			id = row[0]
			if id == "":
				continue
			row[0] = int(id)
			content[int(id)] = row
	return index, content


def getUnitRes(languages, row, index):
	ret = []
	unitName = row[index['name']]
	path = row[index['unitRes']].strip()
	if path:
		ret.append({
			"path": path,
			"languages": languages,
			"name": unitName,
			"type": "spine",
			"source": "unit.unitRes",
		})

	for field in UNIT_PNG_FIELDS:
		path = row[index[field]].strip()
		if path:
			ret.append({
				"path": path,
				"languages": languages,
				"name": unitName,
				"type": "png",
				"source": "unit." + field,
			})
	return ret


def getSkillRes(languages, row, index):
	ret = []
	sound = row[index['sound']]
	skillName = row[index['skillName']].strip()
	if sound:
		path = None
		paths = sound[1:-1].split(";")
		for i in paths:
			if "hero_sound" in i:
				path = i.split("=")[1]
				break
		ret.append({
			"path": path,
			"languages": languages,
			"name": skillName,
			"type": "mp3",
			"source": "skill.sound",
		})
	return ret


def getAllLangsRes():
	tjlog.info('**** getAllLangsRes ****')
	langs = []
	# cards.csv
	#   unit.csv
	#   skill.csv
	unitIDSet = set()
	cardsIndex, cardsContent = readCSV('cards.csv')
	unitIndex, unitContent = readCSV('unit.csv')
	skillIndex, skillContent = readCSV('skill.csv')
	for cardID in sorted(cardsContent.keys()):
		card = cardsContent[cardID]
		languages = card[cardsIndex['languages']].strip()
		# default is all
		if languages == "":
			continue
		# languages = languages[1:-1].split(";")
		unitID = card[cardsIndex['unitID']]
		if unitID in unitIDSet:
			continue
		unitIDSet.add(unitID)

		unitRow = unitContent[int(unitID)]
		unitName = unitRow[unitIndex['name']]
		unitSkillList = unitRow[unitIndex['skillList']]
		tjlog.info(languages, unitName)

		langs += getUnitRes(languages, unitRow, unitIndex)
		if unitSkillList:
			skillList = unitSkillList[1:-1].split(";")
			for skillID in skillList:
				if not skillID:
					continue
				skillID = int(skillID)
				if skillID in skillContent:
					skillRow = skillContent[skillID]
					langs += getSkillRes(languages, skillRow, skillIndex)

	# unlock.csv
	unlockIndex, unlockContent = readCSV('unlock.csv')
	for unlockID in sorted(unlockContent.keys()):
		unlock = unlockContent[unlockID]
		languages = unlock[unlockIndex['languages']].strip()
		feature = unlock[unlockIndex['feature']]
		featureName = unlock[unlockIndex['name']]
		# default is all
		if languages == "" or featureName == "":
			continue
		tjlog.info(languages, feature)
		langs.append({
			"path": feature,
			"languages": languages,
			"name": featureName,
			"type": "ui",
			"source": "unlock",
		})

	return langs


def conv2PathKeyMap(langs):
	m = {}
	for d in langs:
		m[d['path']] = d
	return m


def writeLangsCsv(langs):
	with open(UNOPEN_CSV_PATH, 'wb') as csvfile:
		writer = csv.DictWriter(csvfile, fieldnames=UNOPEN_CSV_ROW)
		writer.writeheader()
		for d in langs:
			writer.writerow(d)


def readLangsCsv():
	tjlog.info('**** readLangsCsv ****')
	langs = []
	with open(UNOPEN_CSV_PATH, 'rb') as csvfile:
		reader = csv.DictReader(csvfile)
		for row in reader:
			langs.append(row)
	return langs


def calcUnopen(language, langs):
	tjlog.info('**** calcUnopen ****', language)
	unopen = []
	for d in langs:
		languages = d["languages"][1:-1].split(";")
		if language not in languages:
			tjlog.info("unopen:", d["path"])
			unopen.append(d)
	return unopen



# NOTE: 如果某个语言没打更新包, 但langs_unopen_res.csv被更新到最新, 会导致有资源遗漏
def publishWithOldPatch(language, oldLangs, newLangs):
	tjlog.info('**** publishWithOldPatch ****')
	publish = []
	mOld = conv2PathKeyMap(oldLangs)
	mNew = conv2PathKeyMap(newLangs)
	for path, oldD in mOld.iteritems():
		languages = oldD["languages"][1:-1].split(";")
		# already open
		if language in languages:
			continue
		flag = False
		# not in new, it mean all languages open
		if path not in mNew:
			flag = True
		else:
			newLanguages = mNew[path]["languages"][1:-1].split(";")
			if language in newLanguages:
				flag = True
		if flag:
			publish.append(oldD)
	return publish


def getPath(d):
	if d["type"] == "spine":
		return os.path.join("res/spine/", os.path.dirname(d["path"])), "dir"
	elif d["type"] == "png":
		if d["path"].startswith("config"):
			return os.path.join("res/resources/", d["path"]), "file"
		assert False
	elif d["type"] == "mp3":
		if d["path"].startswith("hero_sound"):
			return os.path.join("res/sound", d["path"]), "file"
	# TODO:
	elif d["type"] == "ui":
		return "", ""
	assert False



if __name__ == "__main__":
	writeLangsCsv(getAllLangsRes())

	# readLangsCsv()

	# calcUnopen('tw', readLangsCsv())

	# publishWithOldPatch('tw', readLangsCsv(), getAllLangsRes())
