#!/usr/bin/python
# -*- coding: utf-8 -*-

import db.defines as defines
import db.redisorm as rom
import db.scheme.account as DBAccount
import db.scheme.game as DBGame
import db.scheme.pvp as DBPVP
import datetime

def del_mail(servName):
	conf = defines.ServerDefs[servName]['redis']
	# conf['host'] = '182.254.241.252'
	# conf['port'] += 1 # use slave
	print '-' * 10
	print servName, conf

	rom.util.set_connection_settings(**conf)
	r = rom.util.get_connection()

	idMax = DBGame.Mail.get_primary_max()
	cnt = DBGame.Mail.query.filter(deleted_flag=True).count()
	print 'mail', DBGame.Mail.get_count(), 'deleted mail', cnt
	if cnt < 1000:
		return
	c = 0
	for i in xrange(idMax):
		try:
			mail = DBGame.Mail.get(i)
			if not mail.deleted_flag:
				rom.session.forget(mail)
				continue
		except:
			continue
		# print '[DEL] mail', mail.id, mail.deleted_flag, mail.role_db_id, mail.time
		mail.delete()
		c += 1
		if c % 1000 == 0:
			print servName, 'delete mail', c, '/', cnt
	print 'mail', DBGame.Mail.get_count(), 'deleted mail', DBGame.Mail.query.filter(deleted_flag=True).filter(role_db_id=(1, '+inf')).count()


def del_pvp_play(servName):
	conf = defines.ServerDefs[servName]['redis']
	# conf['port'] += 1 # use slave
	print '-' * 10
	print servName, conf

	rom.util.set_connection_settings(**conf)
	r = rom.util.get_connection()

	idMax = DBPVP.PVPPlayRecord.get_primary_max()
	cnt = DBPVP.PVPPlayRecord.query.filter(date=('-inf', 20170101)).count()
	print 'play', DBPVP.PVPPlayRecord.get_count(), 'old', cnt
	if cnt < 1000:
		return
	c = 0
	for i in xrange(idMax):
		try:
			play = DBPVP.PVPPlayRecord.get(i)
			if play.date > 20170101:
				rom.session.forget(play)
				continue
		except:
			continue
		# print '[DEL] play', play.id, play.deleted_flag, play.role_db_id, play.time
		play.delete()
		c += 1
		if c % 1000 == 0:
			print servName, 'delete play', c
	print 'play', DBPVP.PVPPlayRecord.get_count(), 'old', DBPVP.PVPPlayRecord.query.filter(date=('-inf', 20170101)).count()


def main():
	for i in xrange(97, 97+8):
		del_mail('game_qq%02d' % i)
		del_pvp_play('game_qq%02d' % i)

if __name__ == '__main__':
	main()