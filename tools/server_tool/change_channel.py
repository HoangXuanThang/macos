#!/usr/bin/python
# -*- coding: utf-8 -*-

import db.defines as defines
import db.redisorm as rom
import db.scheme.account as DBAccount
import db.scheme.game as DBGame
import datetime

# 之前17区：qq_1EA1EC99414BF61458A3E95ED0770CDE
# 现在新区：tc_71242

# 黄鑫1区：
# 之前的号：oppo_97383440
# 现在的号：tc_149333

# 纪毅11区：
# 之前的账号：wx_oUVA1wm1lP3FVA6zhhByy0XGtfHU
# 现在的账号：wx_oUVA1wkiOvFNXlF7ieHA8XJ0B0HI

AccountMap = {
	'mofang_f_166216': 'mofang_f_166219',
}

def change_channel():
	conf = defines.ServerDefs['account_qq']['redis']
	# conf['host'] = '123.207.108.22'
	conf['host'] = '119.28.17.230'
	# conf['port'] += 1 # use slave

	rom.util.set_connection_settings(**conf)
	r = rom.util.get_connection()

	for old, new in AccountMap.iteritems():
		print '-'*20, old, new
		account = DBAccount.Account.get_by(name=old)
		newacc = DBAccount.Account.get_by(name=new)
		if account:
			print 'old===', account.to_dict()
			if newacc:
				print 'be-changed===', newacc.to_dict()
				newacc.name = old + '@'
				newacc.channel = old.split('_')[0]
				newacc.save()

			account.name = new
			account.channel = new.split('_')[0]
			account.save()

			if newacc:
				newacc.name = old
				newacc.save()
		else:
			print 'can not found', old

	rom.session.rollback()


def main():
	conf = defines.ServerDefs['account_qq']['redis']
	conf['host'] = '123.207.108.22'
	conf['port'] += 1 # use slave

	rom.util.set_connection_settings(**conf)
	r = rom.util.get_connection()

	uid2accountid = {}
	for uid in AccountMap:
		account = DBAccount.Account.get_by(name='mofang_f_%d' % uid)
		if account:
			print uid, account.id
			uid2accountid[uid] = account.id

	print uid2accountid
	rom.session.rollback()

	####################
	conf = defines.ServerDefs['game_tw01']['redis']
	conf['host'] = '119.28.61.236'
	conf['port'] += 1 # use slave

	rom.util.set_connection_settings(**conf)
	r = rom.util.get_connection()

	d = {}
	for uid, attachs in AccountMap.iteritems():
		if uid not in uid2accountid:
			print 'err account', uid
			continue

		accid = uid2accountid[uid]
		role = DBGame.Role.get_by(account_id=accid)
		if isinstance(role, list):
			print role
			role = role[0]

		if role:
			print uid, role.account_id, role.id
			d[role.id] = attachs

		else:
			print 'err role', uid, accid

	print d

	rom.session.rollback()


if __name__ == '__main__':
	change_channel()
