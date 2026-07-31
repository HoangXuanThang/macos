#!/usr/bin/python
# -*- coding: utf-8 -*-

# scheme and db interface

from __future__ import absolute_import
import sys
sys.path.append('../')

import os
import time

from db import redisorm as rom
import redis
from db.redisorm import util

import db.scheme.account as DBAccount
import db.scheme.order as DBOrder
from gmweb.utils import *
from tornado.log import app_log

class DailyArchive(rom.Model):
    id = rom.PrimaryKey()
    date = rom.Integer(required=True, index=True)
    new_account = rom.Msgpack(required=True, default={})
    account_curse = rom.Integer(required=True,default=0)
    active = rom.Msgpack(required=True, default={})
    active_timestamp = rom.Float(required=True, default=0)
    order = rom.Msgpack(required=True, default={})
    order_timestamp = rom.Float(required=True, default=0)
    extend_data = rom.Msgpack(required=True,default={}) # 扩展数据


def get_daily_archive(date):
    util.set_connection_settings(**DB_CONFIG['gmweb'])
    ret = DailyArchive.get_by(date=date)
    rom.session.rollback()
    if ret:
        return ret[0]
    else:
        return None


def save_daily_archive(t_archive):
    util.set_connection_settings(**DB_CONFIG['gmweb'])
    t_archive.save()
    rom.session.rollback()



def create_daily_archive(date):
    util.set_connection_settings(**DB_CONFIG['gmweb'])
    d = DailyArchive(date=date)
    d.save()
    rom.session.rollback()
    return d

# 以后改成直接返回的...
def get_account_after_curse(curse):

    util.set_connection_settings(**DB_CONFIG['account'])
    amax = DBAccount.Account.get_primary_max()
    ids = [i for i in xrange(curse+1, amax)]
    accounts = DBAccount.Account.get(ids, safe=True)

    ret = {}
    newcurse = curse

    for account in accounts:
        if account:
            if account.id > newcurse:
                newcurse = account.id
            get_with_default(ret, account.channel, []).append(account.id)
    return ret, newcurse

# 以后改成直接返回的...
def get_account_after_curse_direct(curse):

    util.set_connection_settings(**DB_CONFIG['account'])
    amax = DBAccount.Account.get_primary_max()
    print 'get_account_after_curse_direct', curse, amax
    ids = [i for i in xrange(curse+1, amax)]
    accounts = DBAccount.Account.get(ids, safe=True)

    return accounts


def get_active_after_time(timestamp):

    util.set_connection_settings(**DB_CONFIG['account'])
    query = DBAccount.Account.query
    newstamp = time.time()
    query = query.filter(last_time=(timestamp, newstamp))
    accounts = query.execute(safe=True)
    ret = {}

    print 'get_active_after_time', len(accounts)
    for account in accounts:
        if account:
            get_with_default(ret, account.channel, []).append(account.id)
    return ret, newstamp

def get_order_after_time(timestamp):

    util.set_connection_settings(**DB_CONFIG['payment'])

    query = DBOrder.PayOrder.query
    newstamp = time.time()

    query = query.filter(time=(timestamp, newstamp))
    orders = query.execute(safe=True)
    util.set_connection_settings(**DB_CONFIG['account'])
    for order in orders:
        if order and order.channel == 'yijie':
            account = DBAccount.Account.get(order.account_id, safe=True)
            if account:
                order.channel = account.channel

    return orders, newstamp

def get_order_in_period(start,end):
    util.set_connection_settings(**DB_CONFIG['payment'])

    query = DBOrder.PayOrder.query

    query = query.filter(time=(start, end))
    orders = query.execute(safe=True)
    util.set_connection_settings(**DB_CONFIG['account'])
    for order in orders:
        if order and order.channel == 'yijie':
            account = DBAccount.Account.get(order.account_id, safe=True)
            if account:
                order.channel = account.channel

    return orders


if __name__ == '__main__':
    pass



