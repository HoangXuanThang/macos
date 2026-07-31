#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import shutil
import json
import argparse
import hashlib
import platform
import datetime
import functools
from collections import deque

import tkFileDialog
import Tkinter as tk
import tkFont
from tkFileDialog import askdirectory
from tkMessageBox import showerror
from PIL import Image, ImageTk
import windnd

import tjlog

SRC_TRUNK_PATH = os.path.abspath(os.getcwd() + '/../..').replace('\\', '/')
RUN_GAME_PATH = os.path.abspath(SRC_TRUNK_PATH + '/client')
DEFAULT_UIJSON_PATH = os.path.abspath(SRC_TRUNK_PATH + '/client/application/res/dev/uijson')
LUA_VIEWS_PATH = os.path.abspath(SRC_TRUNK_PATH + '/client/application/src/app/views')
tjlog.info("SRC_TRUNK_PATH:", SRC_TRUNK_PATH)
tjlog.info("RUN_GAME_PATH:", RUN_GAME_PATH)
tjlog.info("DEFAULT_UIJSON_PATH:", DEFAULT_UIJSON_PATH)

class cd(object):
	def __init__(self, path):
		self.path = path
		self.orginpath = os.getcwd()

	def __enter__(self):
		os.chdir(self.path)

	def __exit__(self, exc_type, exc_value, exc_tb):
		os.chdir(self.orginpath)

def utf2local(s):
	if platform.system() == 'Windows':
		return s.decode('utf8').encode('gbk')
	return s

def createLua(filename):
	filename = utf2local(filename)
	tmp = '''
-- ui_json_run 初始工程显示

local TMP_VIEW = class("TMP_VIEW", cc.load("mvc").ViewBase)

TMP_VIEW.RESOURCE_FILENAME = "''' + filename + '''"
TMP_VIEW.RESOURCE_BINDING = {
}

function TMP_VIEW:onCreate()
	self:getResourceNode():setTouchEnabled(false)
end

return TMP_VIEW
'''
	return tmp

