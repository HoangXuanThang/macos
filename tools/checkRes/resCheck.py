#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import datetime
import Tkinter as tk
import windnd
import functools
from collections import deque
from PIL import Image
import re
import hashlib
from tkFileDialog import askdirectory
# from checksum import create_checksum
import random
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
MAXWIDTH = 2048
MAXHEGHT = 2048

import tjlog
LOG_FILE = "finder_%s.log"

def checkFile(filePath):
	stat = os.stat(filePath)
	with open(filePath, "rb") as fp:
		data = fp.read()
	m = hashlib.md5()
	m.update(data)
	md5 = m.hexdigest()
	return (stat.st_size, md5)

class Application(tk.Frame):
	def __init__(self, root):
		tk.Frame.__init__(self, root)
		self.root = root
		self.root.title('资源检测工具')
		self.root.geometry("600x600+" + str(random.randrange(0, 300)) + '+' + str(random.randrange(0, 300)))
		self.root.rowconfigure(0, weight = 1)
		self.root.columnconfigure(0, weight= 1)
		self.initWidgets()
		self.grid(row = 0, column = 0, sticky=tk.NSEW)
		self.queue = deque()
		self.listboxData = []
		self.listToCheck = []
		self.checking = False
		self.onUpdate()

	def initWidgets(self):
		self.rowconfigure(0, weight = 2)
		self.rowconfigure(1, weight = 1)
		self.rowconfigure(2, weight = 20)
		self.columnconfigure(0, weight = 1)

		self.artPath = tk.StringVar()
		self.tipInfo = tk.StringVar()
		self.checkState = tk.StringVar()

		top = tk.Frame(self)
		top.grid(row = 0, column = 0, sticky = tk.NSEW)
		top.rowconfigure(0, weight = 1)
		top.columnconfigure(0, weight = 1)
		top.columnconfigure(1, weight = 3)
		top.columnconfigure(2, weight = 1)
		top.columnconfigure(3, weight = 1)
		tk.Label(top, text='资源文件夹:', justify=tk.LEFT).grid(row= 0, column = 0, sticky = tk.NSEW)
		tk.Button(top, text = '选择', command = functools.partial(self.onSelectPath, self.artPath)).grid(row =0, column=2)
		tk.Button(top, text = '开始检测', command = functools.partial(self.beginCheck)).grid(row = 0, column = 3)

		ent = tk.Entry(top, width = 50, textvariable = self.artPath)
		ent.grid(row=0, column = 1)
		windnd.hook_dropfiles(ent, functools.partial(self.onDragDropPath, self.artPath))

		stateFrame = tk.Frame(self)
		stateFrame.grid(row = 1, column = 0, sticky = tk.NSEW)

		stateLabel = tk.Label(stateFrame, textvariable = self.checkState, justify = tk.LEFT)
		stateLabel.grid(row = 0, column = 0, sticky = tk.NSEW)
		self.checkState.set('尚未选择文件夹')

		bot = tk.Frame(self)
		bot.grid(row=2, column = 0, pady = 10, sticky = tk.NSEW)

		bot.rowconfigure(0, weight = 100)
		bot.rowconfigure(1, weight = 2)
		bot.columnconfigure(0, weight = 1)
		frmList = tk.LabelFrame(bot, text = '异常资源列表')
		frmList.grid(row = 0, column = 0, sticky = tk.NSEW)
		frmList.rowconfigure(0, weight = 1)
		frmList.columnconfigure(0, weight = 1)

		self.yScroll = tk.Scrollbar(frmList, orient = tk.VERTICAL)
		self.yScroll.grid(row = 0, column = 1, sticky = "ns")
		self.xScroll = tk.Scrollbar(frmList, orient = tk.HORIZONTAL)
		self.xScroll.grid(row = 1, column = 0, sticky = 'ew')

		self.listbox = tk.Listbox(frmList)
		self.listbox.bind("<ButtonRelease-1>", self.onClickList)
		self.listbox.grid(row= 0, column = 0, sticky = tk.NSEW)
		self.xScroll['command'] = self.listbox.xview
		self.yScroll['command'] = self.listbox.yview

		self.label = tk.Label(bot, textvariable = self.tipInfo)
		self.label.grid(row = 1, column = 0, sticky = tk.NSEW)
		self.tipInfo.set('请将需要检测的文件夹拖入目录框中，或者按选择按钮选择文件夹')

	def onSelectPath(self, path):
		path_ = askdirectory(initialdir=path.get())
		if len(path_) > 0:
			if not os.path.isdir(path_):
				path_ = os.path.dirname(path_)
			self.queue.append(lambda:path.set(path_))
			self.checkState.set('点击开始检测按钮即可开始检测')

	def onClickList(self, event):
		idx = self.listbox.curselection()
		if not idx:
			return
		childNum = int(idx[0]) + 1
		curI = 0
		countLen = 0
		for i in range(0, 3):
			if childNum <= len(self.errorinfo[i]):
				curI = i
				break
			else:
				childNum = childNum - len(self.errorinfo[i])
		self.tipInfo.set(self.errorinfo[curI][childNum - 1])

	def onDragDropPath(self, path, dndPath):
		if dndPath:
			dndPath = dndPath[0]
			if not os.path.isdir(dndPath):
				dndPath = os.path.dirname(dndPath)
			self.queue.append(lambda:path.set(unicode(dndPath)))

	def is_img(self, ext):
		ext = ext.lower()
		if ext in ['.jgp', '.png', '.jpeg', '.bmp']:
			return True
		else:
			return False

	def beginCheck(self):
		if self.artPath.get() != '':
			self.updateList()

	def updateList(self):
		list_dirs = os.walk(self.artPath.get())
		self.listbox.delete(0, tk.END)
		self.errorinfo = [[], [], []]
		self.indexs = [0, 0, 0]
		self.listboxData = []
		self.listToCheck = []
		self.record = {}
		self.listToCheck.append({'root':self.artPath.get(), 'type':'root'})
		for root, dirs, files in list_dirs:
				for folder in dirs:
					if not re.search(r'\.svn', os.path.join(root, folder)):
						self.listToCheck.append({'root':root, 'type':'folder', 'name':folder})
				for f in files:
					if not re.search(r'\.svn', os.path.join(root, f)):
						self.listToCheck.append({'root':root, 'type':'file', 'name':f})
		self.checking = True

	def checkOne(self, data):
		if data and data['type'] == 'root':
			self.checkState.set('正在检测根目录：\n' + data['root'])
			searchRet = re.findall('[^a-z0-9_]', data['root'].split('\\')[-1])
			if len(searchRet):
				self.listboxData.append([data['root'], 0])
				self.errorinfo[0].append('根目录存在异常字符：' + ''.join(searchRet))
				tjlog.debug(u"根目录存在异常字符：", searchRet)
				tjlog.warning(data['root'])

		elif data and data['type'] == 'folder':
			filepath = os.path.join(data['root'], data['name'])
			self.checkState.set('正在检测文件夹：\n' + filepath)
			searchRet = re.findall('[^a-z0-9_]', data['name'])
			if len(searchRet):
				self.listboxData.append([filepath, 0])
				self.errorinfo[0].append('文件夹命名存在异常字符：' + ''.join(searchRet))
				tjlog.debug(u"文件夹命名存在异常字符：", searchRet)
				tjlog.warning(filepath)

		elif data['type'] == 'file':
			filepath = os.path.join(data['root'], data['name'])
			self.checkState.set('正在检测文件：\n' + filepath)
			filenameAndExt = os.path.splitext(data['name'])
			filename = filenameAndExt[0]
			if filename[-1] == '@':
				filename = filename[0:-1]

			searchRet = re.findall('[^a-z0-9_]', filename)
			if len(searchRet):
				self.listboxData.append([filepath, 0])
				self.errorinfo[0].append('文件命名存在异常字符: ' + ''.join(searchRet))
				tjlog.debug(u"文件命名存在异常字符: ", searchRet)
				tjlog.warning(filepath)
			else:
				ext = filenameAndExt[1]
				if self.is_img(ext):
					img = Image.open(filepath)
					if (img.size[0] > MAXWIDTH) or (img.size[1] > MAXHEGHT):
						self.listboxData.append([filepath, 1])
						info = ' 图片大小:' + str(img.size[0]) + 'X' + str(img.size[1]) + '，超出了限定大小:' + str(MAXWIDTH) + 'X' + str(MAXHEGHT)
						self.errorinfo[1].append(info)
						tjlog.debug(u"%s" % info)
						tjlog.error(filepath)

					elif ext == '.PNG':
						self.listboxData.append([filepath, 1])
						self.errorinfo[0].append('大写的后缀PNG!')
						tjlog.debug(u"大写的后缀PNG!")
						tjlog.warning(filepath)

				compound_key = checkFile(filepath)
				if compound_key in self.record:
					self.listboxData.append([filepath, 2])
					self.errorinfo[2].append('当前文件与此路径的文件重复：\n' + self.record[compound_key])
					tjlog.debug(u"当前文件与此路径的文件重复：\n", self.record[compound_key])
					tjlog.warning(filepath)
				else:
					self.record[compound_key] = filepath

	def onUpdate(self):
		if len(self.listToCheck) > 0:
			self.checkOne(self.listToCheck[0])
			del self.listToCheck[0]
		else:
			if self.checking:
				self.checkState.set('检测完毕')
				self.checking = False
		if len(self.listboxData) > 0:
			boxdata = self.listboxData[0]
			errortype = boxdata[1]
			index = 0
			for i in range(0, errortype + 1):
				index = self.indexs[i] + index
			self.indexs[errortype] = self.indexs[errortype] + 1
			self.listbox.insert(index, boxdata[0])
			colors = ['yellow', 'orange', 'red']
			self.listbox.itemconfig(index, bg=colors[errortype])
			del self.listboxData[0]
		while len(self.queue) > 0:
			task = self.queue.popleft()
			task()
		self.after(10, self.onUpdate)

def main():
	root = tk.Tk()
	app = Application(root)
	root.mainloop()

if __name__ == '__main__':
	now = datetime.datetime.now()
	logFile = LOG_FILE % now.strftime("%y%m%d_%H%M%S")
	tjlog.init(True, logFile)
	main()