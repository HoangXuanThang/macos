#!/usr/bin/env python
# -*- coding: utf-8 -*-


from searchHandler import SearchHandler

from gmweb.utils import *
from gmweb.archive import Archive
#活跃用户查询
class IncomeByServerHandler(SearchHandler):

    def handler(self):
        start_date = self.startDate
        end_date = self.endDate
        ret = {}
        ret['resultList'] = []
        while start_date <= end_date:
            date = date2int(start_date)
            order_info = get_with_default(Archive.get_archive(date)['extend_data'], 'order_by_server', {})
            server_info = {}
            s = 0
            for key in order_info :
                for channel in order_info[key]:
                    s += order_info[key][channel]['amount']
            if self.serverName == 'All':
                for server in order_info:
                    for channel in order_info[server]:
                        channel_info = get_with_default(server_info, channel, {'amount':0,'ids':[]})
                        channel_info['amount'] += order_info[server][channel]['amount']
                        channel_info['ids'].extend(order_info[server][channel]['ids'])

            else:
                if self.serverName in order_info:
                    server_info = order_info[self.serverName]

            amount = 0
            pu = 0
            dollar_amount = 0
            dollar_pu = 0
            if self.channel == 'ALL':
                for channel in server_info:
                    if channel in ['mofang_iy','mofang_ay', 'mofang_if', 'mofang_af']:
                        dollar_amount += server_info[channel]['amount']
                        dollar_pu += len(server_info[channel]['ids'])
                    else:
                        amount += server_info[channel]['amount']
                        pu += len(server_info[channel]['ids'])
            else:
                if self.channel in server_info:
                    amount = server_info[channel]['amount']
                    pu = len(server_info[channel]['ids'])
            ret['resultList'].append({'date':{'order':0,'value':str(start_date)},'amount':{'order':1,'value':amount},u'付费用户':{'order':2,'value':pu}})
            if dollar_amount:
                ret['resultList'].append({'date':{'order':0,'value':u'美元收入'},'amount':{'order':1,'value':dollar_amount},u'付费用户':{'order':2,'value':dollar_pu}})
            start_date += OneDay


        ret['status'] = 1
        ret['total'] = u'收入分服务器统计'
        return ret