#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import json
import argparse
import hashlib
import platform
import datetime
import functools
from collections import deque

import Tkinter as tk
import tkFont
from tkFileDialog import askdirectory
from tkMessageBox import showerror
from PIL import Image, ImageTk
import windnd

import tjlog


LOG_FILE = "finder_%s.log"
CACHE_MD5_FILE = "file_infos.txt"


def utf2local(s):
	if platform.system() == 'Windows':
		return s.decode('utf8').encode('gbk')
	return s

def listFiles(rootDir):
	list_dirs = os.walk(rootDir)
	list_ret = []
	for root, dirs, files in list_dirs:
		for f in files:
			if f.find('.svn') >= 0:
				continue
			list_ret.append(os.path.join(root, f))
	return list_ret

def checkFile(filePath):
	stat = os.stat(filePath)
	with open(filePath, "rb") as fp:
		data = fp.read()
	m = hashlib.md5()
	m.update(data)
	md5 = m.hexdigest()
	return {
		'size': stat.st_size,
		'md5': md5,
	}

def makeSrcCache(srcPath, cacheFile=True):
	cache, newCache = {}, {}
	path = os.path.join(srcPath, CACHE_MD5_FILE)
	if cacheFile and os.path.exists(path):
		try:
			with open(path, "rb") as fp:
				cache = json.load(fp)
		except:
			pass
		os.remove(path)

	files = listFiles(srcPath)
	for file in files:
		relPath = os.path.relpath(file, srcPath).decode('gbk')
		stat = os.stat(file)
		info = cache.get(relPath, None)
		if info:
			if info['size'] != stat.st_size:
				info = checkFile(file)
				if cacheFile:
					tjlog.debug(u"src更新:", relPath, info)
		else:
			info = checkFile(file)
			if cacheFile:
				tjlog.debug(u"src新增:", relPath, info)
		newCache[relPath] = info

	if cacheFile:
		removes = set(cache.keys()) - set(newCache.keys())
		for key in removes:
			tjlog.debug(u"src删除:", key)

		with open(path, "wb") as fp:
			json.dump(newCache, fp)
		tjlog.info(u"src cache已刷新")
	return newCache

def diffWithArt(artPath, cache):
	md5s = {v['md5'] : k for k, v in cache.iteritems()}
	files = listFiles(artPath)
	exists = []
	ret = []
	for file in files:
		info = checkFile(file)
		key = md5s.get(info['md5'])
		if key:
			exists.append((file, key))
		else:
			tjlog.info(u"art新增:", file.decode('gbk'))
			ret.append((u"新增:", u"[art] " + os.path.relpath(file, artPath).decode('gbk')))

	for file, key in exists:
		tjlog.warning(u"src存在:", os.path.relpath(file, artPath).decode('gbk'), "-->", key)
		ret.append((u"存在:", u"[art] %s --> [src] %s" % (os.path.relpath(file, artPath).decode('gbk'), key)))
		os.remove(file)

	return ret

def main():
	parser = argparse.ArgumentParser(description=u'UI切图移动工具')
	parser.add_argument('--art', default='./', help=u'art美术切图目录')
	parser.add_argument('--src', default='../../../../pokemon_src/trunk/client/application/res/resources', help=u'src下res存放目录')
	args = parser.parse_args()

	artPath = os.path.abspath(args.art)
	srcPath = os.path.abspath(args.src)

	tjlog.info(u"art美术切图目录", artPath.decode('gbk'))
	if not os.path.exists(artPath):
		raise Exception("not exist " + artPath)
	tjlog.info(u"src存放目录", srcPath.decode('gbk'))
	if not os.path.exists(srcPath):
		raise Exception("not exist " + srcPath)

	cache = makeSrcCache(srcPath)
	tjlog.info("-"*30)
	diffWithArt(artPath, cache)

	tjlog.debug(u"log文件:", logFile)
	raw_input(utf2local("按任意键退出"))


