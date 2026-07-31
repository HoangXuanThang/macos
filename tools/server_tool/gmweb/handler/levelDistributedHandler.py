#!/usr/bin/env python
# -*- coding: utf-8 -*-

from searchHandler import SearchHandler

import db.redisorm as rom
import db.scheme.game as DBGame
import db.scheme.account as DBAccount
import db.scheme.order as DBOrder

from gmweb.database import redisConfigGame

import datetime
import time
#等级分布查询
class LevelDistributedHandler(SearchHandler):

    def handler(self):
        ret = {}
        ret['resultList'] = []
       
        rom.util.set_connection_settings(**redisConfigGame)
        r = rom.util.get_connection()
        
        roleMaxIndex = DBGame.Role.get_primary_max()
        ret = {}
        ret['resultList'] = []
        ret['total'] = 'level distributed'

        levelNumMap = {}
        for rID in xrange(1, roleMaxIndex):
            try:
                role = DBGame.Role.get(rID)
            except Exception, e:
                print 'miss role by id %d'%(rID)
                continue
            if not role:
                continue
            levelStr = str(role.level)
            if levelStr not in levelNumMap.keys():
                levelNumMap[levelStr] = 0
            levelNumMap[levelStr] += 1

        for level in levelNumMap.keys():
            ret['resultList'].append({'level':level,'count':levelNumMap[level]})

        ret['status'] = 1
        return self.write(ret)   


# from gmweb import SearchHandlerMap
# SearchHandlerMap['levelDistributed'] = LevelDistributedHandler         