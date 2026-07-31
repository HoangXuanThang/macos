#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2015 YouMi Information Technology Inc.
'''

import copy
import time
import pprint
import os.path
import datetime

from fabric.api import *
from fabric.contrib.console import *

env.use_ssh_config = True
env.forward_agent = True
env.user = 'root'
env.ssh_config_path = './ssh_config'
env.password = 'youmi1024'
env.passwords = {
	'root@119.28.61.236:22': 'jMz6CZPniXYfINv',
	'root@119.28.62.238:22': 'x3uTfpxYmytPj',
	'root@119.28.66.108:22': 'x3uTfpxYmytPj',
	'root@119.28.68.19:22': 'ZZPcMSBX9gMR',
	'root@119.28.67.201:22': 'nMnYp3MukyYMHdyM',
	'root@119.28.62.228:22': 'qtiaqFPwzjPr2',
	'root@119.28.66.84:22': 'J7HfRSCTDQQ7N2R',
	'root@119.28.17.230:22': 'cBJiRfK9e4byRtPe',
	'root@119.28.65.196:22': 'MgVVDzsNggg3',
	'root@119.28.68.176:22': 'FSXsP4nkbfk7k',
	'root@119.28.66.236:22': 'Fzjy2jfWLDLz',
	'root@119.28.17.78:22': 'fYmimqHI4G7',
}

env.roledefs = {
	'localhost': ['localhost'],

	'all': {
		'hosts': [
			'shuma01',
			'shuma02',
			'shuma03',
			'shuma04',
			'shuma05',
			'shuma06',
			'shuma07',
			'shuma08',
			'shuma09',
			'shuma10',
			'shuma11',
			'shuma12',
			'shuma13',
			'shuma14',
			'shuma15',
			'shuma16',
			'shuma17',
			'shuma18',
			'shuma19_1',
			'shuma19_2',
			'shuma19_3',
			'shuma20',
			'shuma21',
			'shuma22',
			'shuma23',
			'shuma24',

			'shuma-tw-login',
			'shuma-tw01',
			'shuma-tw02',
			'shuma-tw03',
			'shuma-tw04',
			'shuma-tw05',
			'shuma-tw06',
			'shuma-tw07',
			'shuma-tw08',
			'shuma-tw09',
			'shuma-tw10',
			'shuma-tw11',
		],
	},

	'allgame': {
		'hosts': [
			'shuma02',
			'shuma03',
			'shuma04',
			'shuma05',
			'shuma06',
			'shuma07',
			'shuma08',
			'shuma09',
			'shuma10',
			'shuma11',
			'shuma12',
			'shuma13',
			'shuma14',
			'shuma15',
			'shuma16',
			'shuma17',
			'shuma18',
			'shuma19_1',
			'shuma19_2',
			'shuma19_3',
			'shuma20',
			'shuma21',
			'shuma22',
			'shuma23',
			'shuma24',

			'shuma-tw01',
			'shuma-tw02',
			'shuma-tw03',
			'shuma-tw04',
			'shuma-tw05',
			'shuma-tw06',
			'shuma-tw07',
			'shuma-tw08',
			'shuma-tw09',
			'shuma-tw10',
			'shuma-tw11',
		],
	},

	'cngame': {
		'hosts': [
			'shuma02',
			'shuma03',
			'shuma04',
			'shuma05',
			'shuma06',
			'shuma07',
			'shuma08',
			'shuma09',
			'shuma10',
			'shuma11',
			'shuma12',
			'shuma13',
			'shuma14',
			'shuma15',
			'shuma16',
			'shuma17',
			'shuma18',
			'shuma19_1',
			'shuma19_2',
			'shuma19_3',
			'shuma20',
			'shuma21',
			'shuma22',
			'shuma23',
			'shuma24',
		],
	},

	'twgame': {
		'hosts': [
			'shuma-tw01',
			'shuma-tw02',
			'shuma-tw03',
			'shuma-tw04',
			'shuma-tw05',
			'shuma-tw06',
			'shuma-tw07',
			'shuma-tw08',
			'shuma-tw09',
			'shuma-tw10',
			'shuma-tw11',
		],
	},
}


LoginServerCount = 10
GameServerBaseName = 'game_server'
# ServerNameList = ['game_server', 'pvp_server', 'game_db_server']
ServerNameList = ['game_server'] # pvp_server, game_db_server 一般不重启
OtherServerNameList = ['gm_server', 'gmweb_server', 'appnotify', 'payment_server']
AgentName = 'anti_cheat_server'

ServerIDMap = {
	'localhost': [''],

	'shuma02': ['01','02','03','04','05','06','07','08'],
	'shuma03': ['09','10','11','12','13','14','15','16'],
	'shuma04': ['17','18','19','20','21','22','23','24'],
	'shuma05': ['25','26','27','28','29','30','31','32'],
	'shuma06': ['33','34','35','36','37','38','39','40'],
	'shuma07': ['41','42','43','44','45','46','47','48'],
	'shuma08': ['49','50','51','52','53','54','55','56'],
	'shuma09': ['57','58','59','60','61','62','63','64'],
	'shuma10': ['65','66','67','68','69','70','71','72'],
	'shuma11': ['73','74','75','76','77','78','79','80'],
	'shuma12': ['81','82','83','84','85','86','87','88'],
	'shuma13': ['89','90','91','92','93','94','95','96'],
	'shuma14': ['97','98','99','100','101','102','103','104'],
	'shuma15': ['105','106','107','108','109','110','111','112'],
	'shuma16': ['113','114','115','116','117','118','119','120'],
	'shuma17': ['121','122','123','124','125','126','127','128'],
	'shuma18': ['129','130','131','132','133','134','135','136'],
	'shuma19_1': ['137','138','139','140','141','142','143','144'],
	'shuma19_2': ['145','146','147','148','149','150','151','152'],
	'shuma19_3': ['153','154','155','156','157','158','159','160'],
	'shuma20': ['161','162','163','164','165','166','167','168'],
	'shuma21': [
		'169','170','171','172','173','174','175','176',
		'177','178','179','180','181','182','183','184',
		'185','186','187','188','189','190','191','192',
	],
	'shuma22': ['193','194','195','196','197','198','199','200'],
	'shuma23': ['201','202','203','204','205','206','207','208'],
	'shuma24': ['209','210','211','212','213','214','215','216'],

	#################
	'shuma-tw01': ['tw_01'],
	'shuma-tw02': ['tw_02'],
	'shuma-tw03': ['tw_03'],
	'shuma-tw04': ['tw_04'],
	'shuma-tw05': ['tw_05'],
	'shuma-tw06': ['tw_06'],
	'shuma-tw07': ['tw_07'],
	'shuma-tw08': ['tw_08'],
	'shuma-tw09': ['tw_09'],
	'shuma-tw10': ['tw_10'],
	'shuma-tw11': ['tw_11'],
}

MaxServerCount = 8
NewServerIDMap = copy.deepcopy(ServerIDMap)
for role in env.roledefs.keys():
	if 'hosts' not in env.roledefs[role]:
		continue
	hostsList = []
	quick = False
	for host in env.roledefs[role]['hosts']:
		if host not in ServerIDMap:
			continue
		if len(ServerIDMap[host]) <= MaxServerCount:
			hostsList.append(host)
		else:
			j = 1
			for i in xrange(0, len(ServerIDMap[host]), MaxServerCount):
				quick = '%s_%02d' % (host, j)
				hostsList.append(quick)
				NewServerIDMap[quick] = ServerIDMap[host][i:i+MaxServerCount]
				j += 1
				quick = True
	if quick:
		env.roledefs['%s_quick' % role] = {'hosts': hostsList}
ServerIDMap = NewServerIDMap
print 'roledefs=', env.roledefs.keys()
# print env.roledefs['allgame_quick']
# raise ArithmeticError('')


def get_deploy_path():
	ret = run('ls -d /mnt/deploy*')
	if len(str(ret).split()) != 1:
		abort("deploy dictionary can not be determinately!")
	return ret


@parallel
# @roles('all')
@roles('cngame')
# @roles('twgame')
def _all_svn_up():
	def _svn_up():
		with remote_tunnel(3690, local_host='192.168.1.125'):
			with settings(warn_only=True):
				run('svn cleanup')
				run('svn revert ./config_csv.py')
				# run('svn revert ./shuma/login/static/shuma/serv.conf')
				# ret = run('svn up ./shuma/')
				ret = run('svn up')
				if ret.failed and str(ret).find('E205011') < 0:
					if not confirm("failed. continue anyway?"):
						abort("aborting at user request.")
				return run('svn info')

	with cd('/mnt/server'):
		try:
			return _svn_up()

		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = run('netstat -nap|grep :3690|awk \'{print substr($7, 0, index($7, "/")-1)}\'')
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				run('kill -9 %d' % int(ret))
				return _svn_up()


def all_svn_up():
	ret = execute(_all_svn_up)
	for k in sorted(ret.keys()):
		print '-'*20
		print k, ':'
		print '\t', ret[k]


@parallel
# @roles('all')
@roles('twgame')
def _all_csv_svn_up():
	def _csv_svn_up():
		with remote_tunnel(3690, local_host='192.168.1.125'):
			with settings(warn_only=True):
				run('svn cleanup')
				run('svn revert ./config_csv.py')
				ret = run('svn up ./config_csv.py')
				# ret = run('svn up ./shuma/pvp/agentmgr/manager.py')
				if ret.failed and str(ret).find('E205011') < 0:
					if not confirm("failed. continue anyway?"):
						abort("aborting at user request.")
				return run('svn info ./config_csv.py')

	with cd('/mnt/server'):
		try:
			return _csv_svn_up()

		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = run('netstat -nap|grep :3690|awk \'{print substr($7, 0, index($7, "/")-1)}\'')
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				run('kill -9 %d' % int(ret))
				return _csv_svn_up()


def all_csv_svn_up():
	ret = execute(_all_csv_svn_up)
	for k in sorted(ret.keys()):
		print '-'*20
		print k, ':'
		print '\t', ret[k]

@parallel
@roles('all')
def _all_game_svn_up():
	def _game_svn_up():
		with remote_tunnel(3690, local_host='192.168.1.125'):
			with settings(warn_only=True):
				run('svn cleanup')
				run('svn revert ./config_csv.py')
				ret = run('svn up ./config_csv.py')
				if ret.failed and str(ret).find('E205011') < 0:
					if not confirm("failed. continue anyway?"):
						abort("aborting at user request.")
				ret = run('svn up ./shuma')
				if ret.failed and str(ret).find('E205011') < 0:
					if not confirm("failed. continue anyway?"):
						abort("aborting at user request.")
				return run('svn info ./shuma')

	with cd('/mnt/server'):
		try:
			return _game_svn_up()

		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = run('netstat -nap|grep :3690|awk \'{print substr($7, 0, index($7, "/")-1)}\'')
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				run('kill -9 %d' % int(ret))
				return _game_svn_up()


def all_game_svn_up():
	ret = execute(_all_game_svn_up)
	for k in sorted(ret.keys()):
		print '-'*20
		print k, ':'
		print '\t', ret[k]


@hosts('shuma01')
def close_login():
	with cd(get_deploy_path()):
		for i in xrange(1, 1 + LoginServerCount):
			name = 'login_server' if i == 1 else '%02d_login_server' % i
			run('supervisorctl stop %s' % name)
			run('supervisorctl reread %s' % name)
			run('supervisorctl update %s' % name)


@hosts('shuma01')
def start_login():
	with cd(get_deploy_path()):
		for i in xrange(1, 1 + LoginServerCount):
			name = 'login_server' if i == 1 else '%02d_login_server' % i
			run('supervisorctl start %s' % name)

# @hosts('shuma01')
@hosts('shuma-tw-login')
def restart_login():
	with cd(get_deploy_path()):
		for i in xrange(1, 1 + LoginServerCount):
			name = 'login_server' if i == 1 else '%02d_login_server' % i
			run('supervisorctl stop %s' % name)
			run('supervisorctl reread %s' % name)
			run('supervisorctl update %s' % name)
			run('supervisorctl start %s' % name)

@parallel
@roles('allgame')
# @hosts('shuma15')
def close_other():
	# with cd('/mnt/server'):
	# 	run('rm -r ./shuma/pvp/agentmgr')

	with cd(get_deploy_path()):
		for dpy in OtherServerNameList:
			run('supervisorctl stop %s' % dpy)
			run('supervisorctl reread %s' % dpy)
			run('supervisorctl update %s' % dpy)

		# serverCount = len(ServerIDMap[env.host_string])
		# for i in xrange(serverCount):
		# 	run('supervisorctl stop redis%d380' % (10 + i))
		# 	run('supervisorctl stop redis%d379' % (10 + i))
		# 	time.sleep(5)
		# 	run('supervisorctl start redis%d379' % (10 + i))
		# 	run('supervisorctl start redis%d380' % (10 + i))


CrossIDMap = {
	'shuma02': ['01'],

	'shuma03': ['02', '03'],
	'shuma04': ['04', '05'],
	'shuma05': ['06', '07'],
	'shuma06': ['08', '09'],
	'shuma07': ['10', '11'],
	'shuma08': ['12', '13'],
	'shuma09': ['14', '15'],
	'shuma10': ['16', '17'],
	'shuma11': ['18', '19'],
	'shuma12': ['20', '21'],
	'shuma13': ['22', '23'],
	'shuma14': ['24', '25'],
	'shuma15': ['26', '27'],
	'shuma16': ['28', '29'],
	'shuma17': [],
	'shuma18': [],
	'shuma19_1': [],
	'shuma19_2': [],
	'shuma19_3': [],
	'shuma20': [],
	'shuma21': [],
	'shuma22': [],
	'shuma23': [],
	'shuma24': [],
}

@parallel
@roles('cngame')
def close_cross():
	with cd(get_deploy_path()):
		serverIDs = CrossIDMap[env.host_string]
		# with cd('supervisord.dir'):
		# 	with remote_tunnel(3690, local_host='192.168.1.125'):
		# 		for s in serverIDs:
		# 			dbdpy = '%s_cross_db_server.ini' % s
		# 			dpy = '%s_cross_server.ini' % s
		# 			run('svn up %s' % dbdpy)
		# 			run('svn up %s' % dpy)
		# 			run('svn up redis18379.ini')
		# 			run('svn up redis18380.ini')

		# run('supervisorctl reread')
		# run('supervisorctl add redis18379')
		# run('supervisorctl start redis18379')
		# time.sleep(1)
		for s in serverIDs:
			dbdpy = '%s_cross_db_server' % s
			dpy = '%s_cross_server' % s

			# run('supervisorctl add %s' % dbdpy)
			# run('supervisorctl add %s' % dpy)

			run('supervisorctl stop %s' % dbdpy)
			run('supervisorctl reread %s' % dbdpy)
			run('supervisorctl update %s' % dbdpy)
			# run('supervisorctl start %s' % dbdpy)

			run('supervisorctl stop %s' % dpy)
			run('supervisorctl reread %s' % dpy)
			run('supervisorctl update %s' % dpy)
			# run('supervisorctl start %s' % dpy)

@hosts('shuma02')
def start_other():
	with cd(get_deploy_path()):
		for dpy in OtherServerNameList:
			run('supervisorctl start %s' % dpy)


def getDeployName(idx, serv):
	return '%s_%s' % (idx, serv)

def getGameDeployName(idx):
	return '%s_%s' % (idx, GameServerBaseName)


@parallel
@roles('cngame_quick')
# @roles('twgame')
# @hosts('shuma21')
# @roles('allgame_quick')
def close_all_servers():
	with cd(get_deploy_path()):
		serverIDs = ServerIDMap[env.host_string]
		for s in ServerNameList:
			deployNameL = [getDeployName(x, s) if x else s for x in serverIDs]
			# print deployNameL
			for dpy in deployNameL:
				run('supervisorctl stop %s' % dpy)
				run('supervisorctl reread %s' % dpy)
				run('supervisorctl update %s' % dpy)
				while True:
					ret = run('supervisorctl status %s' % dpy)
					if ret.find('STOPPED') > 0:
						break
					time.sleep(1)

		# for i in xrange(10, 34):
		# 	run('supervisorctl stop redis%d379' % i)
		# 	run('supervisorctl stop redis%d380' % i)

		# with cd('./db'):
		# 	for i in xrange(10, 34):
		# 		run('rm game%d379.rdb game%d380.rdb game%d380.aof' % (i, i, i))
		# 		run('cp game160816_robots.rdb game%d379.rdb' % (i))


@parallel
@roles('cngame_quick')
# @roles('twgame')
# @roles('allgame_quick')
def start_all_servers():
	with cd(get_deploy_path()):
		serverIDs = ServerIDMap[env.host_string]
		for s in reversed(ServerNameList):
			deployNameL = [getDeployName(x, s) if x else s for x in serverIDs]
			for dpy in deployNameL:
				run('supervisorctl start %s' % dpy)
			time.sleep(8)



@parallel
@roles('allgame_quick')
# @roles('twgame')
def restart_all_game_servers():
	with cd(get_deploy_path()):
		serverIDs = ServerIDMap[env.host_string]
		deployNameL = [getGameDeployName(x) for x in serverIDs]
		# print deployNameL
		for dpy in deployNameL:
			run('supervisorctl stop %s' % dpy)
			run('supervisorctl reread %s' % dpy)
			run('supervisorctl update %s' % dpy)
			run('supervisorctl start %s' % dpy)


@parallel
@roles('cngame')
def restart_some_servers():
	SomeServerIDs = {'01'}
	# SomeServerIDs = set(['%02d' % i for i in xrange(2, 193)])
	# SomeServerIDs = set(['%02d' % i for i in xrange(137, 161)])
	SomeServerNames = ['game_server'] # , 'pvp_server', 'game_db_server'

	with cd(get_deploy_path()):
		serverIDs = ServerIDMap[env.host_string]
		someIDs = [x for x in serverIDs if x in SomeServerIDs]
		for x in someIDs:
			for s in SomeServerNames:
				dpy = getDeployName(x, s)
				run('supervisorctl stop %s' % dpy)
				run('supervisorctl reread %s' % dpy)
				run('supervisorctl update %s' % dpy)
				while True:
					ret = run('supervisorctl status %s' % dpy)
					if ret.find('STOPPED') > 0:
						break
					time.sleep(1)

			for s in reversed(SomeServerNames):
				dpy = getDeployName(x, s)
				run('supervisorctl start %s' % dpy)
				time.sleep(1)


@parallel
@roles('allgame')
def _status_all_servers():
	ret = {}
	with cd(get_deploy_path()):
		serverIDs = ServerIDMap[env.host_string]
		for s in ServerNameList:
			deployNameL = [getDeployName(x, s) if x else s for x in serverIDs]
			for dpy in deployNameL:
				ret[dpy] = run('supervisorctl status %s' % dpy)
	return ret.values()


@hosts('shuma01')
def _status_other_servers():
	ret = {}
	with cd(get_deploy_path()):
		for i in xrange(1, 1 + LoginServerCount):
			dpy = 'login_server' if i == 1 else '%02d_login_server' % i
			ret[dpy] = run('supervisorctl status %s' % dpy)
		for dpy in OtherServerNameList:
			ret[dpy] = run('supervisorctl status %s' % dpy)
	return ret.values()


def status_all_servers():
	result = execute(_status_all_servers)
	result2 = execute(_status_other_servers)
	result.update(result2)
	ret = []
	for k in sorted(result.keys()):
		print '-'*20
		print k, ':'
		for v in sorted(result[k]):
			print '\t', v
			ret.append(v)
	return ret


@hosts('heat02')
def new_config_svn_ci():
	# with cd('/home/hw_shuma_server/config'):
	# 	run('svn up')

	with cd('/home/hw_shuma_server/deploy'):
		run('supervisorctl restart game_server')

	with cd('/home/hw_shuma_server'):
		while True:
			time.sleep(1)
			ret = run('cat config_csv.py|head')
			if ret.find('No such file') == -1:
				break
		run('svn ci -m "[upd] fabric deploy commit" config_csv.py')
		# run('svn ci -m "[upd] fabric deploy commit. only yyhuodong" config_csv.py')


@parallel
@roles('cngame')
# @roles('all')
def _system_all_servers():
	ps = run('ps aux|grep -E "/usr/bin/python.*?py"|sort -k 6 -n -r')
	ps2 = run('ps aux|grep -E "/mnt/deploy"|sort -k 6 -n -r')
	free = run('free -m')
	uptime = run('uptime')
	processor = run('cat /proc/cpuinfo |grep "processor"|wc -l')
	svn = ''
	with cd('/mnt/server'):
		svn = run('svn info')
	svn_agent_csv = ''
	with cd('/mnt/server/anti-cheat/game_config'):
		svn_agent_csv = run('svn info')
	svn_agent_model = ''
	with cd('/mnt/server/anti-cheat/game_scripts/model'):
		svn_agent_model = run('svn info')
	ls_agent_csv = ''
	with cd('/mnt/server/anti-cheat/game_scripts/config'):
		ls_agent_csv = run('ls -l')
	return (ps, ps2, free, uptime, processor, svn, svn_agent_csv, svn_agent_model, ls_agent_csv)

def system_all_servers():
	result = execute(_system_all_servers)
	warns = []
	infos = []
	times = []
	agentinfos = []
	for k in sorted(result.keys()):
		print '-'*20
		print k, ':'
		ps, ps2, free, uptime, processor, svn, svn_agent_csv, svn_agent_model, ls_agent_csv = result[k]
		servers = 0
		pvpservers = 0
		dbservers = 0
		agents = 0
		crossservers = 0
		print ps
		print ps2
		print free
		print uptime

		lines = ps.split('\r')
		for line in lines:
			lst = line.split()
			big = False
			if line.find('game_server.py') >= 0:
				servers += 1
				times.append(( lst[-1], 'TIME %s' % lst[-4], 'CPU %s%%' % lst[2], 'MEM %s%%' % lst[3], 'RSS %.2f GB' % (float(lst[5])/1024/1024) ))
			if line.find('pvp_server.py') >= 0:
				pvpservers += 1
				big = int(lst[5]) > 5*1024*1024
			if line.find('db_server.py') >= 0:
				dbservers += 1
			if line.find('cross_server.py') >= 0:
				crossservers += 1
			if k == 'shuma01':
				big = big or int(lst[5]) > 1*1024*1024
			else:
				big = big or int(lst[5]) > 8*1024*1024
			if big:
				warns.append(('MEM TOO BIG', '%.2fG' % (float(lst[5])/1024/1024), k, lst[-2], lst[-1]))

		lines = ps2.split('\r')
		for line in lines:
			lst = line.split()
			if line.find('anti-cheat/agent') >= 0:
				agents += 1
				big = int(lst[5]) > 500*1024
				if big:
					warns.append(('MEM TOO BIG', '%.2fG' % (float(lst[5])/1024), 'agent-%s' % k))
				times.append(( 'agent-%s' % k, 'TIME %s' % lst[-2], 'CPU %s%%' % lst[2], 'MEM %s%%' % lst[3], 'RSS %.2f MB' % (float(lst[5])/1024) ))

		lines = free.split('\r')
		lst = lines[2].split()
		low = False
		if k == 'shuma01':
			low = int(lst[3]) < 20*1024
		else:
			low = int(lst[3]) < 30*1024
		if low:
			warns.append(('FREE MEM TOO LOW', 'used %.2fG' % (float(lst[2])/1024), 'free %.2fG' % (float(lst[3])/1024), k))
		used_mem, free_mem = 'used %.2fG' % (float(lst[2])/1024), 'free %.2fG' % (float(lst[3])/1024)

		lst = uptime.split()
		if servers > 0 and float(lst[-2][:-2]) > servers/1.5:
			warns.append(('CPU HIGH LOAD', lst[-3], lst[-2], lst[-1], k, str(servers)))

		lstsvn = svn.split('\n')
		for svnline in lstsvn:
			if svnline.find('Revision:') >= 0:
				break

		if agents > 0:
			lstsvn = svn_agent_csv.split('\n')
			for svnagentline1 in lstsvn:
				if svnagentline1.find('Revision:') >= 0:
					break

			lstsvn = svn_agent_model.split('\n')
			for svnagentline2 in lstsvn:
				if svnagentline2.find('Revision:') >= 0:
					break

			lstsvn = ls_agent_csv.split('\n')
			for lsagentline in lstsvn:
				if lsagentline.find('csv.lua') >= 0:
					lsagentline = ' '.join(lsagentline.split()[-4:-1])
					break

			agentinfos.append(('agent-%s' % k, 'csv %s' % svnagentline1.strip(), 'model %s' % svnagentline2.strip(), 'csv2lua %s' % lsagentline.strip()))

		infos.append((k, used_mem, free_mem, 'load', lst[-3], lst[-2], lst[-1], 'game %s' % str(servers), 'pvp %s' % str(pvpservers), 'cross %s' % str(crossservers), 'db %s' % str(dbservers), 'agent %s' % agents, svnline))

	print '\n'
	print '='*20
	for time in times:
		print '\t'.join(time)
	print '\n'
	print '='*20
	for info in agentinfos:
		print '\t'.join(info)
	print '\n'
	print '='*20
	for info in infos:
		print '\t'.join(info)
	print '\n'
	warns.sort(key=lambda t: t[0])
	for warn in warns:
		print 'WARNING:', '\t'.join(warn)


@parallel
# @roles('cngame')
@roles('twgame')
@hosts('shuma03')
def backup_all_redis():
	RedisStartPort = 10379

	with cd(os.path.join(get_deploy_path(), 'db')):
		serverCount = len(ServerIDMap[env.host_string])
		port = RedisStartPort
		for i in xrange(serverCount):
			run('redis-cli -p %d -a hztjredis_shuma_huangwei save' % port)
			run('redis-cli -p %d -a hztjredis_shuma_huangwei save' % (port+1))
			port += 1000

		dirname = datetime.datetime.now().strftime("%y%m%d_%H%M")
		run('rm -f -r %s' % dirname)
		run('mkdir %s' % dirname)
		ret = run('ls *79.rdb')
		for rdbname in ret.split():
			ret = run('cp %s ./%s' % (rdbname, dirname))
			if ret:
				print '!!! Error', ret, rdbname
		ret = run('ls *80.rdb')
		for rdbname in ret.split():
			ret = run('cp %s ./%s' % (rdbname, dirname))
			if ret:
				print '!!! Error', ret, rdbname


@parallel
# @roles('cngame')
@roles('allgame')
def build_all_agent():
	def _svn_up():
		with remote_tunnel(3690, local_host='192.168.1.125'):
			with settings(warn_only=True):
				run('svn cleanup')
				ret = run('svn up')
				# ret = run('svn up -r14877')
				# ret = run('svn up -r14877 game_config')
				# ret = run('svn up -r14877 game_scripts')
				# ret = run('svn up -r14877 game_scripts/model')
				if ret.failed and str(ret).find('E205011') < 0:
					if not confirm("failed. continue anyway?"):
						abort("aborting at user request.")
				return run('svn info')

	with cd('/mnt/server/anti-cheat'):
		try:
			_svn_up()

		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = run('netstat -nap|grep :3690|awk \'{print substr($7, 0, index($7, "/")-1)}\'')
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				run('kill -9 %d' % int(ret))
				_svn_up()

	with cd(get_deploy_path()):
		run('supervisorctl stop %s' % AgentName)
		run('supervisorctl reread %s' % AgentName)
		run('supervisorctl update %s' % AgentName)
		with cd('/mnt/server/anti-cheat'):
			run('chmod 777 build.sh csv2lua.sh')
			run('rm -f agent')
			run('./build.sh')
			run('./csv2lua.sh')
		run('supervisorctl start %s' % AgentName)

@parallel
# @roles('cngame')
@roles('allgame')
def restart_all_agent():
	with cd(get_deploy_path()):
		run('supervisorctl stop %s' % AgentName)
		run('supervisorctl reread %s' % AgentName)
		run('supervisorctl update %s' % AgentName)
		# with cd('/mnt/server/anti-cheat'):
		# 	run('chmod 777 build.sh csv2lua.sh')
		# 	run('./csv2lua.sh')
		run('supervisorctl start %s' % AgentName)

# 检查拳皇争霸状态
# cat *pvp_server-stdout*.log|grep " I "|grep "checkPlayEnd"|sort|awk '{s[$1]=$0}END{for (i in s) print s[i];}'
# cat *game_server-stdout*.log|grep " I "|grep "Craft onPlaying"|awk '{s[$1]=$0}END{for (i in s) print s[i];}'
# cat *game_server-stdout*.log|grep "Game Server Start OK"|grep '161227 20'
@parallel
# @roles('allgame')
@roles('cngame')
def _in_log(query):
	with cd(os.path.join(get_deploy_path(), 'childlog')):
		with settings(warn_only=True, timeout=600):
			query = '''
			export GREP_OPTIONS='--color'
			cat *game_server*.log|grep "): 338"|awk '{print $1, $3, $9}'|sort|uniq |awk '{print $1}'|sort|uniq -c
			'''
			return run(query.strip())


def in_log():
	result = execute(_in_log, '')
	for k in sorted(result.keys()):
		print '-'*20
		print k, ':'
		v = result[k]
		print v


def deploy_all_servers():
	if confirm("waiting for new_config_svn_ci. continue(y) or jump(n)?"):
		execute(new_config_svn_ci)

	if not confirm("waiting for close_login. continue(y) or stop(n)?"):
		abort("aborting at user request.")
	execute(close_login)

	if not confirm("waiting for close_all_servers. continue(y) or stop(n)?"):
		abort("aborting at user request.")
	execute(close_all_servers)
	ret = execute(status_all_servers)

	flag = False
	for x in ret:
		try:
			if x.split()[1] != 'STOPPED':
				print '!!!', x
				flag = True
		except:
			print '!!! exception', x

	if flag and not confirm("server not all stopped. continue?"):
		abort("aborting at user request.")

	if confirm("waiting for svn_up. continue(y) or jump(n)?"):
		execute(all_svn_up)

	if not confirm("waiting for start_all_servers. continue(y) or stop(n)?"):
		abort("aborting at user request.")
	execute(start_all_servers)

	time.sleep(2)
	execute(status_all_servers)

	flag = False
	for x in ret:
		if x.split()[1] != 'RUNNING':
			print '!!!', x
			flag = True

	if flag and not confirm("server not all running. continue?"):
		abort("aborting at user request.")

	if not confirm("waiting for start_login. continue(y) or stop(n)?"):
		abort("aborting at user request.")
	execute(start_login)

