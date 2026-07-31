#-*- coding=utf-8 -*-
import os

choose = raw_input("choose(all): ")
print "please wait checking ..."
os.system('lua.exe main.lua %s > log.txt' % choose)

