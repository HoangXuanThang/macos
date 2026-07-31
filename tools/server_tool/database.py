#!/usr/bin/python
# -*- coding: utf-8 -*-

from db import redisorm as rom
import redis
from db.redisorm import util
import os
import time
from db import defines
import datetime
import db.scheme.account as DBAccount
import db.scheme.order as DBOrder

OneDay = datetime.timedelta(days = 1)

redisConfigGmweb = defines.ServerDefs['gmweb']['redis']
redisConfigGame = defines.ServerDefs['game']['redis']
redisConfigAccount = defines.ServerDefs['account']['redis']
redisConfigPayment = defines.ServerDefs['payment']['redis']

if redisConfigAccount['port'] == 26379:
    redisConfigAccount['port'] = 26479
if redisConfigPayment['port'] == 26379:
    redisConfigPayment['port'] = 26479
if redisConfigGame['port'] == 26379:
    redisConfigGame['port'] = 26479
util.set_connection_settings(**redisConfigGmweb)


class LoginRecord(rom.Model):
    id = rom.PrimaryKey()
    account_id = rom.Integer(required = True)
    created_at = rom.Float(default = time.time)
    channel = rom.String(required = True)


class GMDailyRecord(rom.Model):
    id = rom.PrimaryKey()
    date = rom.Integer(required = True, unique = True, index = True)  #20160707
    channel_info = rom.Msgpack(required = True) #{channel:new_account_num,active_num,income_amount,pay_user_num,order_num}
    account_db_maxid = rom.Integer(required = True)
    payment_db_maxid = rom.Integer(required = True)
    active_db_maxid = rom.Integer(required = True)


def addDailyRecord(date):
    util.set_connection_settings(**redisConfigAccount)
    
    startTime = datetime.datetime.combine(date, datetime.time(second=1))
    startTime = time.mktime(startTime.timetuple())
    endTime = datetime.datetime.combine(date + OneDay, datetime.time(second=1))
    endTime = time.mktime(endTime.timetuple())
    activeAccounts = []

    channel_info = {}
    aMax = DBAccount.Account.get_primary_max()
    aids = [i for i in xrange(1,aMax)]
    accounts = DBAccount.Account.get(aids)
    for account in accounts:
        #活跃用户
        if account and startTime < account.last_time and account.last_time < endTime:
            activeAccounts.append({'account_id':account.id, 'channel':account.channel, 'created_at':account.last_time})
            if account.channel not in channel_info.keys():
                channel_info[account.channel] = {}
                channel_info[account.channel]['new_account_num'] = 0
                channel_info[account.channel]['active_num'] = 0
                channel_info[account.channel]['income_amount'] = 0
                channel_info[account.channel]['pay_user_num'] = 0
                channel_info[account.channel]['order_num'] = 0
            channel_info[account.channel]['active_num'] += 1
        #新增用户
        if account and startTime < account.created_time and account.created_time < endTime:
            if account.channel not in channel_info.keys():
                channel_info[account.channel] = {}
                channel_info[account.channel]['new_account_num'] = 0
                channel_info[account.channel]['active_num'] = 0
                channel_info[account.channel]['income_amount'] = 0
                channel_info[account.channel]['pay_user_num'] = 0
                channel_info[account.channel]['order_num'] = 0
            channel_info[account.channel]['new_account_num'] += 1


    util.set_connection_settings(**redisConfigGmweb)   
    for account in activeAccounts:
        record = LoginRecord(account_id=account['account_id'], created_at=account['created_at'],channel=account['channel']) 
        record.save()
    active_db_maxid = LoginRecord.get_primary_max()
    startId = 1
    yestoday = date - OneDay
    yestoday = yestoday.year * 10000 + yestoday.month * 100 + yestoday.day
    try:
        dailyrecord = GMDailyRecord.get_by(date = yestoday)
    except Exception, e:
        dailyrecord = None
    if dailyrecord:
        startId = dailyrecord.payment_db_maxid

    #统计收入情况
    util.set_connection_settings(**redisConfigPayment)
    oMax = DBOrder.PayOrder.get_primary_max()
    oids = [i for i in xrange(startId, oMax)]
    channelUserMap = {}
    orders = DBOrder.PayOrder.get(oids)
    for order in orders:
        if order and order.time > startTime and order.time < endTime and order.result == 'ok':
            if order.channel not in channel_info.keys():
                channel_info[order.channel] = {}
                channel_info[order.channel]['new_account_num'] = 0
                channel_info[order.channel]['active_num'] = 0
                channel_info[order.channel]['income_amount'] = 0
                channel_info[order.channel]['pay_user_num'] = 0
                channel_info[order.channel]['order_num'] = 0
            
            channel_info[order.channel]['order_num'] += 1
            channel_info[order.channel]['income_amount'] += order.amount

            if order.channel not in channelUserMap.keys():
                channelUserMap[order.channel] = []
            if order.account_id not in channelUserMap[order.channel]:
                channelUserMap[order.channel].append(order.account_id)

    for channel in channelUserMap.keys():
        channel_info[channel]['pay_user_num'] = len(channelUserMap[channel])

    date = date.year * 10000 + date.month * 100 + date.day
    util.set_connection_settings(**redisConfigGmweb)
    dailyrecord = GMDailyRecord(date=date, channel_info=channel_info, account_db_maxid=aMax, payment_db_maxid=oMax, active_db_maxid=active_db_maxid)
    dailyrecord.save()



