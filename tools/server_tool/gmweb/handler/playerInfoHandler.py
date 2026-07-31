#!/usr/bin/env python
# -*- coding: utf-8 -*-

import msgpack
from searchHandler import SearchHandler

import db.redisorm as rom
import db.scheme.game as DBGame
import db.scheme.account as DBAccount
import db.scheme.order as DBOrder
from gmweb.database import redisConfigGame
#from framework.csv import csv,ErrDefs

import datetime
import time
#根据用户Id获取信息
class PlayerInfoHandler(SearchHandler):

    def handler(self):
        rom.util.set_connection_settings(**redisConfigGame)
        r = rom.util.get_connection()

        role = DBGame.Role.get(int(self.playerID))
        if not role:
            ret = {}
            ret['resultList'] = []
        
            ret['total'] = u"没有查到用户"
            ret['status'] = 1
            return self.write(ret)
        ret = {}
        ret['resultList'] = []
    
        ret['resultList'].append({'title':'account_id', 'content': role.account_id})
        ret['resultList'].append({'title':'用户来源渠道', 'content': role.channel})
        ret['resultList'].append({'title':'账号区服', 'content': role.area})
        ret['resultList'].append({'title':'角色名字', 'content': role.name})
        ret['resultList'].append({'title':'个性签名', 'content': role.personal_sign})
        ret['resultList'].append({'title':'主角等级', 'content': role.level})
        ret['resultList'].append({'title':'当前体力值', 'content': role.stamina})
        ret['resultList'].append({'title':'主角当前技能点数', 'content': role.skill_point})
        ret['resultList'].append({'title':'当前等级下经验', 'content': role.level_exp})
        ret['resultList'].append({'title':'总经验', 'content': role.sum_exp})
        ret['resultList'].append({'title':'金币', 'content': role.gold})
        ret['resultList'].append({'title':'RMB钻石', 'content': role.rmb})
        ret['resultList'].append({'title':'QQ托管钻石', 'content': role.qq_rmb})
        ret['resultList'].append({'title':'QQ充值金额', 'content': role.qq_recharge})
        ret['resultList'].append({'title':'竞技场代币', 'content': role.coin1})
        ret['resultList'].append({'title':'远征代币', 'content': role.coin2})
        ret['resultList'].append({'title':'工会代币', 'content': role.coin3})
        ret['resultList'].append({'title':'RMB钻石消耗', 'content': role.rmb_consume})
        ret['resultList'].append({'title':'天赋点', 'content': role.talent_point})
        ret['resultList'].append({'title':'VIP等级', 'content': role.vip_level})
        ret['resultList'].append({'title':'卡牌列表', 'content': str(role.cards)})
        ret['resultList'].append({'title':'道具字典', 'content': str(role.items)})
        ret['resultList'].append({'title':'碎片字典', 'content': str(role.frags)})
        ret['resultList'].append({'title':'开放世界地图列表', 'content': str(role.world_open)})
        ret['resultList'].append({'title':'开放的章节地图列表', 'content': str(role.map_open)})
        ret['resultList'].append({'title':'日常任务字典', 'content': str(role.daily_task)})
        ret['resultList'].append({'title':'主线任务字典', 'content': str(role.main_task)})
        ret['resultList'].append({'title':'购买的充值字典', 'content': str(role.recharges)})
        ret['resultList'].append({'title':'离线充值缓存', 'content': str(role.recharges_cache)})
        ret['resultList'].append({'title':'工会数据', 'content': str(role.union_db_id)})
        ret['resultList'].append({'title':'上次离开的工会id', 'content': role.union_last_db_id})
        ret['resultList'].append({'title':'GM封号', 'content': role.disable_flag})
        ret['resultList'].append({'title':'GM禁言', 'content': role.silent_flag})
        
        x = time.localtime(role.last_time)
        last_time = time.strftime('%Y-%m-%d %H:%M:%S',x)
        ret['resultList'].append({'title':'最后操作时间', 'content': last_time})
        
        x = time.localtime(role.created_time)
        created_time = time.strftime('%Y-%m-%d %H:%M:%S',x)
        ret['resultList'].append({'title':'创建角色时间', 'content': created_time})
        
        ret['total'] = "player info"
        ret['status'] = 1

        return self.write(ret)


# PlayerInfoHandler
# from gmweb import SearchHandlerMap
# SearchHandlerMap['playerInfo'] = PlayerInfoHandler