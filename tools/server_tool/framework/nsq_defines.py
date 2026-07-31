#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.

nsq default config defines
'''

from nsqrpc.defines import NSQLookups

LogReaderNSQDefs = {
	'lookupd_http_addresses': NSQLookups,
	'max_in_flight': 10,
}

LogWriterNSQDefs = {
	'nsqd_tcp_addresses': [
		'0.0.0.0:4150'
	],
}

