#!/usr/bin/env python
# -*- coding: utf-8 -*-

from searchHandler import SearchHandler

from gmweb.utils import *
from gmweb.archive import Archive

#新增用户查询
class AllIncomeHandler(SearchHandler):

    def handler(self):
        start_date = self.startDate
        end_date = self.endDate
        ret = {}
        ret['resultList'] = []
        while start_date <= end_date:
            date = date2int(start_date)
            order_info = Archive.get_archive(date, SEARCH_TYPE['order'])
            active_info = Archive.get_archive(date, SEARCH_TYPE['active'])
            s = 0
            punum = 0
            activenum = 0
            for k,v in order_info.items():
                s += v['amount']
                punum += len(v['ids'])
            for k,v in active_info.items():
                activenum += len(v)
            pr = '%.1f'%(float(punum)/activenum* 100) + '%' if activenum else 0
            arpu = round(float(s)/punum,2) if punum else 0
            aarpu = round(float(s)/activenum,2) if activenum else 0
            ret['resultList'].append({'date':{'order':0,'value':date},'amount':{'order':1,'value':s},u'付费用户':{'order':2,'value':punum},u'活跃用户':{'order':3,'value':activenum},u'付费率':{'order':4,'value':pr},'arpu':{'order':5,'value':arpu},u'活跃arpu':{'order':6,'value':aarpu}})
            for channel in order_info:
                punum = len(order_info[channel]['ids'])
                if channel == 'yijie':
                    activenum = 0
                    for c in active_info:
                        if c[:5] == 'yijie':
                            activenum += len(active_info[c])
                elif channel in ['anfan','yeshen','jiumao']:
                    activenum = len(active_info['lj_'+channel]) if 'lj_'+channel in active_info else 0

                else:
                    activenum = len(active_info[channel]) if channel in active_info else 0
                s = order_info[channel]['amount']
                pr = '%.1f'%(float(punum)/activenum* 100) + '%' if activenum else 0
                arpu = round(float(s)/punum,2) if punum else 0
                aarpu = round(float(s)/activenum,2) if activenum else 0
                ret['resultList'].append({'date':{'order':0,'value':channel},'amount':{'order':1,'value':s}, u'付费用户':{'order':2,'value':punum},u'活跃用户':{'order':3,'value':activenum},u'付费率':{'order':4,'value':pr},'arpu':{'order':5,'value':arpu},u'活跃arpu':{'order':6,'value':aarpu}})

            start_date += OneDay


        ret['status'] = 1
        ret['total'] = u'各渠道收入情况'
        return ret

