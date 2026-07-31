#!/usr/bin/env python
# -*- coding: utf-8 -*-


from searchHandler import SearchHandler

from gmweb.utils import *
from gmweb.archive import Archive

#用户留存查询
class RetentionHandler(SearchHandler):

    def handler(self):
        days = [1,2,3,4,5,6,14,29]
        titles = {1:'次留',2:'3留',3:'4留',4:'5留',5:'6留',6:'7留',14:'15留',29:'30留'}

        start_date = self.startDate
        end_date = self.endDate
        ret = {}
        ret['resultList'] = []
        if self.channel == 'ALL':
            while start_date <= end_date:

                date = date2int(start_date)
                
                item = {}
                item['date'] = {'value':str(date),'order':0}
                account_info = Archive.get_archive(date, SEARCH_TYPE['new_account'])
                # 新增人数
                s = get_sum(account_info)
                item['新增人数'] = {'value':s,'order':1}
                new_accounts = {}
                for k, v in account_info.items():
                    for aid in v:
                        new_accounts[aid] = True

                for day in days:
                    newdate = start_date + OneDay * day
                    newdate = date2int(newdate)
                    active_info = Archive.get_archive(newdate, SEARCH_TYPE['active'])
                    # 登录人数
                    active_num = 0
                    active_accounts = []
                    for k, v in active_info.items():
                        active_accounts.extend(v)

                    for aid in active_accounts:
                        if aid in new_accounts:
                            active_num += 1
                    p = float(active_num)*100/s if s else 0
                    value = "%d, %.1f"%(active_num,p) + '%'
                    item[titles[day]] = {'order':day+2, 'value':value}
                start_date += OneDay
                ret['resultList'].append(item)
        else:
            while start_date <= end_date:

                date = date2int(start_date)
                
                item = {}
                item['date'] = {'value':str(date),'order':0}
                account_info = Archive.get_archive(date, SEARCH_TYPE['new_account'],self.channel)
                # 新增人数
                s = 0
                new_accounts = {}
                if account_info:
                    s = len(account_info)
                    for aid in account_info:
                        new_accounts[aid] = True
                item['新增人数'] = {'value':s,'order':1}


                for day in days:
                    newdate = start_date + OneDay * day
                    newdate = date2int(newdate)
                    active_info = Archive.get_archive(newdate, SEARCH_TYPE['active'],self.channel)
                    # 登录人数
                    active_num = 0
                    active_accounts = []
                    if active_info:
                        active_accounts = active_info

                    for aid in active_accounts:
                        if aid in new_accounts:
                            active_num += 1
                    p = float(active_num)*100/s if s else 0
                    value = "%d, %.1f"%(active_num,p) + '%'
                    item[titles[day]] = {'order':day+2, 'value':value}
                start_date += OneDay
                ret['resultList'].append(item)
                    
        ret['status'] = 1
        ret['total'] = u'各渠道留存'
        return ret

