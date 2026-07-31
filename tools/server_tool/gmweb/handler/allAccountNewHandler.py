#!/usr/bin/env python
# -*- coding: utf-8 -*-

from searchHandler import SearchHandler

from gmweb.archive import Archive
from gmweb.utils import *

#新增用户查询
class AllAccountNewHandler(SearchHandler):

    def handler(self):
        start_date = self.startDate
        end_date = self.endDate
        ret = {}
        ret['resultList'] = []
        while start_date <= end_date:
            date = date2int(start_date)
            account_info = Archive.get_archive(date, SEARCH_TYPE['new_account'])
            s = 0
            for k,v in account_info.items():
                s += len(v)
            ret['resultList'].append({'date':date,'info':s})
            for channel in account_info:
                ret['resultList'].append({'date':channel,'info':len(account_info[channel])})

            start_date += OneDay


        ret['status'] = 1
        ret['total'] = u'各渠道新增人数'
        return ret

        


        


