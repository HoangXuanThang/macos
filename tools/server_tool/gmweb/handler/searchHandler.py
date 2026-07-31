#!/usr/bin/env python
# -*- coding: utf-8 -*-

import datetime
import time
import sys
import os
import json
sys.path.append('../../')

import db.redisorm as rom
import db.scheme.game as DBGame
import db.scheme.account as DBAccount
import db.scheme.order as DBOrder

from tornado.web import RequestHandler

from db import defines

from gmweb.utils import *
from gmweb.archive import Archive


class SearchHandler(RequestHandler):


    #请求处理入口，包括判断登录，解析参数，分发处理和错误处理
    def get(self):
        
        user = self.get_secure_cookie('youmi_user')
        if user != 'guest':
            self.write('no auth')
            return
        self.searchType = self.get_argument("searchType", None)
        self.serverName = self.get_argument("serverName", None)
        self.platform = self.get_argument("platform", None)
        self.channel = self.get_argument("channel",None)
        startDate = self.get_argument("startDate",None)
        endDate = self.get_argument("endDate",None)
        if startDate:
            startTime = startDate + ' 00:00:00'
            self.startTime = time.mktime(time.strptime(startTime,'%Y-%m-%d %H:%M:%S'))
            y, m, d = startDate.split('-')
            self.startDate = datetime.date(year = int(y), month=int(m),day=int(d))


        if endDate:
            endTime = endDate + ' 23:59:59'
            self.endTime = time.mktime(time.strptime(endTime,'%Y-%m-%d %H:%M:%S'))
            y, m, d = endDate.split('-')
            self.endDate = datetime.date(year = int(y), month=int(m),day=int(d))

        assert self.startTime < self.endTime
        self.playerID = self.get_argument("playerID",None)
        self.orderID = self.get_argument("orderID",None)
        self.unionID = self.get_argument("unionID",None)
        self.playerName = self.get_argument("playerName",None)
        # if self.serverName:                
        #     redisConfigGame = defines.ServerDefs[self.serverName]['redis']
        #     redisConfigGame['port'] += SERVER_CONFIG['SLAVE_DB_PORT']
        #     redisConfigGame['host'] = '123.207.111.69'
        ret = self.handler()
        #rom.session.rollback()
        ret['total'] += 'last update time %s'%(Archive.last_upd_time)
        return self.write(ret)

        # except Exception, e:
        #     print 32 * '-'
        #     print e
        #     print 32 * '-'
        #     ret = {}
        #     ret['status'] = 0
        #     ret['total'] = u'参数错误:'+str(e)
        #     return self.write(ret)
        

    def handler(self):
        raise NotImplementedError()

