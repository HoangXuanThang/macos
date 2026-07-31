#!/usr/bin/env python
# -*- coding: utf-8 -*-

from searchHandler import SearchHandler

import db.redisorm as rom
import db.scheme.game as DBGame
import db.scheme.account as DBAccount
import db.scheme.order as DBOrder
from gmweb.database import redisConfigPayment
import datetime
import time
#根据ID查询订单
class OrderByIDHandler(SearchHandler):

    def handler(self):
        rom.util.set_connection_settings(**redisConfigPayment)
        r = rom.util.get_connection()
        ret = {}
        ret['resultList'] = []
        ret['total'] = ""

        OrderID = int(self.orderID)
        try:
            order = DBOrder.PayOrder.get(OrderID)
            print order.__dict__
        except Exception, e:
            ret['total'] = u"no order by id"
        else:
            item = {}
            for key in order._data.keys():
                if key == 'sdkmsg' :
                    continue
                item[key] = order._data[key]

            ret['resultList'].append(item)

        ret['status'] = 1        
        return self.write(ret)


# from gmweb import SearchHandlerMap
# SearchHandlerMap['orderByID'] = OrderByIDHandler