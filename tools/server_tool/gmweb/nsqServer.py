#!/usr/bin/env python
# -*- coding: utf-8 -*-

from nsqrpc.message import unpack_request, pack_response, NOTIFY

import nsq
import tornado
import re
import time

from defines import NSQReaders, NSQ_LOOKUP

from database import *



class NSQServer(object):

    def __init__(self, cfg):
        self.readers = []
        for reader in cfg:
            self.add_reader(reader)


    def add_reader(self, cfg):
        reader = NSQReader(cfg)
        self.readers.append(reader)



class NSQReader(object):

    def __init__(self, cfg):
        self.ioloop = tornado.ioloop.IOLoop.current()
        self.topic = cfg['topic']
        self.channel = cfg['channel']
        # 之后如果有多种reader，根据类型使用不同的handler...
        self.handler = LogHandler(cfg)
        self.reader = nsq.Reader(message_handler=self.request_handler,
            lookupd_http_addresses=NSQ_LOOKUP,
            topic=self.topic, channel=self.channel,  lookupd_poll_interval=15)



    def request_handler(self, msg):
        msgid, protocol = unpack_request(msg.body)
        #print msgid, protocol
        
        return self.handler.handleLog(protocol)



class LogHandler(object):

    def __init__(self, cfg):
        self.re_str = cfg['re']



    def handleLog(self,logItem):
        serverName = logItem[3][1]
        #目前只处理登录
        match = re.search(self.re_str, logItem[3][0])
        if match:
            log_date = str(int(match.groupdict()['ddate']) + 20000000)
            log_time = match.groupdict()['ttime']
            role_id = int(match.groupdict()['account'])
            print log_date, log_time, role_id, serverName
            a = log_date + ' ' + log_time
            created_at = time.mktime(time.strptime(a,'%Y%m%d %H:%M:%S'))
            addLoginRecord(role_id, serverName, created_at)
        return True



