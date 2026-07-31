#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2015 YouMi Information Technology Inc.
'''

import os
import time
import pprint

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

	'machines': {
		'hosts': [
			'shuma23',
			'shuma24',
			# 'shuma-tw11',
		],
	},
}


Language = 'cn'
# Language = 'tw'

if Language == 'tw':
	DeployName = 'deploy_tw'
	ServerININameList = ['tw_%02d_game_server.ini', 'tw_%02d_pvp_server.ini', 'tw_%02d_game_db_server.ini']
else:
	DeployName = 'deploy_qq'
	ServerININameList = ['%02d_game_server.ini', '%02d_pvp_server.ini', '%02d_game_db_server.ini']


ServerIDMap = {
	'shuma23': (201, 208),
	'shuma24': (209, 216),
	# 'shuma-tw11': (11, 11),
}

DBFileName = 'game160816_dbs.tar.gz'



def get_deploy_path():
	ret = run('ls -d /mnt/deploy*')
	if len(str(ret).split()) != 1:
		abort("deploy dictionary can not be determinately!")
	return ret


@parallel
@roles('machines')
def setup_sh_env():
	with settings(warn_only=True):
		ret = run('''cat ~/.bashrc|grep "export LS_OPTIONS='-Sh --color=auto'"''')
		if ret.failed:
			run('''
				echo "export LS_OPTIONS='-Sh --color=auto'" >> ~/.bashrc
				echo "export GREP_OPTIONS='-n --color'" >> ~/.bashrc
				echo 'eval "`dircolors`"' >> ~/.bashrc
				echo "alias ls='ls $LS_OPTIONS'" >> ~/.bashrc
				echo "alias ll='ls $LS_OPTIONS -l'" >> ~/.bashrc
				echo "alias l='ls $LS_OPTIONS -lA'" >> ~/.bashrc
				echo "alias rm='rm -i'" >> ~/.bashrc
				echo "alias cp='cp -i'" >> ~/.bashrc
				echo "alias mv='mv -i'" >> ~/.bashrc
			''')

		# coredump
		run('echo "*          soft     core   unlimited" >> /etc/security/limits.conf')
		run('echo 1 > /proc/sys/kernel/core_uses_pid')
		run('echo "/tmp/corefile-%e-%p-%t" > /proc/sys/kernel/core_pattern')

		# ipv6
		run('sysctl -w net.ipv6.conf.all.disable_ipv6=0')
		run('sysctl -w net.ipv6.conf.default.disable_ipv6=0')
		run('sysctl -w net.ipv6.conf.eth0.disable_ipv6=0')
		run('sysctl -w net.ipv6.conf.lo.disable_ipv6=0')

		run('apt-get update')
		run('apt-get install zsh -y')
		run('apt-get install git -y')

		ret = run('ls .oh-my-zsh')
		if ret.failed:
			while True:
				ret = run('sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"')
				if ret:
					break

		ret = run(''' cat ~/.zshrc|grep 'ZSH_THEME="ys"' ''')
		if ret.failed:
			run('sed -i "s/robbyrussell/ys/g" ~/.zshrc')
			run('chsh -s /bin/zsh')

@parallel
@roles('machines')
def setup_disk():
	with settings(warn_only=True):
		ret = run('fdisk -l|grep /dev/vdb1')
		if not ret:
			run('echo "n\np\n1\n\n\nwq\n\n"|fdisk -S 56 /dev/vdb')
			run('mkfs.ext4 /dev/vdb1 -F')
			ret = run('cat /etc/fstab|grep /dev/vdb1')
			if not ret:
				run("echo '/dev/vdb1  /mnt ext4    defaults    0  0' >> /etc/fstab")
			run('mount -a')

@parallel
@roles('machines')
def setup_svn_db():
	with settings(warn_only=True):
		with cd('~'):
			ret = run('which redis-server')
			if ret.failed:
				put(os.path.join(os.getcwd(), 'redis-2.8.19.tar.gz'), '~/redis-2.8.19.tar.gz')
				run('rm -r redis-2.8.19')
				run('gzip -d redis-2.8.19.tar.gz')
				run('tar xvf redis-2.8.19.tar')
				with cd('~/redis-2.8.19'):
					run('make install')

		with cd('/mnt/'):
			ret = run('ls %s' % DeployName)
			if ret.failed:
				run('sed -i "s/# store-plaintext-passwords = no/store-plaintext-passwords = yes/g" ~/.subversion/servers')
				run('sed -i "s/# store-passwords = no/store-passwords = yes/g" ~/.subversion/servers')

				run('svn co svn://localhost/svn/shuma_src/trunk/config/%s --username huangwei --password 05901111' % DeployName)

			ret = run('ls server')
			if ret.failed:
				run('svn co svn://localhost/svn/shuma_src/trunk/server --username huangwei --password 05901111')
				run('svn co svn://localhost/svn/shuma_src/trunk/tools/server_tool --username huangwei --password 05901111')

		with cd('/mnt/server'):
			run('svn cleanup')
			run('svn up')
			ret = run(''' cat dev_patch.py|grep "#framework.__dev__ = True" ''')
			if ret.failed:
				run('sed -i "s/framework.__dev__/#framework.__dev__/g" dev_patch.py')
			ret = run(''' cat dev_patch.py|grep "framework.__language__ = '%s'" ''' % Language)
			if ret.failed:
				run(''' sed -i "s/framework.__language__ = '.*'/framework.__language__ = '%s'/g" dev_patch.py ''' % Language)

		with cd('/mnt/server/anti-cheat/game_scripts'):
			ret = run(''' cat main.lua|grep "LOCAL_LANGUAGE = '%s'" ''' % Language)
			if ret.failed:
				run(''' sed -i "s/LOCAL_LANGUAGE = '.*'/LOCAL_LANGUAGE = '%s'/g" main.lua ''' % Language)

		with cd('/mnt/%s/db' % DeployName):
			ret = run('ls %s' % DBFileName)
			if ret.failed:
				put(os.path.join(os.getcwd(), DBFileName), DBFileName)
				run('tar -xzf %s' % DBFileName)

				serverIDRange = ServerIDMap[env.host_string]
				redisCount = serverIDRange[1] - serverIDRange[0] + 1
				for i in xrange(10 + 1, 10 + redisCount):
					redisName = 'game%d379.rdb' % i
					run('cp game10379.rdb %s' % redisName)

@parallel
@roles('machines')
def setup_aptget():
	run('apt-get update')
	libs = (
		'subversion',
		'build-essential',
		'lib32stdc++6',
		'gcc-multilib',
		'g++-multilib',
		'python-dev',
		'pypy-dev',
		'gdb',
		'python2.7-dbg',
		'libcurl4-openssl-dev',
		'graphviz',
		'openssl',
		'libssl-dev',
		'swig',
		'gawk',
		'iftop',
		'ifstat',
		'htop',
		'dstat',
		'iotop',
		'ltrace',
		'strace',
		'sysstat',
	)
	for lib in libs:
		run('apt-get install %s -y' % lib)


@parallel
@roles('machines')
def setup_pip():
	with cd('~'):
		put(os.path.join(os.getcwd(), 'get-pip.py'), '~/get-pip.py')
		run('python get-pip.py')
		run('pip install --upgrade pip')
		libs = (
			'supervisor',
			'cython',
			'six',
			'lz4',
			'xdot',
			'rpdb',
			'psutil',
			'pycurl',
			'pycrypto',
			'M2Crypto',
			'objgraph',
			'msgpack-python',
			'backports.ssl-match-hostname',
			'tornado',
			'toro',
		)
		for lib in libs:
			with settings(warn_only=True):
				while True:
					ret = run('pip install %s' % lib)
					if not ret.failed:
						break


@parallel
@roles('machines')
def setup_supervisor():
	with cd(os.path.join(get_deploy_path(), 'supervisord.dir')):
		# 删除多余的redis配置
		serverIDRange = ServerIDMap[env.host_string]
		redisCount = serverIDRange[1] - serverIDRange[0] + 1
		redisNames = []
		for i in xrange(10, 10 + redisCount):
			redisNames.append('redis%d379.ini' % i)
			redisNames.append('redis%d380.ini' % i)
		allRedis = run('ls redis*')
		allRedis = set(allRedis.split())
		needDelRedis = allRedis - set(redisNames)
		if needDelRedis:
			run('rm -f %s' % ' '.join(needDelRedis))

		# 删除多余的game和pvp配置
		ret = run('ls *_game_server.ini').split() + run('ls *_pvp_server.ini').split() + run('ls *_game_db_server.ini').split()
		allGame = set(ret)
		for sid in xrange(serverIDRange[0], serverIDRange[1] + 1):
			for fmt in ServerININameList:
				name = fmt % sid
				allGame.discard(name)
		if allGame:
			run('rm -f %s' % ' '.join(allGame))

		# 删除cross配置
		ret = run('ls *_cross_server.ini').split() + run('ls *_cross_db_server.ini').split()
		allGame = set(ret)
		if allGame:
			run('rm -f %s' % ' '.join(allGame))

	# 编译agent
	with cd('/mnt/server/anti-cheat'):
		run('chmod 777 build.sh csv2lua.sh')
		run('rm -f agent')
		run('./build.sh')
		run('./csv2lua.sh')


@parallel
@roles('machines')
def setup_startserv():
	serverIDRange = ServerIDMap[env.host_string]
	redisCount = serverIDRange[1] - serverIDRange[0] + 1
	# 启动redis
	with cd(get_deploy_path()):
		with settings(warn_only=True):
			run('supervisord')
		time.sleep(1)
		redisNames = []
		for i in xrange(10, 10 + redisCount):
			redisNames.append('redis%d379' % i)
		run('supervisorctl start %s' % ' '.join(redisNames))
		redisNames = []
		for i in xrange(10, 10 + redisCount):
			redisNames.append('redis%d380' % i)
		run('supervisorctl start %s' % ' '.join(redisNames))

	# 启动db, pvp, game
	with cd(get_deploy_path()):
		with settings(warn_only=True):
			run('supervisord')
		for fmt in reversed(ServerININameList):
			fmt = fmt[:-4] # remove .ini
			for sid in xrange(serverIDRange[0], serverIDRange[1] + 1):
				servName = fmt % sid
				run('supervisorctl start %s' % servName)
			time.sleep(1)


@parallel
@roles('machines')
def test_env():
	ret = run('sysctl -a|grep "net.ipv6.conf.eth0.disable_ipv6 = 0"')
	if ret.failed:
		print '!!! Err in redis-server'

	ret = run('which redis-server')
	if ret.failed:
		print '!!! Err in redis-server'

	ret = run('python -c "import msgpack;print msgpack.Packer"')
	if ret.find('fallback') >= 0:
		print '!!! Err in msgpack'

	with cd('/mnt/server'):
		ret = run(''' cat dev_patch.py|grep "#framework.__dev__ = True" ''')
		if not ret:
			print '!!! Err in __dev__'

	with cd('/mnt/server'):
		ret = run(''' cat dev_patch.py|grep "framework.__language__" ''')

	with cd('/mnt/server/anti-cheat/game_scripts'):
		ret = run(''' cat main.lua|grep "LOCAL_LANGUAGE =" ''')


def all_setup():
	execute(setup_sh_env)
	execute(setup_disk)
	execute(setup_aptget)
	execute(setup_pip)
	execute(setup_svn_db)
	execute(setup_supervisor)
	execute(setup_startserv)
	execute(test_env)