class Application(tk.Frame):
	def __init__(self, root):
		tk.Frame.__init__(self, root)
		self.root = root
		self.root.title("UI切图移动定位工具")
		self.root.geometry("600x600+500+200")
		self.root.rowconfigure(0, weight=1)
		self.root.columnconfigure(0, weight=1)
		# self.root.resizable(width=False, height=False)

		self.initWidgets()
		self.grid(row=0, column=0, sticky=tk.NSEW)
		self.queue = deque()
		self.onUpdate()

	def initWidgets(self):
		self.rowconfigure(0, weight=1)
		self.rowconfigure(1, weight=10)
		self.columnconfigure(0, weight=1)

		self.font = tkFont.Font(family='微软雅黑', size=12, weight='bold')
		self.artPath = tk.StringVar()
		self.srcPath = tk.StringVar()
		self.status = tk.StringVar()
		self.imageInfo = tk.StringVar()

		top = tk.Frame(self)
		top.grid(row=0, column=0, sticky=tk.NSEW)
		bot = tk.Frame(self)
		bot.grid(row=1, column=0, pady=10, sticky=tk.NSEW)

		top.rowconfigure(0, weight=1)
		top.columnconfigure(0, weight=1)
		top.columnconfigure(1, weight=10)
		top.columnconfigure(2, weight=1)
		top.columnconfigure(3, weight=1)
		tk.Label(top, text='art美术切图目录:', justify=tk.LEFT).grid(row=0, column=0)
		ent1 = tk.Entry(top, width=30, textvariable=self.artPath)
		ent1.grid(row=0, column=1)
		windnd.hook_dropfiles(ent1, functools.partial(self.onDragDropPath, self.artPath))
		tk.Button(top, text="选择", command=functools.partial(self.onSelectPath, self.artPath)).grid(row =0, column=2)
		tk.Label(top, text='src下res存放目录:', justify=tk.LEFT).grid(row=1, column=0)
		ent2 = tk.Entry(top, width=30, textvariable=self.srcPath)
		ent2.grid(row=1, column=1)
		windnd.hook_dropfiles(ent2, functools.partial(self.onDragDropPath, self.srcPath))
		tk.Button(top, text="选择", command=functools.partial(self.onSelectPath, self.srcPath)).grid(row =1, column=2)

		tk.Button(top, text='检 查', width=5, font=self.font, command=self.run).grid(row=0, column=3, rowspan=2, padx=20)

		bot.rowconfigure(0, weight=100)
		bot.rowconfigure(1, weight=1)
		bot.rowconfigure(2, weight=1)
		bot.rowconfigure(3, weight=1)
		bot.columnconfigure(0, weight=1)
		frmList = tk.LabelFrame(bot, text="图片列表")
		frmList.rowconfigure(0, weight=1)
		frmList.columnconfigure(0, weight=1)
		frmList.grid(row=0, column=0, sticky=tk.NSEW)
		windnd.hook_dropfiles(frmList, self.onDragDropImage)
		self.yScroll = tk.Scrollbar(frmList, orient=tk.VERTICAL)
		self.yScroll.grid(row=0, column=1, sticky="ns")
		self.xScroll = tk.Scrollbar(frmList, orient=tk.HORIZONTAL)
		self.xScroll.grid(row=1, column=0, sticky="ew")
		self.listbox = tk.Listbox(frmList, xscrollcommand=self.xScroll.set, yscrollcommand=self.yScroll.set)
		self.listbox.bind("<ButtonRelease-1>", self.onClickList)
		self.listbox.grid(row=0, column=0, sticky=tk.NSEW)
		self.xScroll['command'] = self.listbox.xview
		self.yScroll['command'] = self.listbox.yview
		tk.Label(bot, textvariable=self.status, justify=tk.LEFT).grid(row=1, column=0, sticky=tk.EW)

		self.preview = tk.Label(bot, height=100)
		self.preview.grid(row=2, column=0)
		self.preview.grid_forget()

		self.imageInfo.set(u"定位请将图片拖入列表框")
		self.lblImageInfo = tk.Label(bot, textvariable=self.imageInfo)
		self.lblImageInfo.grid(row=3, column=0)

	def showPreview(self, path):
		try:
			image = Image.open(path)
			photo = ImageTk.PhotoImage(image)
		except Exception, e:
			showerror(u'错误', u"图片无法加载预览", parent=self)
			return False

		self.preview.photo = photo
		self.preview.config(image=photo) # , height=min(100, image.size[1])
		self.preview.grid(row=2, column=0)

		self.imageInfo.set(str(image))
		self.lblImageInfo.grid(row=3, column=0)
		return True

	def onUpdate(self):
		while len(self.queue) > 0:
			task = self.queue.popleft()
			task()
		self.after(100, self.onUpdate)

	def onDragDropPath(self, path, dndPath):
		if dndPath:
			dndPath = dndPath[0]
			if not os.path.isdir(dndPath):
				dndPath = os.path.dirname(dndPath)
			self.queue.append(lambda: path.set(dndPath.decode('gbk')))

	def onDragDropImage(self, path):
		if path:
			self.queue.append(lambda: self.locate(path[0].decode('gbk')))

	def onSelectPath(self, path):
		path_ = askdirectory(initialdir=path.get())
		if len(path_) > 0:
			path.set(path_)

	def onClickList(self, event):
		idx = self.listbox.curselection()
		if not idx:
			return

		log = self.listbox.get(idx)
		isSrc = True
		p = log.find(u"[src]")
		if p >= 0:
			path = log[p+5:].strip()
		else:
			p = log.find(u"[art]")
			if p >= 0:
				path = log[p+5:].strip()
				isSrc = False

		artPath = self.artPath.get()
		srcPath = self.srcPath.get()
		path = os.path.join(srcPath if isSrc else artPath, path)
		self.showPreview(path)

	def locate(self, path):
		srcPath = self.srcPath.get()

		tjlog.info(u"src存放目录", srcPath)
		if not os.path.exists(srcPath):
			showerror(u'错误', u"src目录不存在", parent=self)
			return

		self.listbox.delete(0, tk.END) # clear
		self.preview.grid_forget()
		self.lblImageInfo.grid_forget()

		if not self.showPreview(path):
			return
		info = checkFile(path.encode('gbk'))
		tjlog.debug(path, info)

		if os.path.exists(srcPath):
			cache = makeSrcCache(srcPath.encode('gbk'))
			md5s = {v['md5'] : k for k, v in cache.iteritems()}
			key = md5s.get(info['md5'])
			if key:
				tjlog.warning(u"src存在:", key)
				self.listbox.insert(tk.END, u"存在: [src] " + key)
				self.listbox.itemconfig(tk.END, bg='yellow')
			else:
				showerror(u'错误', u"没有找到该资源", parent=self)


	def run(self):
		artPath = self.artPath.get()
		srcPath = self.srcPath.get()

		tjlog.info(u"art美术切图目录", artPath)
		if not os.path.exists(artPath):
			showerror(u'错误', u"目录不存在 " + artPath, parent=self)
			return
		tjlog.info(u"src存放目录", srcPath)
		if not os.path.exists(srcPath):
			showerror(u'错误', u"目录不存在 " + srcPath, parent=self)
			return

		self.listbox.delete(0, tk.END) # clear
		self.preview.grid_forget()
		self.lblImageInfo.grid_forget()

		cache = makeSrcCache(srcPath.encode('gbk'))
		tjlog.info("-"*30)
		ret = diffWithArt(artPath.encode('gbk'), cache)
		new, old = 0, 0
		for t in ret:
			self.listbox.insert(tk.END, t[0] + " " + t[1])
			if t[0] == u"存在:":
				self.listbox.itemconfig(tk.END, bg='yellow')
				old += 1
			else:
				self.listbox.itemconfig(tk.END, bg='green')
				new += 1
		tjlog.debug(u"log文件:", logFile)
		self.status.set(u"存在: %d, 新增: %d" % (old, new))


def win_main():
	root = tk.Tk()
	app = Application(root)
	root.mainloop()

if __name__ == '__main__':
	now = datetime.datetime.now()
	logFile = LOG_FILE % now.strftime("%y%m%d_%H%M%S")
	tjlog.init(True, logFile)

	# main()
	win_main()
