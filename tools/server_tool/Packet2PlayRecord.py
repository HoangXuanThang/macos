#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import msgpack

def packet_to_record(filename):
	with open(filename, 'rb') as fp:
		data = fp.read()
	d = msgpack.unpackb(data)
	print d.keys()
	if d.get('model', {}).get('pw_playrecords', None) is None:
		print 'it is not pvp play record'
		return
	for playID, d in d['model']['pw_playrecords'].iteritems():
		print playID
		with open('%d.record' % playID, 'wb') as fp:
			data = msgpack.packb(d, use_bin_type=True)
			fp.write(data)

def main():
	for x in ('3.packet', '4.packet', '5.packet', '6.packet'):
		packet_to_record(x)

if __name__ == '__main__':
	main()