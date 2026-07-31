#!/usr/bin/python
# -*- coding: utf-8 -*-

namePrefixs = set()
names = set()

def readCache():
	global namePrefixs
	global names

	with open('names.txt', 'rb') as fp:
		lines = fp.readlines()
		for x in lines:
			names.add(x.strip())
	with open('namePrefixs.txt', 'rb') as fp:
		lines = fp.readlines()
		for x in lines:
			namePrefixs.add(x.strip())

	print 'readCache', len(namePrefixs), len(names)


def main():
	readCache()

	with open('names.py', 'wb') as fp:
		fp.write('# namePrefixs %d * names %d = %d\n' % (len(namePrefixs), len(names), len(namePrefixs) * len(names)))
		fp.write('names = (%s)\nnamePrefixs = (%s)\n' % (','.join(["'%s'" % x for x in names]), ','.join(["'%s'" % x for x in namePrefixs])))


if __name__ == '__main__':
	main()