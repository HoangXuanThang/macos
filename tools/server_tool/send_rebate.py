#!/usr/bin/python
# -*- coding: utf-8 -*-

import redis
import time
import defines
import itertools
import msgpackrpc
from collections import namedtuple

import db.redisorm as rom
import db.scheme.game as DBGame
import db.scheme.account as DBAccount

redisConfig = {
	'host': '0.0.0.0',
	'port': 12345,
	'db': 0,
	# 'password': 'hzyoumiheat02redis01',
}
redisConfigAccount = {
	'host': '0.0.0.0',
	'port': 12345,
	'db': 1,
	# 'password': 'hzyoumiheat02redis01',
}

print time.time(), redisConfig, redisConfigAccount

__csv_recharges_ = namedtuple('__csv_recharges_', ['icon','name','numIcon','type','param','rmbDisplay','rmb','firstPresent','firstDesc','present','desc','recommend'])

csv = {
	1 : __csv_recharges_('Resources/ICON/PAY-BS01.png', '250钻石月卡包', None, 2, {'days' : 31}, 0, 250, None, '连续30天每天领取100钻', None, '连续30天每天领取100钻', 1),
	2 : __csv_recharges_('Resources/ICON/PAY-BS01.png', '880钻石终身卡', None, 2, {'days' : 31}, 0, 880, None, '运营期间每天领取100钻', None, '运营期间每天领取100钻', 1),
	3 : __csv_recharges_('Resources/00ShuMa/CZ_res/cz_pic_zuan6.png', '6480钻石', 'Resources/00ShuMa/CZ_res/num1.png', None, None, 648, 6480, 6480, '另赠6480钻(仅首次)', None, None, 1),
	4 : __csv_recharges_('Resources/00ShuMa/CZ_res/cz_pic_zuan5.png', '3280钻石', 'Resources/00ShuMa/CZ_res/num2.png', None, None, 328, 3280, 3280, '另赠3280钻(仅首次)', None, None, 1),
	5 : __csv_recharges_('Resources/00ShuMa/CZ_res/cz_pic_zuan4.png', '1980钻石', 'Resources/00ShuMa/CZ_res/num3.png', None, None, 198, 1980, 1980, '另赠1980钻(仅首次)', None, None, 1),
	6 : __csv_recharges_('Resources/00ShuMa/CZ_res/cz_pic_zuan3.png', '980钻石', 'Resources/00ShuMa/CZ_res/num4.png', None, None, 98, 980, 980, '另赠980钻(仅首次)', None, None, None),
	7 : __csv_recharges_('Resources/00ShuMa/CZ_res/cz_pic_zuan2.png', '600钻石', 'Resources/00ShuMa/CZ_res/num5.png', None, None, 60, 600, 600, '另赠600钻(仅首次)', None, None, None),
	8 : __csv_recharges_('Resources/00ShuMa/CZ_res/cz_pic_zuan1.png', '300钻石', 'Resources/00ShuMa/CZ_res/num6.png', None, None, 30, 300, 300, '另赠300钻(仅首次)', None, None, None),
	9 : __csv_recharges_('Resources/00ShuMa/CZ_res/cz_pic_zuan1.png', '60钻石', 'Resources/00ShuMa/CZ_res/num7.png', None, None, 6, 60, None, None, None, None, None),
	'__default' : __csv_recharges_(None, None, '', 1, {}, None, None, 0, None, 0, None, 0)
}

vipLevel = [
0,
60,
300,
600,
1000,
2000,
3000,
5000,
7000,
10000,
15000,
20000,
30000,
60000,
120000,
200000,
]

def read_prev_rmb():
	rom.util.set_connection_settings(**redisConfig)
	r = rom.util.get_connection()

	print '-'*20

	maxRoleID = DBGame.Role.get_primary_max()
	accountMap = {}
	rmbSum = 0
	roleCnt = 0

	for i in xrange(maxRoleID):
		role = DBGame.Role.get(i)
		try:
			if role:
				roleCnt += 1
				isRMB = False
				rD = {}
				for k, d in role.recharges.iteritems():
					if k < 3: # 月卡自动激活
						continue
					orders = d.get('orders', [])
					cnt = 0
					for x in orders:
						if x != -1: # -2是qq补齐
							isRMB = True
							cnt += 1
					rD[k] = cnt
				if not isRMB:
					continue

				rmb = 0
				for k, cnt in rD.iteritems():
					rmb += csv[k].rmb * cnt
				rmbSum += rmb
				accountMap[role.account_id] = [role.vip_level, rmb, role.id, role.name, role.level]
		except:
			print role.recharges
			raise

	print len(accountMap), roleCnt, rmbSum

	rom.util.set_connection_settings(**redisConfigAccount)
	r = rom.util.get_connection()

	for accountID, l in accountMap.iteritems():
		account = DBAccount.Account.get(accountID)
		if account:
			l.append(account.name)

	with open('rebate.txt', 'wb') as fp:
		fp.write(str(accountMap))

	print 'read ok'


def send_mail():
	rom.util.set_connection_settings(**redisConfig)
	r = rom.util.get_connection()

	rpc = msgpackrpc.Client(address=msgpackrpc.Address('192.168.1.125', 25551))

	print '-'*20

	with open('rebate.txt', 'rb') as fp:
		s = fp.read()
		accountMap = eval(s)

	sender = '天女兽'
	subject = '删档测试充值双倍返还'
	content = '''#C0xffe672#F24#亲爱的驯兽师们:\n    \n   《数码宝贝大冒险》在你们的支持下，终于迎来了不删档测试。为了回馈曾与我们一起奋斗在数码世界的驯兽师们，现特此对您在删档期间的充值金额进行双倍返还（赠送钻石不在返还范围内，双倍返还只能在一区领取）。\n    被选召的孩子，开启冒险之旅吧！\n    《数码宝贝大冒险》运营组
'''

	for accountID, l in accountMap.iteritems():
		vip = l[0]
		rmb = l[1]
		channelID = l[-1]
		if rmb-vipLevel[vip] < 0:
			oldvip = vip
			oldstep = rmb-vipLevel[vip]
			for i, s in enumerate(vipLevel):
				if s > rmb:
					vip = i-1
					break
			print '-'*10
			print 'warning', accountID, oldstep, oldvip, (rmb, vip), l, l[3]
			role = DBGame.Role.get(l[2])
			if role:
				print role.recharges
			if rmb-vipLevel[vip] < 0:
				print rmb, vip
				raise Exception('error in vip')
		rpc.call('gmSendNewbieMail', channelID, 22, sender, subject, content, {'vip': vip, 'vip_exp': rmb-vipLevel[vip], 'rmb': rmb*2})

	vip = 4
	rmb = 1234
	rpc.call('gmSendNewbieMail', 'test_hw', 22, sender, subject, content, {'vip': vip, 'vip_exp': rmb-vipLevel[vip], 'rmb': rmb*2})

	print 'send ok'


if __name__ == '__main__':
	import sys
	if len(sys.argv) >= 2:
		if sys.argv[1].lower() == 'read':
			read_prev_rmb()
		elif sys.argv[1].lower() == 'send':
			send_mail()