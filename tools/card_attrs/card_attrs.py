#!/usr/bin/python
# -*- coding: utf-8 -*-

import datetime
import binascii
import md5
import msgpackrpc
import random
import platform
import functools
import Tkinter as tk
import tkFont
import json
from tkMessageBox import showerror

from rpc import GMRPClient

def utf2local(s):
	if platform.system() == 'Windows':
		return s.decode('utf8').encode('gbk')
	return s

def objectid2string(id):
	return binascii.hexlify(id)

def string2objectid(s):
	return binascii.unhexlify(s)

with open('config.json', 'r') as fp:
	config = fp.read()
d = json.loads(config)

client = GMRPClient(msgpackrpc.Address(d['gm']['host'], d['gm']['port']))
client.init()

def get_cards(servkey, roleID):
	ret = client.call('gmGetRoleCards', servkey, roleID, None)
	return ret

def eval_card_attrs(servkey, roleID, cardID, disables):
	attrs = client.call('gmEvalCardAttrs', servkey, roleID, cardID, disables)
	return attrs


servkeys = d['servers']

keys = [x[0] for x in d['keys']]
keysDisplays = {x[0]: x[1] for x in d['keys']}

attrs = [x[0] for x in d['attrs']]
attrsDisplays = {x[0]: x[1] for x in d['attrs']}

attrsExtend = [x[0] for x in d['attrs_extend']]
attrsExtendDisplays = {x[0]: x[1] for x in d['attrs_extend']}

names = ['name', 'card_id', 'level', 'star', 'advance', 'character']
namesDisplay = {
	'name': '名字',
	'card_id': 'CSV ID',
	'level': '等级',
	'star': '星数',
	'advance': '阶数',
	'character': '性格',
}

def tabify(s, tabsize = 4):
	ln = ((len(s)/tabsize)+1)*tabsize
	return s.ljust(ln)

