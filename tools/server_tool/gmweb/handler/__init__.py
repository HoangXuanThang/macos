#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os  
import sys

from gmweb.handler.searchHandler import SearchHandler
from gmweb.handler.accountNewHandler import AccountNewHandler
from gmweb.handler.activeHandler import ActiveHandler
from gmweb.handler.incomeHandler import IncomeHandler
from gmweb.handler.retentionHandler import RetentionHandler
from gmweb.handler.activePlayerLineHandler import ActivePlayerHandler

from gmweb.handler.allAccountNewHandler import AllAccountNewHandler
from gmweb.handler.allActiveHandler import AllActiveHandler
from gmweb.handler.allIncomeHandler import AllIncomeHandler

from gmweb.handler.incomeByServerHandler import IncomeByServerHandler 


modules = [
    sys.modules['gmweb.handler.accountNewHandler'],
    sys.modules['gmweb.handler.activeHandler'],
    sys.modules['gmweb.handler.incomeHandler'],
    sys.modules['gmweb.handler.retentionHandler'],
    sys.modules['gmweb.handler.activePlayerLineHandler'],

    sys.modules['gmweb.handler.allAccountNewHandler'],
    sys.modules['gmweb.handler.allActiveHandler'],
    sys.modules['gmweb.handler.allIncomeHandler'],

    sys.modules['gmweb.handler.incomeByServerHandler']
]

handlers = []

def makeHandlerMap():
    for module in modules:
        for x in dir(module):
            cls = getattr(module, x)
            if type(cls) == type and issubclass(cls, SearchHandler) and cls != SearchHandler:
                url = '/' + cls.__module__[14:-7]
                handlers.append((url, cls))

makeHandlerMap()








