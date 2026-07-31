#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
import sys
sys.path.append('../')

import datetime
import logging
import os.path
import signal
import time

import tornado.auth
import tornado.httpserver
import tornado.ioloop
import tornado.web
import tornado.log
from tornado.options import options

from db.defines import ServerDefs as DBServerDefs
from gmweb.archive import Archive
import gmweb.handler
from gmweb.defines import ServerDefs
from gmweb.utils import *

logger = tornado.log.access_log
def initLogger():
    tornado.log.enable_pretty_logging()


class Application(tornado.web.Application):
    def __init__(self):
        initLogger()
        handlers = [
            (r"/auth/login", AuthLoginHandler),
            (r"/auth/logout", AuthLogoutHandler),
            (r"/search", SearchPageHandler),
        ]
        handlers = handlers + gmweb.handler.handlers
        print '===================================='
        print handlers
        print '===================================='
        settings = dict(
            blog_title=u"YouMi ShuMa Stat Blog",
            template_path=os.path.join(os.path.dirname(__file__), "templates"),
            static_path=os.path.join(os.path.dirname(__file__), "static"),
            xsrf_cookies=True,
            cookie_secret="__TODO:huangwei_GENERATE_YOUR_OWNyoumi_RANDOM_VALUE_HERE__",
            login_url="/auth/login",
            debug=True,
        )
        tornado.web.Application.__init__(self, handlers, **settings)


class BaseHandler(tornado.web.RequestHandler):
    pass


class SearchPageHandler(BaseHandler):
    def get(self):
        user = self.get_secure_cookie('youmi_user')
        if user != 'guest':
            self.write('no auth')
            return
        serverList = []
        for name in DBServerDefs.keys():
            if name[:5] == 'game_':
                serverList.append(name)
        serverList = sorted(serverList)
        t = ['All']
        t.extend(serverList)
        serverList = t
        date = str(datetime.date.today())
        self.render('index.html',serverList=serverList,date=date)



class AuthLoginHandler(BaseHandler):
    def get(self):
        pwd = self.get_argument("pwd", None)
        if pwd != 'youmi_stat':
            self.write('no auth')
        else:
            self.set_secure_cookie("youmi_user", 'guest')
            self.redirect('/search')

class AuthLogoutHandler(BaseHandler):
    def get(self):
        self.clear_cookie("youmi_user")
        self.redirect('/auth/login')



class Server(object):
    def __init__(self, name):
        self.cfg = ServerDefs[name]
        init_config(self.cfg)
        listen_port = self.cfg['listen_port']
        self.http_server = tornado.httpserver.HTTPServer(Application())
        self.http_server.listen(listen_port)
        #self.nsq_server = NSQServer(NSQReaders)
        self.ioloop = tornado.ioloop.IOLoop.instance()
        self.name = name
        self.servName = '[%s] GM Web Server' % name
        self.address = ''
        archive_timer = tornado.ioloop.PeriodicCallback(Archive.archive_data, 3 * 60 *1000)
        archive_timer.start()



    def runLoop(self):
        self.ioloop.start()



def main():
    pass


if __name__ == '__main__':
    main()


