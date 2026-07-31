#!/usr/bin/python
# -*- coding: utf-8 -*-

# redis-cli -p 19379 -h 123.206.211.90 -a hztjredis_shuma_huangwei config set stop-writes-on-bgsave-error no

import os

SERVER_IPS = [
	'115.159.183.222',
	'115.159.83.118',
	'115.159.44.187',
	'115.159.125.78',
	'115.159.102.209',
	'115.159.3.100',
	'115.159.22.50',
	'115.159.99.91',
	'115.159.36.101',
	'115.159.59.152',
	'182.254.216.172',
	'182.254.241.252',
	'115.159.200.184',
	'115.159.185.23',
	'115.159.145.94',
	'115.159.62.109',
	'123.206.211.90',
]


PORT = [
	10379, 17379
]

def main():
	for ip in SERVER_IPS:
		for port in xrange(10379, 17379+1000, 1000):
			cmd = 'redis-cli -p %d -h %s -a hztjredis_shuma_huangwei config set stop-writes-on-bgsave-error no' % (port, ip)
			print cmd
			os.system(cmd)

if __name__ == '__main__':
	main()