class Application(tk.Frame):

	def __init__(self, root):
		tk.Frame.__init__(self, root)
		self.root = root

		# self.root.geometry("800x800+500+200")
		self.root.rowconfigure(0, weight=1)
		self.root.columnconfigure(0, weight=1)
		self.root.resizable(False, False)
		self.root.title("卡牌属性计算工具")

		self.initWidgets()
		self.grid(row=0, column=0, sticky=tk.NSEW)

		self.roleID = None
		self.cardID = None

		self.check_client()

	def initWidgets(self):
		self.font = tkFont.Font(family='微软雅黑', size=10, weight='bold')

		uidvar = tk.StringVar()
		namevar = tk.StringVar()
		self.disables = [tk.StringVar() for _ in keys]
		self.attrsval = {attr: tk.StringVar() for attr in attrs}
		map(lambda x:x.set('0.00'), self.attrsval.values())
		self.cards = []
		self.servKey = tk.StringVar()
		self.servKey.set('game.dev.2')
		self.card = {name: tk.StringVar() for name in names}

		top = tk.Frame(self)
		top.grid(row=0, column=0, sticky=tk.NSEW, columnspan=3)
		tk.Label(top, text="区 服").grid(row=0, column=0)
		tk.OptionMenu(top, self.servKey, *servkeys).grid(row=0, column=1)
		tk.Label(top, text="角色UID").grid(row=0, column=2, sticky=tk.NSEW)
		tk.Entry(top, textvariable=uidvar, width=15).grid(row=0, column=3)
		tk.Button(top, text="查询角色", command=functools.partial(self.onRoleSearch, uidvar, namevar), width=10).grid(row=0, column=4)
		tk.Label(top, textvariable=namevar, width=15).grid(row=0, column=5)

		# tk.Button(self, text="计 算", command=self.onEval, width=5, font=self.font).grid(row=0, column=3)

		leftPanel = tk.LabelFrame(self, text="卡牌列表")
		leftPanel.rowconfigure(0, weight=1)
		leftPanel.columnconfigure(0, weight=1)
		leftPanel.grid(row=1, column=0, sticky=tk.NSEW)
		self.listbox = tk.Listbox(leftPanel)
		self.listbox.grid(row=0, column=0, sticky=tk.NSEW)
		self.listbox.bind("<ButtonRelease-1>", self.onClickList)
		scrollbar = tk.Scrollbar(leftPanel)
		scrollbar.grid(row=0, column=1, sticky="ns")
		scrollbar.config(command=self.listbox.yview)
		self.listbox.yscrollcommand = scrollbar.set

		midPanel = tk.Frame(self)
		midPanel.grid(row=1, column=1, sticky=tk.NSEW)
		cardFrame = tk.LabelFrame(midPanel, text="卡牌信息")
		cardFrame.grid(row=0, column=0)
		for i, name in enumerate(names):
			tk.Label(cardFrame, text=namesDisplay[name], width=10, anchor=tk.W).grid(row=i, column=0)
			tk.Label(cardFrame, textvariable=self.card[name], width=10, anchor=tk.W).grid(row=i, column=1)
		keysFrame = tk.LabelFrame(midPanel, text="选中取消")
		keysFrame.grid(row=1, column=0)
		for i, key in enumerate(keys):
			tk.Checkbutton(keysFrame, text=keysDisplays[key], variable=self.disables[i], onvalue=key, offvalue='', command=self.onEval, anchor=tk.W).grid(row=i, column=0, sticky=tk.NSEW)

		rightPanel = tk.LabelFrame(self, text='卡牌属性')
		rightPanel.grid(row=1, column=2, sticky=tk.NSEW)
		for i, attr in enumerate(attrs):
			tk.Label(rightPanel, text=attrsDisplays[attr], width=12, anchor=tk.E).grid(row=i, column=0)
			tk.Label(rightPanel, textvariable=self.attrsval[attr], width=12, anchor=tk.W).grid(row=i, column=1)

		rightPanel2 = tk.LabelFrame(self, text='额外属性')
		rightPanel2.grid(row=1, column=3, sticky=tk.NSEW)
		rightPanel2.rowconfigure(0, weight=1)
		rightPanel2.columnconfigure(0, weight=1)
		self.attrsExtendList = tk.Listbox(rightPanel2, width=30)
		self.attrsExtendList.grid(row=0, column=0, sticky=tk.NSEW)

	def onRoleSearch(self, uidvar, namevar):
		uid = uidvar.get()
		if not uid:
			return
		servkey = self.servKey.get()
		uid = int(uid)
		model = get_cards(servkey, uid)
		if not model:
			showerror('Error', 'maybe role not login', parent=self)
			return
		role, cards = model['role'], model['cards']
		self.roleID = role['id']
		namevar.set(role['name'])

		self.listbox.delete(0, tk.END) # clear
		self.cards = sorted(cards.values(), key=lambda x:x['fighting_point'], reverse=True)
		for card in self.cards:
			self.listbox.insert(tk.END, '%s     %d' % (card['name'], card['fighting_point']))

	def onClickList(self, event):
		idx = self.listbox.curselection()
		if not idx:
			return
		card = self.cards[idx[0]]
		if self.cardID == card['id']:
			return
		# cardID = self.listbox.get(idx)
		# print 'onClickList', objectid2string(card['id'])
		self.cardID = card['id']
		for name, var in self.card.iteritems():
			var.set(str(card[name]))
		self.onEval()

	def onEval(self):
		servkey = self.servKey.get()
		disables = [var.get() for var in self.disables]
		disables = filter(None, disables)
		# print disables
		card_attrs = eval_card_attrs(servkey, self.roleID, self.cardID, disables)
		if card_attrs:
			extend = {}
			for k, v in card_attrs.iteritems():
				if k in attrs:
					self.attrsval[k].set('%.02f' % v)
				else:
					if v > 0:
						extend[k] = v
			self.attrsExtendList.delete(0, tk.END) # clear
			for key in attrsExtend:
				if key in extend:
					s = tabify(attrsExtendDisplays.get(key, key)) + '%.02f' % extend[key]
					self.attrsExtendList.insert(tk.END, s)
		else:
			showerror('Error', 'maybe role not login', parent=self)

	def check_client(self):
		try:
			print client.call('_hello', 1)
		except Exception as e:
			showerror('Error', str(e), parent=self)

def win_main():
	root = tk.Tk()
	app = Application(root)
	root.mainloop()

if __name__ == '__main__':
	win_main()
