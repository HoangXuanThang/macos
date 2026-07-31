#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import

from framework.helper import ClassProperty

import os
import sys
import time
import copy
import functools

class Csv(object):
	dic = None
	Version = 0
	DictCache = {}

	@classmethod
	def load(cls):
		if Csv.dic:
			return

		import framework
		import framework.csv2py.csv2src
		import framework.csv2py.pyservcfg
		from framework.log import logger

		csv2src = framework.csv2py.csv2src
		cfg = framework.csv2py.pyservcfg

		try:
			os.remove(cfg.LUA_FILE_NAME + 'c')
		except Exception, e:
			pass
		try:
			os.remove(cfg.LUA_FILE_NAME + 'o')
		except Exception, e:
			pass

		# 开发期判断模块为py时自动生成csv
		# 打包后模块为pyc，不自动生成csv
		if hasattr(framework, '__dev__'):
			if hasattr(framework, '__dev_config__'):
				cfg.SRC_PATH = framework.__dev_config__

			logger.info('Python Csv generated %s %s %s', cfg.__doc__, cfg.LUA_FILE_NAME, cfg.SRC_PATH)

			try:
				os.remove(cfg.LUA_FILE_NAME)
			except Exception, e:
				pass

			# import gc
			# gc.collect()
			# print 111111111111,process_info()

			csv2src.__dict__.update(cfg.__dict__)
			csv2src.main()

			cfg = None
			csv2src = None

		# gc.collect()
		# print 222222222222,process_info()

		import config_csv
		_csv = reload(config_csv)
		Csv.dic = _csv.csv

		# gc.collect()
		# print 33333333333,process_info()

	@classmethod
	def reload(cls):
		global csv
		from framework.log import logger

		oldID = id(Csv.dic)
		logger.info('CSV reload before, %d %d %d' % (cls.Version, id(csv.dic), id(Csv.dic)))
		Csv.dic = None
		Csv.load()
		csv.reset() # global csv地址不变，更改成员
		ErrDefs.classInit()
		L10nDefs.classInit()
		Csv.refreshCache()
		logger.info('CSV reload after, %d %d %d' % (cls.Version, id(csv.dic), id(Csv.dic)))
		if oldID == id(Csv.dic):
			logger.warning('CSV reload may be failed!')

	@classmethod
	def refreshCache(cls):
		global csv

		cls.Version = int(time.time() - 1400000000)
		cls.DictCache = {'yunying': csv.yunying.to_dict()}

	@classmethod
	def isCSV(cls, val):
		return isinstance(val, str) and (val[:4] == 'csv[' or val[:4] == 'csv.')

	@classmethod
	def getCSV(cls, val):
		if not cls.isCSV(val):
			raise ValueError('It is not CSV value.')
		return eval(val)

	@classmethod
	def _r_to_dict(cls, dic, defDic):
		if hasattr(dic, '_fields'):
			d = dict(zip(dic._fields, dic))
			if defDic:
				for k in d:
					if d[k] is None:
						d[k] = getattr(defDic, k)
			return d

		d = copy.copy(dic)
		if not isinstance(d, dict):
			return d

		ddef = d.pop('__default', None)
		for k in d:
			d[k] = cls._r_to_dict(d[k], ddef)
		return d

	@property
	def id(self):
		return self.myID

	def __init__(self, myID = None, dic = None, defDic = None):
		if dic is not None:
			self.rawSetAttr('dic', dic)
			self.rawSetAttr('defDic', defDic)
		else:
			Csv.load()
			self.rawSetAttr('dic', Csv.dic)
			self.rawSetAttr('defDic', None)

		if myID is not None:
			try:
				myID = int(myID)
				if myID <= 0:
					myID = None
			except ValueError:
				myID = None
		self.rawSetAttr('myID', myID)
		self.rawSetAttr('odic', {})


	def to_dict(self):
		return self._r_to_dict(self.dic, self.defDic)

	def reset(self):
		self.rawSetAttr('dic', Csv.dic)
		self.rawSetAttr('defDic', None)
		self.rawSetAttr('myID', None)
		self.rawSetAttr('odic', {})

	def keys(self):
		if isinstance(self.dic, dict):
			keyL = self.dic.keys()
			if '__default' in keyL:
				keyL.remove('__default')
			return keyL
		return self.dic._fields

	def __len__(self):
		if isinstance(self.dic, dict):
			return len(self.dic) - (1 if '__default' in self.dic else 0)
		return len(self.dic._fields)

	def __iter__(self):
		return iter(self.keys())

	def __getitem__(self, key):
		return self.__getattr__(key)

	def __setitem__(self, key, message):
		raise AttributeError('Csv can not be set item!')

	def __getattr__(self, name):
		val = None
		if name in self.odic:
			val = self.odic[name]
		elif isinstance(self.dic, dict):
			if name in self.dic:
				val = self.dic[name]
				val = Csv(name, val, self.dic.get('__default', None))
				self.odic[name] = val
		else:
			val = getattr(self.dic, name)
			if val is None and self.defDic:
				val = getattr(self.defDic, name)
		return val

	def __setattr__(self, name, value):
		raise AttributeError('Csv can not be set attr!')

	def rawSetAttr(self, name, value):
		self.__dict__[name] = value


class ErrDefs(object):
	@classmethod
	def classInit(cls):
		for id in csv.error_text:
			cfg = csv.error_text[id]
			if cfg.var:
				setattr(cls, cfg.var, str(id))

class L10nDefs(object):
	@classmethod
	def classInit(cls):
		import framework
		field = 'text'

		for id in csv.language:
			cfg = csv.language[id]
			if cfg.key:
				def fget(cfg, cls):
					raw = getattr(cfg, field)
					if framework.__language__ != 'cn':
						field2 = '%s_%s' % (field, framework.__language__)
						return getattr(cfg, field2, raw)
					return raw
				setattr(cls, cfg.key, ClassProperty(functools.partial(fget, cfg)))


csv = Csv()
csv.refreshCache()
ErrDefs.classInit()
L10nDefs.classInit()

# print L10nDefs.WorldServerMaintain