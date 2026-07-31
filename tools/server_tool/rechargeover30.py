#!/usr/bin/python
# -*- coding: utf-8 -*-
import datetime
import os
import sys
import time

from db import redisorm as rom
import redis
from db.redisorm import util

from db.defines import ServerDefs as DBServerDefs
from game.defines import ServerDefs as GameServerDefs
from db.scheme.game import Role
from db.scheme.order import PayOrder

from gmweb.utils import *

server_list = ['game_qq01','game_qq02','game_qq03','game_qq04','game_qq05','game_qq06','game_qq07','game_qq08']
#server_list = ['game_qq09','game_qq10','game_qq11','game_qq12','game_qq13','game_qq14','game_qq15','game_qq16']
#server_list = ['game_qq17','game_qq18','game_qq19','game_qq20','game_qq21','game_qq22','game_qq23']

# config
DB_CONFIG = {}


def init_config():
    slave_db_port = 1
    for game_server in server_list:
        DB_CONFIG[game_server] = DBServerDefs[game_server]['redis']
        DB_CONFIG[game_server]['host'] = GameServerDefs[game_server]['ip']
        DB_CONFIG[game_server]['port'] += slave_db_port
    DB_CONFIG['payment'] = DBServerDefs['payment_qq']['redis']
    DB_CONFIG['payment']['port'] += slave_db_port
    DB_CONFIG['payment']['host'] = '123.207.108.22'

    print DB_CONFIG


def query(game_server):
    ret = []

    util.set_connection_settings(**DB_CONFIG[game_server])    
    try:
        rmax = Role.get_primary_max()
    except Exception, e:
        print 'server not running...'

    start = 1
    role = Role.get(1)
    if role and role.account_id >= 1000000000:
        start = 10000
    
    ids = [i for i in xrange(start,rmax)]
    # ids = [i for i in xrange(11000,11500)]
    roles = Role.get(ids)
    rom.session.rollback()
    util.set_connection_settings(**DB_CONFIG['payment'])    
    for role in roles:
        if role :
            rmb = 0
            dateAmountMap = {}
            if role.recharges:
                for pid in role.recharges:
                    if pid in [-1,1,2]:
                        continue
                    orders = role.recharges[pid]['orders']
                    for oid in orders:
                        order = PayOrder.get(oid)
                        if order and order.result == 'ok':
                            date = date2int(time2date(order.time))
                            if date not in dateAmountMap:
                                dateAmountMap[date] = 0
                            dateAmountMap[date] += order.amount
                            rmb += order.amount
            t = True
            for date in xrange(20160816,20160831):
                if date not in dateAmountMap:
                    t = False
                    break
                if dateAmountMap[date] < 30:
                    t = False
                    break

            if t:
                ret.append((role.channel, rmb))

    rom.session.rollback()
    return ret
    


def main():
    result = {}
    init_config()
    for server in server_list:        
        ret = query(server)
        result[server] = ret
    for k, v in result.items():
        num = len(v)
        amount = 0
        for item in v:
            amount += item[1]
        print k, num, amount

    channelNum = {}
    channelAmount = {}

    for k, v in result.items():
        for item in v:
            if item[0] not in channelNum:
                channelNum[item[0]] = 0
                channelAmount[item[0]] = 0
            channelNum[item[0]] += 1
            channelAmount[item[0]] += item[1]
    for channel in channelNum:
        print channel, channelNum[channel], channelAmount[channel]



if __name__ == '__main__':
    main()