def getLoginRecord(channel, startTime, endTime):
    accountIDs = []
    t = time.localtime(endTime)
    end_date = datetime.date(year=t.tm_year, month = t.tm_mon, day = t.tm_mday)
    if end_date >= datetime.date.today():
        #获取当天活跃数值
        todayStart = datetime.datetime.combine(datetime.date.today(), datetime.time(second=1))
        todayStart = time.mktime(todayStart.timetuple())
        util.set_connection_settings(**redisConfigAccount)
        aMax = DBAccount.Account.get_primary_max()

        aids = [i for i in xrange(1,aMax)]
        accounts = DBAccount.Account.get(aids)

        for account in accounts:
            if account and account.last_time> todayStart and account.last_time<endTime and account.channel == channel:
                if account.id not in accountIDs:
                    accountIDs.append(account.id)

    t = time.localtime(startTime)
    start_date = datetime.date(year=t.tm_year, month = t.tm_mon, day = t.tm_mday)
    if start_date >= datetime.date.today():
        return accountIDs

    util.set_connection_settings(**redisConfigGmweb)

    rMax = LoginRecord.get_primary_max()

    ids = [i for i in xrange(1,rMax)]
    records = LoginRecord.get(ids)
    
    for record in records:
        if record and record.channel==channel and record.created_at > startTime and record.created_at < endTime:
            if record.account_id not in accountIDs:
                accountIDs.append(record.account_id)

    return accountIDs

def getLoginByDate(channel, startTime, endTime):
    util.set_connection_settings(**redisConfigGmweb)
    loginByDate = {}

    query = LoginRecord.query
    query = query.filter(channel=channel)
    records = query.execute()

    for record in records: 
        if record and record.created_at > startTime and record.created_at < endTime:
            t = time.localtime(record.created_at)
            timeStr=time.strftime("%Y-%m-%d %H:%M:%S", t)
            dateStr = timeStr.split(' ')[0]
            if dateStr not in loginByDate.keys():
                loginByDate[dateStr] = 0
            loginByDate[dateStr] += 1
    return loginByDate


def getNewAccount(startDate, endDate):
    #{'date':{channel1,channel2...}}
    ret = {}
    if endDate >= datetime.date.today():
        endDate =  datetime.date.today() 
        item = {}
        #get today info here
        #get maxid yestoday
        util.set_connection_settings(**redisConfigGmweb)
        startId = 1
        yestoday = endDate - OneDay
        yestoday = date2int(yestoday)
        try:
            dailyrecord = GMDailyRecord.get_by(date = yestoday)
        except Exception, e:
            dailyrecord = None
        if dailyrecord:
            startId = dailyrecord.payment_db_maxid

        util.set_connection_settings(**redisConfigAccount)
        aMax = DBAccount.Account.get_primary_max()
        aids = [i for i in xrange(startId, aMax)]
        accounts = DBAccount.Account.get(aids)
        for account in accounts:
            if account:
                timeTuple = time.localtime(account.created_time)
                create_date = datetime.date(year=timeTuple.tm_year, month = timeTuple.tm_mon, day = timeTuple.tm_mday)
                if create_date == endDate:
                    if account.channel not in item.keys():
                        item[account.channel] = 0
                    item[account.channel] += 1
        ret[date2int(endDate)] = item
        endDate -= OneDay



        
    util.set_connection_settings(**redisConfigGmweb)
    while startDate <= endDate:
        #get startdate info from gmweb db
        dateint = date2int(startDate)
        try:
            dailyrecord = GMDailyRecord.get_by(date = dateint)
        except Exception, e:
            dailyrecord = None
        if dailyrecord:
            channel_info = dailyrecord.channel_info
            item = {}
            for channel in channel_info.keys():

                item[channel] = channel_info[channel]['new_account_num']
             
                
            ret[dateint] = item
        startDate += OneDay

    return ret


        



