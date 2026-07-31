#!/usr/bin/env python
# -*- coding: utf-8 -*-

from searchHandler import SearchHandler

from gmweb.utils import *
from gmweb.archive import Archive

#新增用户查询
class IncomeHandler(SearchHandler):

    def handler(self):
        start_date = self.startDate
        end_date = self.endDate
        ret = {}
        ret['resultList'] = []
        while start_date <= end_date:
            date = date2int(start_date)
            order_info = Archive.get_archive(date, SEARCH_TYPE['order'])
            active_info = Archive.get_archive(date, SEARCH_TYPE['active'])
            if self.channel == 'ALL':
                s = 0
                punum = 0
                activenum = 0
                dollar_sum = 0
                dollar_pn = 0
                dollar_active = 0
                for k,v in order_info.items():
                    if k in ['mofang_iy','mofang_ay', 'mofang_if', 'mofang_af']:
                        dollar_sum += v['amount']
                        dollar_pn += len(v['ids'])
                    else:
                        s += v['amount']
                        punum += len(v['ids'])
                for k,v in active_info.items():
                    if k in ['mofang_iy','mofang_ay', 'mofang_if', 'mofang_af']:
                        dollar_active += len(v)
                    else:
                        activenum += len(v)
                pr = '%.1f'%(float(punum)/activenum* 100) + '%' if activenum else 0
                arpu = round(float(s)/punum,2) if punum else 0
                aarpu = round(float(s)/activenum,2) if activenum else 0
                dollar_pr = '%.1f'%(float(dollar_pn)/dollar_active* 100) + '%' if dollar_active else 0
                dollar_arpu = round(float(dollar_sum)/dollar_pn,2) if dollar_pn else 0
                dollar_aarpu = round(float(dollar_sum)/dollar_active,2) if dollar_active else 0
                ret['resultList'].append({'date':{'order':0,'value':date},'amount':{'order':1,'value':s}, u'付费用户':{'order':2,'value':punum},u'活跃用户':{'order':3,'value':activenum},u'付费率':{'order':4,'value':pr},'arpu':{'order':5,'value':arpu},u'活跃arpu':{'order':6,'value':aarpu}})
                ret['resultList'].append({'date':{'order':0,'value':u'美元收入'},'amount':{'order':1,'value':dollar_sum}, u'付费用户':{'order':2,'value':dollar_pn},u'活跃用户':{'order':3,'value':dollar_active},u'付费率':{'order':4,'value':dollar_pr},'arpu':{'order':5,'value':dollar_arpu},u'活跃arpu':{'order':6,'value':dollar_aarpu}})
                
            else:
                channel = self.channel
                activenum = 0
                s = 0
                punum = 0
                if channel == 'lj':
                    channels = ['anfan','yeshen','jiumao']
                    for channel in channels:
                        s += order_info[channel]['amount'] if channel in order_info else 0
                        punum += len(order_info[channel]['ids']) if channel in order_info else 0
                        activenum += len(get_with_default(active_info, 'lj_'+channel, []))
                elif channel == 'tencent':
                    channels = ['wx','qq']
                    for channel in channels:
                        s += order_info[channel]['amount'] if channel in order_info else 0
                        punum += len(order_info[channel]['ids']) if channel in order_info else 0
                        activenum += len(get_with_default(active_info, channel, []))
                else:
                    s = order_info[channel]['amount'] if channel in order_info else 0
                    punum = len(order_info[channel]['ids']) if channel in order_info else 0
                    activenum = len(get_with_default(active_info, channel, []))

                
                pr = '%.1f'%(float(punum)/activenum* 100) + '%' if activenum else 0
                arpu = round(float(s)/punum,2) if punum else 0
                aarpu = round(float(s)/activenum,2) if activenum else 0
                ret['resultList'].append({'date':{'order':0,'value':date},'amount':{'order':1,'value':s}, u'付费用户':{'order':2,'value':punum},u'活跃用户':{'order':3,'value':activenum},u'付费率':{'order':4,'value':pr},'arpu':{'order':5,'value':arpu},u'活跃arpu':{'order':6,'value':aarpu}})

            start_date += OneDay


        ret['status'] = 1
        ret['total'] = u'各渠道收入情况'
        return ret

