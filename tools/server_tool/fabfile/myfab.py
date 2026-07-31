#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2019 TianJi Information Technology Inc.
'''

import sys

import fabfile

def parallel():
	pass

def main():
	method = sys.argv[1]
	print method
	func = getattr(fabfile, method)
	func()

if __name__ == "__main__":
	main()
