#!/usr/bin/env python
# -*- coding: utf-8 -*-

from searchHandler import SearchHandler

import db.redisorm as rom
import db.scheme.game as DBGame
import db.scheme.account as DBAccount
import db.scheme.order as DBOrder

import datetime
import time
#用户订单查询
class PlayerOrdersHandler(SearchHandler):

    def handler(self):
        
        ret = {}
        ret['resultList'] = []
       
        ret['total'] = "not Implemented"
        ret['status'] = 0
        return self.write(ret)
        # rom.util.set_connection_settings(**self.redisConfigPayment)
        # r = rom.util.get_connection()


        # orders = []
        # oMax = DBOrder.PayOrder.get_primary_max()
        # for i in xrange(1, oMax):
        #     try:
        #         order = DBOrder.PayOrder.get(i)
        #     except Exception, e:
        #         continue
        #     if order and order.channel == self.channel and order.account_id == int(self.playerID):
        #         orders.append(order)

        # ret = {}
        # ret['resultList'] = []
        # amount = 0
        # for order in orders:
        #     if order.time < self.startTime or order.time > self.endTime:
        #         continue

        #     ret['resultList'].append(order._data)
        #     amount += order.amount
        # ret['total'] = u"玩家总付费:%d,订单数%d"%(amount, len(ret['resultList']))
        # ret['status'] = 1
        # return self.write(ret)


# PlayerOrdersHandler
# from gmweb import SearchHandlerMap
# SearchHandlerMap['playerOrders'] = PlayerOrdersHandler