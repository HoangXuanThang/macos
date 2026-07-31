#!/usr/bin/env python
# -*- coding: utf-8 -*-


from searchHandler import SearchHandler

from gmweb.utils import *
from gmweb.archive import Archive
#活跃用户查询
class ActiveHandler(SearchHandler):

    def handler(self):

        start_date = self.startDate
        end_date = self.endDate
        ret = {}
        ret['resultList'] = []
        while start_date <= end_date:
            date = date2int(start_date)
            account_info = Archive.get_archive(date, SEARCH_TYPE['active'])
            if self.channel == 'ALL':
                s = 0
                for k,v in account_info.items():
                    s += len(v)
        
            else:
                if self.channel == 'lj':
                    channels = ['lj_yeshen', 'lj_anfan', 'lj_jiumao']
                elif self.channel == 'tencent':
                    channels = ['wx', 'qq']
                else:
                    channels = [self.channel]            

                s = 0
                for channel in channels:
                    s += len(get_with_default(account_info,channel,[]))
            ret['resultList'].append({'date':date,'info':s})           
            start_date += OneDay


        ret['status'] = 1
        ret['total'] = u'各渠道活跃人数'
        return ret