def getActive(startDate, endDate):
    ret = {}
    if endDate >= datetime.date.today():
        endDate =  datetime.date.today() 
        item = {}
        util.set_connection_settings(**redisConfigAccount)
        aMax = DBAccount.Account.get_primary_max()
        aids = [i for i in xrange(1, aMax)]
        accounts = DBAccount.Account.get(aids)
        for account in accounts:
            if account:
                timeTuple = time.localtime(account.last_time)
                create_date = datetime.date(year=timeTuple.tm_year, month = timeTuple.tm_mon, day = timeTuple.tm_mday)
                if create_date == endDate:
                    if account.channel not in item.keys():
                        item[account.channel] = 0
                    item[account.channel] += 1
        ret[date2int(endDate)] = item
        endDate -= OneDay

    util.set_connection_settings(**redisConfigGmweb)
    while startDate <= endDate:
        #get startdate info from gmweb db
        dateint = date2int(startDate)
        try:
            dailyrecord = GMDailyRecord.get_by(date = dateint)
        except Exception, e:
            dailyrecord = None
        if dailyrecord:
            channel_info = dailyrecord.channel_info
            item = {}
            for channel in channel_info.keys():
                    item[channel] = channel_info[channel]['active_num']

            ret[dateint] = item
        startDate += OneDay

    return ret


def test():
    today = datetime.date.today()
    yestoday = today - OneDay
    startTime = datetime.datetime.combine(yestoday, datetime.time(second=1))
    startTime = time.mktime(startTime.timetuple())
    endTime = datetime.datetime.combine(yestoday, datetime.time(hour = 23, minute = 59,second=59))
    endTime = time.mktime(endTime.timetuple())

    tdstartTime = datetime.datetime.combine(today, datetime.time(second=1))
    tdstartTime = time.mktime(tdstartTime.timetuple())
    tdendTime = datetime.datetime.combine(today, datetime.time(hour = 23, minute = 59,second=59))
    tdendTime = time.mktime(tdendTime.timetuple())
    util.set_connection_settings(**redisConfigAccount)
    aMax = DBAccount.Account.get_primary_max()
    channelAccount = {}
    for i in xrange(1,aMax):
        a = DBAccount.Account.get(i)
        if a and a.created_time > startTime and a.created_time < endTime and a.last_time >tdstartTime and a.last_time < tdendTime:
            if a.channel not in channelAccount.keys():
                channelAccount[a.channel] = 0
            channelAccount[a.channel] += 1

    print channelAccount
    return channelAccount

def getRetention(date):
    if date >= datetime.date.today():
        return None
    ret = {}
    # get new account
    channelAccount = {}
    util.set_connection_settings(**redisConfigGmweb)
    startId = 0
    aMax = -1
    lastday = date -OneDay
    try:
        dailyrecord = GMDailyRecord.get_by(date = date2int(lastday))
    except Exception, e:
        dailyrecord = None
    if dailyrecord:
        startId = dailyrecord.account_db_maxid

    try:
        dailyrecord = GMDailyRecord.get_by(date = date2int(date))
    except Exception, e:
        dailyrecord = None
    if dailyrecord:
        aMax = dailyrecord.account_db_maxid


    util.set_connection_settings(**redisConfigAccount)
    if aMax == -1:
        aMax = DBAccount.Account.get_primary_max()

    aids = [i for i in xrange(startId, aMax)]
    accounts = DBAccount.Account.get(aids)
    for account in accounts:
        timeTuple = time.localtime(account.created_time)
        create_date = datetime.date(year=timeTuple.tm_year, month = timeTuple.tm_mon, day = timeTuple.tm_mday)
        if create_date == date:
            if account.channel not in channelAccount.keys():
                channelAccount[account.channel] = []
            channelAccount[account.channel].append(account.id)

    ret['newAccount'] = channelAccount
    days = [1,2,3,4,5,6,14,29]
    for num in days :

        #次日留存
        channelNum = {}
        afterdate = date + OneDay * num
        if afterdate > datetime.date.today():
            break
        if afterdate == datetime.date.today():
            #去account查
            util.set_connection_settings(**redisConfigAccount)
            for channel in channelAccount.keys():
                channelNum[channel] = 0
                for aid in channelAccount[channel]:
                    account = DBAccount.Account.get(aid)
                    if account and time2date(account.last_time) == afterdate:
                        channelNum[channel] += 1

        else:
            #去gmweb查
            util.set_connection_settings(**redisConfigGmweb)
            activeIds = []
            startId = 0
            aMax = GMDailyRecord.get_primary_max()

            lastday = afterdate - OneDay
            dr = GMDailyRecord.get_by(date=date2int(lastday))
            if dr:                
                startId = dr.active_db_maxid

            dr = GMDailyRecord.get_by(date=date2int(afterdate))
            if dr:
                aMax = dr.active_db_maxid

            ids = [i for i in xrange(startId, aMax)]
            records = LoginRecord.get(ids)

            for record in records:
                if record and time2date(record.created_at) == afterdate:
                    activeIds.append(record.account_id)

            for channel in channelAccount.keys():
                channelNum[channel] = 0
                for aid in channelAccount[channel]:
                    if aid in activeIds:
                        channelNum[channel] += 1
        ret[num] = channelNum
    
    return ret


def date2int(date):
    return date.year * 10000 + date.month * 100 + date.day


def time2date(t):
    timeTuple = time.localtime(t)
    return datetime.date(year=timeTuple.tm_year, month = timeTuple.tm_mon, day = timeTuple.tm_mday)






