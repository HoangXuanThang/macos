#!/usr/bin/python
# -*- coding: utf-8 -*-

import db.defines as defines
import db.redisorm as rom
import db.scheme.account as DBAccount
import db.scheme.game as DBGame
import datetime

def main():
	names = ['game_qq12']
	for servName in names:
		conf = defines.ServerDefs[servName]['redis']
		conf['port'] += 1 # use slave

		rom.util.set_connection_settings(**conf)
		r = rom.util.get_connection()

		print '-'*20, servName
		mMax = DBGame.Union.get_primary_max()
		for i in xrange(mMax):
			union = DBGame.Union.get(i)
			if union:
				print union.id, union.name, union.level, union.chairman_db_id, len(union.members)

		rom.session.rollback()

if __name__ == '__main__':
	main()