import re
import db.redisorm as rom
import db.scheme.game as DBGame
import db.scheme.account as DBAccount
import db.scheme.order as DBOrder

from database import LoginRecord

import time
import datetime

defines = {
    'account': {
        'redis': {
            'host': '0.0.0.0',
            'port': 26479,
            'db': 1,
            'password': 'hzyoumiheat02redis01',
        },
        'host': '127.0.0.1',
        'port': 27777,
        'log_topic': 'global',
    },
    'gmweb': {
        'redis': {
            'host': '0.0.0.0',
            'port': 26379,
            'db': 4,
            'password': 'hzyoumiheat02redis01',
        },
    },
}

myRedisConfigAccount = defines['account']['redis']
myRedisConfigGmweb = defines['gmweb']['redis']


if __name__ == '__main__':
    fList = ['login_server-stdout---supervisor-qTt5pE.log','login_server-stdout---supervisor-qTt5pE.log.1']
    rom.util.set_connection_settings(**myRedisConfigAccount)
    print '======================================='
    print 'about to get active account ids.this will run minutes'
    print '======================================='
    
    accounts = []
    for filename in fList:

        f = open(filename,'r')
        re_str = r"(?P<ddate>[0-9]{6}) (?P<ttime>[0-9]{2}:[0-9]{2}:[0-9]{2}).*] `(?P<name>.*)` login in server"  
        lines = f.readlines()
        i = 0
        for line in lines:
            if i > 1000:
                break
            i+=1
            match = re.search(re_str , line)
            if match:
                date = match.groupdict()['ddate']
                name = match.groupdict()['name']
                if date == '160707':
                    a = DBAccount.Account.get_by(name = name)
                    if a:
                        print a.id
                        if a.id not in accounts:
                            accounts.append({'id':a.id,'channel':a.channel}) 

    print '======================================='
    print 'account ids done'
    print len(accounts)
    print '======================================='

    print '======================================='
    print 'about to write in gmweb db'
    print 'be   careful..............'
    print '======================================='

    rom.util.set_connection_settings(**myRedisConfigGmweb)

    # constuct a time in 2016 07 07
    date = datetime.date(year = 2016, month=7,day=7)
    t = datetime.datetime.combine(date, datetime.time(hour = 12,second=1))
    
    #this should be float because of my terrible design of db
    created_at = time.mktime(t.timetuple())

    for a in accounts:
        record = LoginRecord(account_id=a['id'],channel=a['channel'],created_at=created_at)
        record.save()




                
