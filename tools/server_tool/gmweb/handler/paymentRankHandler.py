#!/usr/bin/env python
# -*- coding: utf-8 -*-

from searchHandler import SearchHandler

import db.redisorm as rom
import db.scheme.game as DBGame
import db.scheme.account as DBAccount
import db.scheme.order as DBOrder

import datetime
import time
#用户消费排名
class PaymentRankHandler(SearchHandler):

    def handler(self):
        # rom.util.set_connection_settings(**self.redisConfigPayment)
        # r = rom.util.get_connection()
        # query = DBOrder.PayOrder.query
        # query = query.filter(channel=self.channel)
        # orders = query.execute()
        # ret = {}
        # ret['resultList'] = []
        # ret['total'] = ""
        # playerOrderMap = {}
        
        # for order in orders:
        #     if order.time < self.startTime or order.time > self.endTime:
        #         continue

        #     playerName = DBAccount.Account.get(order.account_id)
        #     if playerName not in playerOrderMap.keys():
        #         playerOrderMap[playerName] = []
        #     playerOrderMap[playerName].append(order)

        # playerOrders = sorted(playerOrderMap.iteritems(), key=lambda d:d[1], reverse = True )
        # for item in playerOrders:
        #     ret['resultList'].append({item[0]:item[1]})
        # ret['total'] = 'rank result'
        # ret['status'] = 1
        # return self.write(ret)
        ret = {}
        ret['resultList'] = []

        ret['resultList'].append({'title1':{'value':'234','order':9},'asdf':{'value':'value','order':1},123:{'value':321,'order':2}})
        ret['total'] = ""
        ret['status'] = 1
        return self.write(ret)
#         PaymentRankHandler
# from gmweb import SearchHandlerMap
# SearchHandlerMap['paymentRank'] = PaymentRankHandler