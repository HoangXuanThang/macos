#!/usr/bin/python
# -*- coding: utf-8 -*-

import db.defines as defines
import db.redisorm as rom
import db.scheme.account as DBAccount
import db.scheme.game as DBGame
import datetime

def main():
	conf = defines.ServerDefs['game_qq01']['redis']
	conf['port'] += 1 # use slave

	rom.util.set_connection_settings(**conf)
	r = rom.util.get_connection()

	mMax = DBGame.Mail.get_primary_max()
	for i in xrange(mMax):
		mail = DBGame.Mail.get(i)
		if mail and mail.role_db_id == 11018:
			t = datetime.datetime.fromtimestamp(mail.time)
			print mail.id, mail.role_db_id, mail.sender, mail.subject, t

if __name__ == '__main__':
	main()