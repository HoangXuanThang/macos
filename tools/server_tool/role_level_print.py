#!/usr/bin/python
# -*- coding: utf-8 -*-

import pprint
import msgpack
import datetime
from collections import defaultdict
from Queue import PriorityQueue

def utf2local(s):
	return s.decode('utf8').encode('gbk')

def main():
	import db.defines as defines
	import db.redisorm as rom
	import db.scheme.account as DBAccount
	import db.scheme.game as DBGame

	nameL = ['game_qq159']
	for name in nameL:
		print '-'*20, name

		conf = defines.ServerDefs[name]['redis']
		conf['port'] += 1 # use slave
		print conf

		rom.util.set_connection_settings(**conf)
		r = rom.util.get_connection()

		rMax = DBGame.Role.get_primary_max()
		query = DBGame.Role.query.filter(level=(25, '+inf')).filter(channel='tt')

		for role in query.all():
			print role.id, role.name, role.level, role.vip_level

		rom.session.rollback()
		# rom.session.commit(True, True)

if __name__ == '__main__':
	main()
