#!/usr/bin/python
# -*- coding: utf-8 -*-

import db.defines as defines
import db.redisorm as rom
import db.scheme.account as DBAccount
import db.scheme.game as DBGame
import datetime
import binascii
import md5

from tornado.ioloop import IOLoop
from tornado.gen import coroutine, Return, sleep, moment
from tornado.concurrent import Future
import msgpackrpc
from framework.loop import AsyncLoop


def multi_future(d):
	keys = list(d.keys())
	d = d.values()
	unfinished_d = set(d)

	future = Future()
	if not d:
		future.set_result({} if keys is not None else [])
	def callback(f):
		unfinished_d.remove(f)
		if not unfinished_d:
			result_list = []
			for i in d:
				try:
					result_list.append(i.result())
				except Exception as e:
					result_list.append(e)
			future.set_result(dict(zip(keys, result_list)))
	for f in d:
		f.add_done_callback(callback)
	return future



SessionName = 'fbld_admin'
SessionID = None
class GMRPClient(msgpackrpc.Client):
	def _result_handler(self, result):
		ret, msg, kwargs = result
		if not ret:
			print('_result_handler', result)
			raise Exception(ret)
		return msg

	def call(self, method, *args):
		global SessionID, SessionName
		if SessionID is not None:
			args = (SessionName, SessionID) + args

		ret = None
		try:
			result = self.send_request(method, args).get()
			ret = self._result_handler(result)

		except Exception as e:
			raise

		return ret

	def call_async(self, method, *args):
		global SessionID, SessionName
		if SessionID is not None:
			args = (SessionName, SessionID) + args

		fu = self.send_request(method, args)
		fu.attach_result_handler(self._result_handler)
		return fu



Roles = [
('game_qq01', 12032),
('game_qq06', 11280),
('game_qq04', 12604),
('game_qq08', 24114),
('game_qq01', 27803),
('game_qq04', 14878),
('game_qq05', 10761),
('game_qq08', 18888),
('game_qq01', 10005),
('game_qq01', 31452),
('game_qq01', 12071),
('game_qq03', 11427),
('game_qq01', 20502),
('game_qq08', 19296),
('game_qq01', 15771),
('game_qq07', 10324),
('game_qq02', 11279),
('game_qq08', 15207),
('game_qq01', 46204),
('game_qq03', 12002),
('game_qq01', 50918),
('game_qq02', 21804),
('game_qq01', 56803),
('game_qq03', 12171),
('game_qq01', 10070),
('game_qq01', 13755),
('game_qq08', 22850),
('game_qq08', 26485),
('game_qq04', 15963),
('game_qq08', 24040),
('game_qq01', 11519),
('game_qq02', 13492),
('game_qq01', 12085),
('game_qq02', 18742),
('game_qq01', 36949),
('game_qq07', 15427),
('game_qq01', 11254),
('game_qq06', 14889),
('game_qq01', 10117),
('game_qq01', 20623),
('game_qq01', 10699),
('game_qq01', 39014),
('game_qq01', 10257),
('game_qq01', 10792),
('game_qq01', 11508),
('game_qq07', 14829),
('game_qq05', 18102),
('game_qq07', 16944),
('game_qq01', 12445),
('game_qq02', 21816),
('game_qq01', 32825),
('game_qq02', 14185),
('game_qq01', 10123),
('game_qq03', 16991),
('game_qq01', 10407),
('game_qq07', 12594),
('game_qq01', 40549),
('game_qq03', 19387),
('game_qq01', 19938),
('game_qq02', 12203),
('game_qq01', 12650),
('game_qq02', 10045),
('game_qq01', 22725),
('game_qq02', 10912),
('game_qq11', 17848),
('game_qq11', 20930),
('game_qq13', 10056),
('game_qq15', 18004),
('game_qq10', 17994),
('game_qq09', 19240),
('game_qq15', 10497),
('game_qq15', 18293),
('game_qq13', 19500),
('game_qq15', 16789),
('game_qq11', 23498),
('game_qq12', 21007),
('game_qq11', 10814),
('game_qq09', 16068),
('game_qq10', 10887),
('game_qq10', 15836),
('game_qq10', 26534),
('game_qq13', 12175),
('game_qq11', 24152),
('game_qq13', 11219),
('game_qq14', 13155),
('game_qq09', 21505),
('game_qq10', 13251),
('game_qq09', 17840),
('game_qq13', 11959),
('game_qq09', 12740),
('game_qq12', 12865),
('game_qq12', 23946),
('game_qq16', 12046),
('game_qq09', 28231),
('game_qq13', 11797),
('game_qq14', 12454),
('game_qq10', 17830),
('game_qq15', 12195),
('game_qq10', 21084),
('game_qq14', 13326),
('game_qq15', 13046),
('game_qq09', 11221),
('game_qq10', 16500),
('game_qq16', 12034),
('game_qq12', 11529),
('game_qq12', 14777),
('game_qq10', 12717),
('game_qq16', 19814),
('game_qq13', 12015),
('game_qq15', 14495),
('game_qq11', 13589),
('game_qq15', 20419),
('game_qq13', 10954),
('game_qq16', 11171),
('game_qq14', 10587),
('game_qq16', 10732),
('game_qq11', 17515),
('game_qq16', 16425),
('game_qq12', 14963),
('game_qq15', 20242),
('game_qq13', 14201),
('game_qq14', 11161),
('game_qq09', 20879),
('game_qq09', 24608),
('game_qq12', 15488),
('game_qq09', 10492),
('game_qq11', 17008),
('game_qq13', 19530),
]


def main():
	################ login
	client = GMRPClient(msgpackrpc.Address('123.207.108.22', 23333))
	print client.call('_hello', 1)

	global SessionID, SessionName
	SessionID, permission_level, version = client.call('gmLogin', 'huanxi2394fd79a1ad32ff2e2db603da', SessionName, binascii.hexlify(md5.new('tj_abcx').digest()))

	################ send
	global Roles

	sender = '小秘书'
	subject = '跨服32强布阵异常补偿邮件'
	content = '亲爱的小伙伴:\n    很抱歉由于一些异常原因，导致部分玩家在32强赛时无法布阵，现特此对您进行补偿，补偿内容已随邮件发送，请及时查收。如还有疑问，可联系官方客服公众QQ： 800111308'
	attachs = {911:3, 'gold':300000, 'coin4':100}

	fus = {}
	for servName, roleID in Roles:
		print servName, roleID
		print client.call('gmSendMail', servName, roleID, 1, sender, subject, content, attachs)
		# fus[(servName, roleID)] = fu

	# @coroutine
	# def wait():
	# 	fu = multi_future(fus)
	# 	ret = yield fu
	# 	print ret

	# IOLoop.current().run_sync(wait)

if __name__ == '__main__':
	main()

