#!/usr/bin/env python
# -*- coding: utf-8 -*-


from searchHandler import SearchHandler


from gmweb.archive import Archive

#活跃用户曲线

class ActivePlayerHandler(SearchHandler):

    def handler(self):
               
        Archive.repair(self.startDate)
        ret = {}
        ret['resultList'] = []

        
        ret['total'] = u"修复完成"
        ret['status'] = 1
        return ret


