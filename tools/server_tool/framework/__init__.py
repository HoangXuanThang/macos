#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Tornado
http://www.tornadoweb.org/en/stable/index.html
'''

import sys
import time
import math
import datetime
import platform


__company__ = 'TianJi Information Technology Inc.'
__copyright__ = 'Copyright (c) 2016 TianJi Information Technology Inc.'


nowtime_t = time.time
nowdate_t = datetime.date.today
nowdatetime_t = datetime.datetime.now
nowdtime_t = lambda: nowdatetime_t().time()

is_percent_t = lambda x: isinstance(x,str) and x[-1] == '%'
# (float, percent)
str2num_t = lambda x: ((0, float(x[:-1]) / 100.0) if (isinstance(x,str) and x[-1] == '%') else (float(x), 0))
ceil_int_t = lambda f: int(0.5 + math.ceil(f))

ZeroTime = datetime.time(hour=0, minute=0, second=1)
DayFullTime = datetime.time(hour=23, minute=59, second=59)
OneDay = datetime.timedelta(days=1)


# 自然日
def todaydate2int():
	return date2int(nowdate_t())

# 凌晨5点后算新的一天
def todayinclock5date2int():
	ndt = nowdatetime_t()
	ndi = date2int(ndt.date())
	if ndt.hour >= 5:
		return ndi
	return date2int(ndt.date() - OneDay)

# 自然日
def todayelapsedays(start_time):
	ndt = nowdatetime_t()
	dt = ndt - start_time
	return dt.days

# 按凌晨5点算新的一天
def todayinclock5elapsedays(start_time):
	ndt = nowdatetime_t()
	dt = ndt.date() - start_time.date()
	if start_time.hour < 5 and ndt.hour >= 5:
		return dt.days + 1
	elif ndt.hour < 5 and start_time.hour >= 5:
		return dt.days - 1
	return dt.days

def date2int(dt):
	return dt.year * 10000 + dt.month * 100 + dt.day

def int2date(v):
	return datetime.date(year=v / 10000, month=(v / 100) % 100, day=v % 100)

def inclockNdate2int(tNow, hours=5):
	if tNow.hour >= hours:
		return date2int(tNow)
	return date2int(tNow - OneDay)

def inclock5date(t):
	if t.hour >= 5:
		return t.date()
	return (t - OneDay).date()

def period2date(start_time, t=None):
	t = nowdatetime_t() if t is None else t
	if t.time() >= start_time:
		return t.date()
	return (t - OneDay).date()

def perioddate2int(start_time, t=None):
	return date2int(period2date(start_time, t))

def nowtime2int():
	return datetime2int(nowdatetime_t())

#找到时刻对应的时间区间起点的数字
def time2period(t, periods):
	hour = t.hour

	if hour < periods[0]:
		date = period2date(datetime.time(hour=periods[0]), t)
		hour = periods[len(periods)-1]
	else:
		i = 0
		for period in periods:
			if period > hour:
				break
			i += 1
		date = nowdatetime_t()
		hour = periods[i - 1]

	return date2int(date)*100 + hour

#找到现在时刻对应的时间区间起点的数字
def nowtime2period(periods):
	return time2period(nowdatetime_t(), periods)

def datetime2int(dt):
	return (dt.year % 100) * 1000000 + dt.month * 10000 + dt.day * 100 + dt.hour

def int2datetime(v):
	return datetime.datetime(year=2000 + v / 1000000, month=(v / 10000) % 100, day=(v / 100) % 100, hour=v % 100)

def time2int(t):
	return t.hour * 100 + t.minute

def int2time(v):
	return datetime.time(hour=v / 100, minute=v % 100)

def int2timedelta(v):
	return datetime.timedelta(hours=v / 100, minutes=v % 100)

def todaymonth2int():
	return month2int(nowdate_t())

def month2int(t):
	return t.year * 100 + t.month

def int2month(v):
	return datetime.date(year=v / 100, month=v % 100, day=1)

def in_period(start_time, duration, now=nowdatetime_t()):
	todayStart = datetime.datetime.combine(now.date(), start_time)
	if now.time() >= start_time:
		return now < todayStart + duration
	# may be in yesterday period
	return now < todayStart - OneDay + duration

def period_runtime(start_time, duration, now=nowdatetime_t()):
	todayStart = datetime.datetime.combine(now.date(), start_time)
	if now.time() >= start_time:
		if now >= todayStart + duration:
			return None # out
		return now - todayStart
	if now >= todayStart + duration - OneDay:
		return None # out
	return now - todayStart + OneDay

def utf2local(s):
	if platform.system() == 'Windows':
		return s.decode('utf8').encode('gbk')
	return s

# 随机字典空配置标示符
def is_none(s):
	return 'NONE' == s.upper() if isinstance(s, str) else False

def is_qq_channel(s):
	return s.upper() in ('QQ', 'WX')

class Timer(object):
	def __init__(self, name, verbose=True):
		self.verbose = verbose
		self.name = name

	def __enter__(self):
		self.start = time.time()
		return self

	def __exit__(self, *args):
		self.end = time.time()
		self.secs = self.end - self.start
		self.msecs = self.secs * 1000  # millisecs
		if self.verbose:
			print '[DEBUG] %s elapsed time: %f ms' % (self.name, self.msecs)

class EventLocker(object):
	def __init__(self, ev):
		self.ev = ev

	def __enter__(self):
		self.ev.set()
		return self

	def __exit__(self, *args):
		self.ev.clear()

if __name__ == '__main__':
	#for test
	print nowtime2period([9,12,13,14,15,16,18,21])
	print time2period(datetime.datetime.now(),[9,12,13,16,18,21])



