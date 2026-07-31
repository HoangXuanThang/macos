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
#根据工会ID获取工会信息
class UnionInfoHandler(SearchHandler):

    def handler(self):
        rom.util.set_connection_settings(**redisConfigGame)
        r = rom.util.get_connection()

        if not self.unionID:
            ret = {}
            ret['resultList'] = []
            
            uMaxID = DBGame.Union.get_primary_max()
            for uID in xrange(1, uMaxID):
                try:
                    union = DBGame.Union.get(uID)
                except Exception, e:
                    print "lose union by id"
                    continue
                if not union:
                    continue
                x = time.localtime(union.created_time)
                created_time = time.strftime('%Y-%m-%d %H:%M:%S',x)
                ret['resultList'].append({
                    'id':union.id,
                    'name':union.name,
                    'level':union.level, 
                    'created_time':created_time
                    })
            ret['total'] = u"社团数 %d"%(len(ret['resultList']))
            ret['status'] = 1
        else:
            union = DBGame.Union.get(int(self.unionID))
            if not union:
                ret = {}
                ret['resultList'] = []
                ret['total'] = u'没有查到相关工会'
                ret['status'] = 1
                return self.write(ret)
            ret = {}
            x = time.localtime(union.created_time)
            created_time = time.strftime('%Y-%m-%d %H:%M:%S',x)
            ret['resultList'] = [
                {'title':'id','value':union.id},
                {'title':'name','value':union.name},
                {'title':'level','value':union.level},
                {'title':'created_time','value':created_time},
                {'title':'contrib', 'value':union.contrib},
                {'title':'day_contrib', 'value':union.day_contrib},
                {'title':'last_date', 'value':union.last_date},
                {'title':'intro', 'value':union.intro},
                {'title':'join_type', 'value':union.join_type},
                {'title':'join_level', 'value':union.join_level},
                {'title':'chairman_db_id', 'value':union.chairman_db_id},
                {'title':'vice_chairmans', 'value':str(union.vice_chairmans)},
                {'title':'members', 'value':str(union.members)},
                {'title':'join_notes', 'value':str(union.join_notes)},
                {'title':'huodongs', 'value':str(union.huodongs)},
                {'title':'mails', 'value':str(union.mails)},
                {'title':'fb_states', 'value':str(union.fb_states)},
                {'title':'institute', 'value':str(union.institute)}
            ]
            ret['total'] = "union info"
            ret['status'] = 1

        return self.write(ret)

# UnionInfoHandler
# from gmweb import SearchHandlerMap
# SearchHandlerMap['unionInfo'] = UnionInfoHandler