class Application(tk.Frame):
	def __init__(self, root):
		tk.Frame.__init__(self, root)
		self.root = root
		self.root.title("UI JSON 游戏内启动工具")
		self.root.geometry("550x300+600+300")
		self.root.rowconfigure(0, weight=1)
		self.root.columnconfigure(0, weight=1)
		# self.root.resizable(width=False, height=False)

		self.initWidgets()
		self.grid(row=0, column=0, sticky=tk.NSEW)
		self.queue = deque()
		self.onUpdate()

	def initWidgets(self):
		self.rowconfigure(0, weight=1)
		self.rowconfigure(1, weight=1)
		self.rowconfigure(2, weight=1)
		self.columnconfigure(0, weight=1)

		self.font = tkFont.Font(family='微软雅黑', size=24, weight='bold')
		self.artFile = tk.StringVar()
		self.srcPath = tk.StringVar()
		self.status = tk.StringVar()
		self.chvar1 = tk.IntVar()
		self.chvar2 = tk.IntVar()

		top = tk.Frame(self)
		top.grid(row=0, column=0, pady = 5, sticky=tk.NSEW)
		top.rowconfigure(0, weight=1)
		top.rowconfigure(1, weight=1)
		top.columnconfigure(0, weight=1)
		top.columnconfigure(1, weight=10)
		top.columnconfigure(2, weight=1)
		tk.Label(top, text='art下uijson文件:', justify=tk.LEFT).grid(row=0, column=0, padx=5)
		ent1 = tk.Entry(top, width=60, textvariable=self.artFile)
		ent1.columnconfigure(0, weight=1)
		ent1.grid(row=0, column=1, padx=5)
		windnd.hook_dropfiles(ent1, functools.partial(self.onDragDropFile, self.artFile))
		tk.Button(top, text="选择", width=10, command=functools.partial(self.onSelectFile, self.artFile)).grid(row =0, column=2, padx=5)
		tk.Label(top, text='src下uijson目录:', justify=tk.LEFT).grid(row=1, column=0, padx=5)
		self.srcPath.set(DEFAULT_UIJSON_PATH)
		tjlog.info(DEFAULT_UIJSON_PATH)
		ent2 = tk.Entry(top, width=60, textvariable=self.srcPath)
		ent2.grid(row=1, column=1, padx=5)
		windnd.hook_dropfiles(ent2, functools.partial(self.onDragDropPath, self.srcPath))
		tk.Button(top, text="选择", width=10, command=functools.partial(self.onSelectPath, self.srcPath)).grid(row =1, column=2, padx=5)

		mid = tk.Frame(self)
		mid.grid(row=1, column=0, sticky=tk.NSEW)
		mid.columnconfigure(0, weight=1)
		mid.columnconfigure(1, weight=1)
		check1 = tk.Checkbutton(mid, text="svn update", variable=self.chvar1)
		check1.select()
		check1.grid(row=2, column=0, pady=5)
		check2 = tk.Checkbutton(mid, text="显示空json", variable=self.chvar2)
		check2.select()
		check2.grid(row=2, column=1, pady=5)

		bot = tk.Frame(self)
		bot.grid(row=2, column=0, pady = 5, sticky=tk.NSEW)
		bot.columnconfigure(0, weight=1)
		bot.rowconfigure(0, weight=1)
		bot.rowconfigure(1, weight=1)
		tk.Button(bot, text='启 动', width=5, font=self.font, command=self.run).grid(row=0, column=0, padx=50, pady=5, ipadx=200, ipady=10)

		self.status.set(u"准备就绪")
		tk.Label(bot, textvariable=self.status).grid(row=1, column=0, sticky=tk.S)

	def onUpdate(self):
		while len(self.queue) > 0:
			task = self.queue.popleft()
			task()
		self.after(100, self.onUpdate)

	def onDragDropPath(self, path, dndPath):
		tjlog.info(dndPath, isFile)
		if dndPath:
			dndPath = dndPath[0]
			if not os.path.isdir(dndPath):
				dndPath = os.path.dirname(dndPath)
			self.queue.append(lambda: path.set(dndPath.decode('gbk')))

	def onDragDropFile(self, path, dndPath):
		if dndPath:
			dndPath = dndPath[0]
			self.queue.append(lambda: path.set(dndPath.decode('gbk')))

	def onSelectPath(self, path):
		path_ = askdirectory(initialdir=path.get())
		if len(path_) > 0:
			path.set(path_)
			self.status.set(u"准备就绪")

	def onSelectFile(self, file):
		path_ = file.get()
		if not os.path.isdir(path_):
			path_ = os.path.dirname(path_)
		file_ = tkFileDialog.askopenfilename(title=u"选择文件", initialdir=path_)
		if len(file_) > 0:
			file.set(file_)
			self.status.set(u"准备就绪")

	def run(self):
		if self.chvar1.get() == 1:
			with cd(SRC_TRUNK_PATH):
				os.system('svn update')

		artFile = self.artFile.get()
		srcPath = self.srcPath.get()
		info = ""
		if artFile:
			tjlog.info(u"art下uijson文件:", artFile)
			if not os.path.exists(artFile):
				showerror(u'错误', u"目录不存在 " + artFile, parent=self)
				return
			tjlog.info(u"src下uijson目录:", srcPath)
			if not os.path.exists(srcPath):
				showerror(u'错误', u"目录不存在 " + srcPath, parent=self)
				return
			shutil.copy(artFile, srcPath)
			info = info + u"复制成功 "
			tjlog.info(info)

			if self.chvar2.get() == 1:
				# 启动显示空 uijson , 生成对应 lua
				with open("tmp.lua", 'w') as fp:
					filename = os.path.basename(artFile)
					fp.write(createLua(filename))
				shutil.copy("tmp.lua", LUA_VIEWS_PATH)

		with cd(RUN_GAME_PATH):
			os.system("setup_game01_new.bat")

		info = info + u"游戏已启动"
		tjlog.info(info)
		self.status.set(info)

def main():
	root = tk.Tk()
	app = Application(root)
	root.mainloop()

if __name__ == '__main__':
	main()
