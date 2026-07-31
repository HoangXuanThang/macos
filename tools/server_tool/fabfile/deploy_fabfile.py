#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2025 Nexus Information Technology Inc.
'''

import os
import sys
import time
import pprint

from fabric import *
from env import config
from functools import wraps

roledefs = {
	'localhost': ['heat02', 'heat03'],
	# 'machines': ['tc-pokemon-cn-mq', 'tc-pokemon-cn-login', 'tc-pokemon-cn-01'],
	'machines': [
		'tc-pokemon-cn-02',
	],
}

Language = 'cn'
DeployName = 'deploy_cn'

SVNVersion = None
CSVVersion = None

def get_deploy_path():
	ret = run('ls -d /mnt/deploy*')
	if len(str(ret).split()) != 1:
		abort("deploy dictionary can not be determinately!")
	return ret

class parallel(object):
	def __init__(self, hosts=None):
		self.hosts = hosts

	def __call__(self, func):
		@wraps(func)
		def _warp():
			group = ThreadingGroup(*self.hosts, config=config)
			result = {}
			for cxn in group:
				result[cxn.original_host] = func(cxn)
			return result
		return _warp

# @task('tc-pokemon-cn-02')
@parallel(hosts=roledefs['machines'])
def setup_sh_env(c):
	# print c.run('hostname')
	ret = c.run('''cat ~/.bashrc|grep "export LS_OPTIONS='-Sh --color=auto'"''')
	if ret.exited != 0:
		c.run('''
echo "export LANG=en_US.UTF-8" >> ~/.bashrc
echo "export LS_OPTIONS='-Sh --color=auto'" >> ~/.bashrc
echo "export GREP_OPTIONS='-n --color'" >> ~/.bashrc
echo 'eval "`dircolors`"' >> ~/.bashrc
echo "alias ls='ls $LS_OPTIONS'" >> ~/.bashrc
echo "alias ll='ls $LS_OPTIONS -l'" >> ~/.bashrc
echo "alias l='ls $LS_OPTIONS -lA'" >> ~/.bashrc
echo "alias rm='rm -i'" >> ~/.bashrc
echo "alias cp='cp -i'" >> ~/.bashrc
echo "alias mv='mv -i'" >> ~/.bashrc

