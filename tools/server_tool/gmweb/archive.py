#!/usr/bin/python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
import sys
sys.path.append('../')

import datetime
import time

from gmweb.database import *
from gmweb.utils import *
import tornado.log
import framework

import json
import urlparse

log_method = tornado.log.access_log.info
rechargeMap = [0,0,0,648,328,198,98,60,30,6,0,0,0,0,0,0,0]

# daily data archive and query
class Archive(object):


    # 当天数据内存缓存
    data = {}
    last_upd_time = ''

    # 数据归档定时执行
    # 新需求加新的process处理extend即可
    @classmethod
    def archive_data(cls):
        t_archive = cls._load_current_data()

        cls._process_newaccount()

        cls._process_active()

        cls._process_order()

        cls._upd_data(t_archive)

    # 加载今天的数据，没有就建一个空的
    @classmethod
    def _load_current_data(cls):
        #  防止 晚上0点左右 跨天
        today = datetime.date.today()
        yestoday = today - OneDay
        today = date2int(today)
        yestoday = date2int(yestoday)

        t_archive = get_daily_archive(today)
        if t_archive:

            # upd to cls.data
            cls.data['new_account'] = t_archive.new_account
            cls.data['account_curse'] = t_archive.account_curse
            cls.data['active'] = t_archive.active
            cls.data['active_timestamp'] = t_archive.active_timestamp
            cls.data['order'] = t_archive.order
            cls.data['order_timestamp'] = t_archive.order_timestamp
            cls.data['extend_data'] = t_archive.extend_data
            log_method('start archieve: date:%d, %d, %d, %d'%(today, t_archive.account_curse, t_archive.active_timestamp, t_archive.order_timestamp))

        else:
            # get yesterday
            y_archive = get_daily_archive(yestoday)
            if y_archive:
                cls.data['account_curse'] = y_archive.account_curse
                cls.data['active_timestamp'] = y_archive.active_timestamp
                cls.data['order_timestamp'] = y_archive.order_timestamp
                log_method('got yesoday data: date:%d, %d, %d, %d'%(today, y_archive.account_curse, y_archive.active_timestamp, y_archive.order_timestamp))
            else:

                cls.data['account_curse'] = 0
                cls.data['active_timestamp'] = day_start()
                cls.data['order_timestamp'] = day_start()
                log_method('this should only show for the first time')

            cls.data['new_account'] = {}
            cls.data['active'] = {}
            cls.data['order'] = {}
            cls.data['extend_data'] = {}
            t_archive = create_daily_archive(today)
        return t_archive



    # 写回
    @classmethod
    def _upd_data(cls, t_archive):
        t_archive.new_account = cls.data['new_account']
        t_archive.account_curse = cls.data['account_curse']
        t_archive.active = cls.data['active']
        t_archive.active_timestamp = cls.data['active_timestamp']
        t_archive.order = cls.data['order']
        t_archive.order_timestamp = cls.data['order_timestamp']
        t_archive.extend_data = cls.data['extend_data']
        cls.last_upd_time = str(datetime.datetime.now())
        save_daily_archive(t_archive)

    @classmethod
    def _process_newaccount(cls):
        new_accounts, newcurse = get_account_after_curse(cls.data['account_curse'])
        # 字典合并，更新 curse
        for channel in new_accounts:
            get_with_default(cls.data['new_account'], channel, []).extend(new_accounts[channel])
        cls.data['account_curse'] = newcurse

    @classmethod
    def _process_active(cls):
        active_accounts, newstamp = get_active_after_time(cls.data['active_timestamp'])
        for channel in active_accounts:
            channel_arr = get_with_default(cls.data['active'], channel, [])
            for aid in active_accounts[channel]:
                append_unique(channel_arr, aid)
        cls.data['active_timestamp'] = newstamp


    @classmethod
    def _process_order(cls):
        orders, newstamp = get_order_after_time(cls.data['order_timestamp'])
        for order in orders:
            channel = order.channel
            if channel == 'tc':
                sdkmsg = order.sdkmsg
                d = dict(urlparse.parse_qsl(sdkmsg))
                rid = json.loads(d['game_extra'])[3]
                order.amount =  int(rechargeMap[rid])
            channel_info = get_with_default(cls.data['order'], channel, {'amount':0,'ids':[]})
            channel_info['amount'] += order.amount
            append_unique(channel_info['ids'], order.account_id)
        cls.data['order_timestamp'] = newstamp

        order_by_server = get_with_default(cls.data['extend_data'], 'order_by_server', {})
        for order in orders:
            server_key = order.server_key
            channel = order.channel
            server_info = get_with_default(order_by_server, server_key, {})
            channel_info = get_with_default(server_info, channel, {'amount':0,'ids':[]})
            channel_info['amount'] += order.amount
            append_unique(channel_info['ids'], order.account_id)


    # 给handler 查询使用。只做查询
    # search type 为空就不往后判断了
    @classmethod
    def get_archive(cls, date, search_type=None, channel=None):
        d_archive = get_daily_archive(date)
        data = {}
        if d_archive:

            data['new_account'] = d_archive.new_account
            data['active'] = d_archive.active
            data['order'] = d_archive.order
            data['extend_data'] = d_archive.extend_data

            if search_type:
                data = data[search_type]
            if channel:
                data = get_with_default(data, channel, {})

        return data

    @classmethod
    def repair(cls, date):
        dddate = date
        yestoday = date - OneDay
        yestoday = date2int(yestoday)
        y_archive = get_daily_archive(yestoday)
        if y_archive is None:
            y_archive = create_daily_archive(yestoday)
            print 'framework.__language__', framework.__language__
            if framework.__language__ == 'tw':
                y_archive.account_curse = 17470970-1
        accounts = get_account_after_curse_direct(y_archive.account_curse)
        print 'repair accounts', len(accounts)

        account_data = {}
        order_data = {}
        newcurse = y_archive.account_curse
        for account in accounts:
            if account and time2date(account.created_time) == date:
                if account.id > newcurse:
                    newcurse = account.id
                get_with_default(account_data, account.channel, []).append(account.id)

        start = datetime.datetime.combine(date, datetime.time(second=1))
        end = datetime.datetime.combine(date, datetime.time(hour=23,minute=59,second=59))
        start = time.mktime(start.timetuple())
        end = time.mktime(end.timetuple())
        if dddate == datetime.date.today():
            end = time.time()

        print 'repair order datetime', start, end
        orders = get_order_in_period(start,end)
        print 'repair orders', len(orders)
        for order in orders:
            channel = order.channel
            if channel == 'tc':
                sdkmsg = order.sdkmsg
                d = dict(urlparse.parse_qsl(sdkmsg))
                rid = json.loads(d['game_extra'])[3]
                try:
                    order.amount =  int(rechargeMap[rid])
                except Exception as e:
                    print rid
                    raise

            channel_info = get_with_default(order_data, channel, {'amount':0,'ids':[]})
            channel_info['amount'] += order.amount
            append_unique(channel_info['ids'], order.account_id)

        order_by_server = {}
        for order in orders:
            server_key = order.server_key
            channel = order.channel
            server_info = get_with_default(order_by_server, server_key, {})
            channel_info = get_with_default(server_info, channel, {'amount':0,'ids':[]})
            channel_info['amount'] += order.amount
            append_unique(channel_info['ids'], order.account_id)

        date = date2int(date)
        d_archive = get_daily_archive(date)
        if d_archive is None:
            d_archive = create_daily_archive(date)
        d_archive.new_account = account_data
        d_archive.account_curse = newcurse
        #d_archive.active_timestamp = end
        d_archive.order_timestamp = end
        d_archive.order = order_data
        extend_data = {}
        extend_data['order_by_server'] = order_by_server
        d_archive.extend_data = extend_data
        if dddate != datetime.date.today():
            d_archive.active_timestamp = end
        # 修复当天活跃
        if dddate == datetime.date.today():
            active_info, newstamp = get_active_after_time(start)
            d_archive.active = active_info
            d_archive.active_timestamp = newstamp

        save_daily_archive(d_archive)
