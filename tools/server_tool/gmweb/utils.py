#!/usr/bin/python
# -*- coding: utf-8 -*-

# config and other common tools

from __future__ import absolute_import
import sys
sys.path.append('../')

import datetime
import time

import framework
from db.defines import ServerDefs as DBServerDefs
from game.defines import ServerDefs as GameServerDefs


# defines

SEARCH_TYPE = {
    'new_account': 'new_account',
    'active': 'active',
    'order':'order',
}

# config
DB_CONFIG = {}

def init_config(cfg):
    DB_CONFIG['account'] = DBServerDefs['account_qq']['redis']
    DB_CONFIG['payment'] = DBServerDefs['payment_qq']['redis']
    DB_CONFIG['gmweb'] = DBServerDefs['gmweb_qq']['redis']

    slave_db_port = cfg['SLAVE_DB_PORT']
    DB_CONFIG['account']['port'] += slave_db_port
    DB_CONFIG['payment']['port'] += slave_db_port

    DB_CONFIG['payment']['host'] = '123.207.108.22'
    DB_CONFIG['account']['host'] = '123.207.108.22'
    DB_CONFIG['gmweb']['host'] = '123.207.108.22'

    if framework.__language__ == 'tw':
        DB_CONFIG['payment']['host'] = '119.28.17.230'
        DB_CONFIG['account']['host'] = '119.28.17.230'
        DB_CONFIG['gmweb']['host'] = '119.28.17.230'

    # for server in DBServerDefs:
    #     if 'game_qq' in server:
    #         DB_CONFIG[server] = DBServerDefs[server]['redis']
    #         DB_CONFIG[server]['host'] = GameServerDefs[server]['ip']
    print '=' * 32
    print 'finish init config'
    print DB_CONFIG
    print '=' * 32



# datetime tool

OneDay = datetime.timedelta(days = 1)

def day_start():
    t = datetime.datetime.combine(datetime.date.today(), datetime.time(second=1))
    return time.mktime(t.timetuple())

def date2int(date):
    return date.year * 10000 + date.month * 100 + date.day

def time2date(t):
    timeTuple = time.localtime(t)
    return datetime.date(year=timeTuple.tm_year, month = timeTuple.tm_mon, day = timeTuple.tm_mday)

def today2int():
    today = datetime.date.today()
    return date2int(today)

def yestoday2int():
    y = datetime.date.today() - OneDay
    return date2int(y)


# dict tools

# 只对dict list有用.只能函数级联操作
def get_with_default(d, key, default):
    if key not in d:
        d[key] = default
    return d[key]


def append_unique(arr, value):
    if value not in arr:
        arr.append(value)

# 针对 account 和active d:{'channel':[ids...]}
def get_sum(d):
    s = 0
    for k, v in d.items():
        s += len(v)
    return s


if __name__ == '__main__':
    print str(datetime.datetime.now())