echo "export LANG=en_US.UTF-8" >> ~/.bashrc
echo "export LC_ALL=C" >> ~/.bashrc
echo "export TZ='Asia/Shanghai'" >> ~/.bashrc
		''')

	# timezone
	c.run('ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime')
	c.run('echo Asia/Shanghai > /etc/timezone')

	# coredump
	c.run('ulimit -c unlimited')
	c.run('echo "*          soft     core   unlimited" >> /etc/security/limits.conf')
	c.run('echo "*          hard     nofile   unlimited" >> /etc/security/limits.conf')
	c.run('echo 1 > /proc/sys/kernel/core_uses_pid')
	c.run('echo "/tmp/corefile-%e-%p-%t" > /proc/sys/kernel/core_pattern')

	# ipv6
	c.run('sysctl -w net.ipv6.conf.all.disable_ipv6=0')
	c.run('sysctl -w net.ipv6.conf.default.disable_ipv6=0')
	c.run('sysctl -w net.ipv6.conf.eth0.disable_ipv6=0')
	c.run('sysctl -w net.ipv6.conf.lo.disable_ipv6=0')

	c.run('apt-get update')
	c.run('apt-get install zsh -y')
	c.run('apt-get install git -y')

	ret = c.run('ls .oh-my-zsh')
	if ret.exited != 0:
		while True:
			ret = c.run('sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"')
			if ret:
				break

	ret = c.run(''' cat ~/.zshrc|grep 'ZSH_THEME="ys"' ''')
	if ret.exited != 0:
		c.run('sed -i "s/robbyrussell/ys/g" ~/.zshrc')
	ret = c.run(''' cat ~/.zshrc ''')
	if ret.exited == 0:
		c.run('chsh -s /bin/zsh')

@parallel(hosts=roledefs['machines'])
# @task(hosts=roledefs['machines'])
def setup_disk(c):
	vdevice = 'vdb'
	ret = c.run('fdisk -l|grep /dev/%s1' % vdevice)
	if ret.exited != 0:
		c.run('echo "n\np\n1\n\n\nwq\n\n"|fdisk -S 56 /dev/%s' % vdevice)
		c.run('mkfs.ext4 /dev/%s1 -F' % vdevice)
		ret = c.run('cat /etc/fstab|grep /dev/%s1' % vdevice)
		if ret.exited != 0:
			c.run("echo '/dev/%s1  /mnt ext4    defaults    0  0' >> /etc/fstab" % vdevice)
		c.run('mount -a')

# @task(hosts=roledefs['machines'])
@parallel(hosts=roledefs['machines'])
def setup_aptget(c):
	c.run('apt-get update')
	libs = (
		'expect',
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
		'iotop',
		'lsof',
		'iftop',
		'ifstat',
		'iptraf',
		'htop',
		'dstat',
		'iotop',
		'ltrace',
		'strace',
		'sysstat',
		'bmon',
		'nethogs',
		'silversearcher-ag',
		'libsasl2-2',
		'sasl2-bin',
		'libsasl2-modules',
	)
	for lib in libs:
		c.run('apt-get install %s -y' % lib)

# @task(hosts=roledefs['machines'])
@parallel(hosts=roledefs['machines'])
def setup_pip(c):
	c.put(os.path.join(os.getcwd(), 'get-pip.py'), '/root/get-pip.py')
	c.run('cd ~ && python get-pip.py')
	# c.run('pip install --upgrade pip')
	libs = (
		'supervisor',
		'cython',
		'six',
		('lz4', "0.8.2"),
		('numpy', "1.16.0"),
		'xlrd',
		'xdot',
		'rpdb',
		'psutil',
		'fabric', # apt-get remove python-cryptography python-cffi
		'pycurl',
		'pycrypto',
		'M2Crypto',
		'objgraph',
		'msgpack-python',
		'backports.ssl-match-hostname',
		('tornado', "5.1.1"),
		'Markdown', # toro?
		('toro', "1.0.1"),
		'pymongo',
		'pyrasite',
		# 'pyopenssl',
	)

	# AttributeError: 'module' object has no attribute 'SSL_ST_INIT'
	# c.run('rm -rf /usr/lib/python2.7/dist-packages/OpenSSL')
	# c.run('rm -rf /usr/lib/python2.7/dist-packages/pyOpenSSL-0.15.1.egg-info')

	for lib in libs:
		while True:
			if isinstance(lib, str):
				cmd = 'pip install %s' % lib
			else:
				cmd = 'pip install -v %s==%s' % lib
			ret = c.run(cmd)
			if ret.exited == 0:
				break

# @task(hosts=roledefs['machines'])
@parallel(hosts=roledefs['machines'])
def setup_svn_db(c):
	if True:
	# with c.forward_remote(local_port=3690, local_host="192.168.1.125", remote_port=3690):
		svnPrefix = 'svn://localhost/svn/pokemon_src'
		with c.cd('/mnt'):
			ret = c.run('ls release')
			if ret.exited != 0:
				c.run('sed -i "s/# store-plaintext-passwords = no/store-plaintext-passwords = yes/g" ~/.subversion/servers')
				c.run('sed -i "s/# store-passwords = no/store-passwords = yes/g" ~/.subversion/servers')
				c.run('sed -i "s/# store-passwords = no/store-passwords = yes/g" ~/.subversion/config')

				c.run('svn co %s/release --username test --password 123456' % svnPrefix)

			ret = c.run('ls %s' % DeployName)
			if ret.exited != 0:
					c.run('svn co %s/trunk/deploy/%s --username test --password 123456' % (svnPrefix, DeployName))

		with c.cd('/mnt/release'):
			if SVNVersion is None:
				c.run('svn up')
				if CSVVersion is not None:
					c.run('svn up -r %d config_csv.py' % CSVVersion)
			else:
				c.run('svn up -r %d' % SVNVersion)
				if CSVVersion is None:
					c.run('svn up config_csv.py')
				else:
					c.run('svn up -r %d config_csv.py' % CSVVersion)

			ret = c.run(''' cat dev_patch.py|grep "#framework.__dev__ = True" ''')
			if ret.exited != 0:
				c.run('sed -i "s/framework.__dev__/#framework.__dev__/g" dev_patch.py')
			ret = c.run(''' cat dev_patch.py|grep "framework.__language__ = '%s'" ''' % Language)
			if ret.exited != 0:
				c.run(''' sed -i "s/framework.__language__ = '.*'/framework.__language__ = '%s'/g" dev_patch.py ''' % Language)

	if True:
	# with c.forward_remote(local_port=443, local_host="192.168.1.251", remote_port=3000):
		with c.cd('/mnt/release'):
			c.run('bash deploy.sh release')

@parallel(hosts=roledefs['machines'])
def setup_mongodb(c):
	c.put(os.path.join(os.getcwd(), '../mongodb-org-shell_3.6.14_amd64.deb'), '/root/mongodb-org-shell_3.6.14_amd64.deb')
	c.put(os.path.join(os.getcwd(), '../mongodb-org-tools_3.6.14_amd64.deb'), '/root/mongodb-org-tools_3.6.14_amd64.deb')
	c.put(os.path.join(os.getcwd(), '../191204_cn_dbs.tar.gz'), '/root/191204_cn_dbs.tar.gz')

	# mongorestore --uri "mongodb://gamesystem:123456:27017/game_cn_5?authMechanism=SCRAM-SHA-1&authSource=admin" --gzip dump
	# db.getCollection('ArenaGlobal').update({}, {"$set": {"key": "game.cn.5"}})

@task(hosts=roledefs['machines'])
def setup_supervisor(c):
	with c.cd(os.path.join(get_deploy_path(), 'supervisord.dir')):
		# TODO: 删除多余的配置
		pass

@task(hosts=roledefs['machines'])
def setup_startserv(c):
	pass

# @task(hosts=roledefs['machines'])
@parallel(hosts=roledefs['machines'])
def test_env(c):
	ret = c.run('sysctl -a|grep "net.ipv6.conf.eth0.disable_ipv6 = 0"')
	if ret.exited != 0:
		print '!!! Err in ipv6'

	ret = c.run('cat /etc/timezone')
	if ret.stdout.strip() != 'Asia/Shanghai':
		print '!!! Err in timezone'

	ret = c.run('python -c "import datetime;print datetime.datetime.fromtimestamp(0)"')
	if ret.stdout.strip() != "1970-01-01 08:00:00":
		print '!!! Err in timezone'

	ret = c.run('python -c "import msgpack;print msgpack.Packer"')
	if ret.stdout.find('fallback') >= 0:
		print '!!! Err in msgpack'

	# ret = c.run('which redis-server')
	# if ret.exited != 0:
	# 	print '!!! Err in redis-server'

	# with cd('/mnt/server'):
	# 	ret = c.run(''' cat dev_patch.py|grep "#framework.__dev__ = True" ''')
	# 	if not ret:
	# 		print '!!! Err in __dev__'

	# with cd('/mnt/server'):
	# 	ret = c.run(''' cat dev_patch.py|grep "framework.__language__" ''')

	# with cd('/mnt/server/anti-cheat/game_scripts'):
	# 	ret = c.run(''' cat main.lua|grep "LOCAL_LANGUAGE =" ''')

# @task(hosts=['heat02', 'heat03'])
@task(hosts=['tc-pokemon-cn-02'])
def test(c):
	print "test!!!!", c, type(c)
	print c.run('hostname')

def main():

	print('========')
	# r = Connection('heat02', config=config).run('hostname')
	# print type(r)
	# print('command====', r.command)
	# print('stdout====', r.stdout)
	# print('========')

	# print Connection('tc-pokemon-cn-mq', config=config).run('hostname')

	# test(Connection('heat02', config=config))

	c = Connection('tc-pokemon-cn-02', config=config)
	setup_disk(c)

	# print SerialGroup('web1', 'web2').run('hostname')

if __name__ == '__main__':
	# main()

	method = sys.argv[1]
	print method
	mod = sys.modules[__name__]
	func = getattr(mod, method)
	func()
