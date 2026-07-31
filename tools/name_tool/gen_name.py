#!/usr/bin/python
# -*- coding: utf-8 -*-

import re
import httplib
import urllib2
import threading

NAMES = [
	'八神 太一',
	'八神 嘉儿',
	'高石 武',
	'石田 大和',
	'武之内 素娜',
	'泉 光子郎',
	'太刀 川美美',
	'城户 助',

	'芝谷 彩可',
	'美空 云雀',
	'月影 千草',
	'水野 遥',
	'松本 润',
	'中山 美穗',
	'宫崎 葵',
	'野原 美芽',
	'小池 徹平',
	'井上 织姬',
	'松永 久秀',
	'朝海 光',
	'高野 秀树',
	'山田 阳一',
	'森田 大空',
	'田中 真梨子',
	'木美 奈子',
	'森美 树子',
	'长谷 川茜',
	'秋道 丁次',
	'千叶 长空',
	'林 理惠',
	'星舞 花溪',
	'优 梦翼',
	'飞鸟 裕子',
	'星宇 慧枫',
	'相原 里奈',
	'千叶 丽子',
	'江川 有未',
	'知念 里奈',
	'江藤 留美',
	'江崎 优子',
	'深野 晴美',
	'吹石 一恵',
	' 秋元',
	'秋津 真白',
	'秋山 美砂',
	'安西 梨香',
	'青叶 工美',
	'青木 琴美',
	'浅田 真子',
	'福冈 晶',
	'古谷 芳香',
	' 冬花',
	'原久 美子',
	'叶山 奈美',
	'早川 桃子',
	'叶山 美纪',
	'叶月 未来',
	'本田 理沙',
	'本城 美佳',
	'星野 香织',
	'细川 直美',
	'五十岚 ',
	'加山 花衣',
	'今井 友香',
	'今村 朱美',
	'稻田 奈绪',
	'井上 翠',
	'井上 梨花',
	'入来 阳子',
	'石井 里穂',
	'泉 尚子',
	'纯名 里沙',
	'华原 朋美',
	'嘉门 洋子',
	'川村 千里',
	'木田 彩水',
	'小林 绢香',
	'小岛 里美',
	'小松 千春',
	'今野 妙子',
	'幸田 奈美',
	'小山 真依',
	'前园 友香',
	'美保 纯',
	'三上 美铃',
	'南理 香',
	'三崎 千香',
	'三田 友穂',
	'宫内 知美',
	'水原 爱',
	'水野 美纪',
	'水岛 杏里',
	'望月 留美',
	'森川 瑞树',
	'森高 千里',
	'长山 洋子',
	'中岛 礼香',
	'七森 美江',
	'七海 沙恵',
	'七园 未梨',
	'新山 千春',
	'菊川 芳江',
	'佐藤 了一',
	'青山 恭子',
	'水木 京一',

]

URLS = [
	('https://zh.wikipedia.org/wiki/%E6%97%A5%E6%9C%AC%E5%A7%93%E6%B0%8F%E5%88%97%E8%A1%A8/1001-2000', ur'(<td>(?P<xing>[\u4e00-\u9fa5]+)<br />)|(>(?P<xing2>[\u4e00-\u9fa5]+)氏</a></td>)'),
	('https://zh.wikipedia.org/wiki/%E6%97%A5%E6%9C%AC%E5%A7%93%E6%B0%8F%E5%88%97%E8%A1%A8/1-1000', ur'(<td>(?P<xing>[\u4e00-\u9fa5]+)<br />)|(>(?P<xing2>[\u4e00-\u9fa5]+)氏</a></td>)'),
	('https://zh.wikipedia.org/wiki/%E6%97%A5%E6%9C%AC%E4%BA%BA%E5%90%8D', ur'(<td>(?P<xing>[\u4e00-\u9fa5]+)<br />)|(>(?P<xing2>[\u4e00-\u9fa5]+)氏</a></td>)'),
	('https://zh.wikipedia.org/wiki/%E6%97%A5%E6%9C%AC%E5%A7%93%E6%B0%8F%E5%88%97%E8%A1%A8', ur'(<td>(?P<xing>[\u4e00-\u9fa5]+)<br />)|(>(?P<xing2>[\u4e00-\u9fa5]+)氏</a></td>)'),

	('http://www.kekejp.com/info/201111/30459.shtml', ur'<p>\s*\d+.(?P<xing>[^（]+).+</p>'),
	('http://www.kekejp.com/info/201111/30459_2.shtml', ur'<p>\s*\d+.(?P<xing>[^（]+).+</p>'),
	('http://www.kekejp.com/info/201111/30459_3.shtml', ur'<p>\s*\d+.(?P<xing>[^（]+).+</p>'),
]

TRYURLS = [
	('http://www.xuanpai.com/tool/riben?sex=1', 20, ur'<li ><font color=red>(?P<xing>[^<]+)</font><font color=blue>(?P<ming>[^<]+)</font></li>'),
	('http://www.xuanpai.com/tool/riben?sex=2', 10, ur'<li ><font color=red>(?P<xing>[^<]+)</font><font color=blue>(?P<ming>[^<]+)</font></li>'),
]

namePrefixs = set()
names = set()

lock = threading.Lock()

def download(url, reg):
	# print 'begin', url
	headers = {'accept-language': 'zh-CN,zh;q=0.8,en;q=0.6,de;q=0.4'}
	req = urllib2.Request(url, headers=headers)
	fp = urllib2.urlopen(req)
	data = fp.read()
	try:
		udata = data.decode('utf8')
	except:
		udata = data.decode('gbk')
	# print 'download ok', url

	regobj = re.compile(reg, re.MULTILINE)
	xings = set()
	mings = set()
	for match in regobj.finditer(udata):
		d = match.groupdict()
		if d.get(u'xing', None) and len(d[u'xing']) <= 3:
			# print match.group(), d[u'xing']
			xings.add(d[u'xing'])
		if d.get(u'xing2', None) and len(d[u'xing2']) <= 3:
			xings.add(d[u'xing2'])
		if d.get(u'ming', None) and len(d[u'ming']) <= 3:
			mings.add(d[u'ming'])

	lock.acquire()
	global namePrefixs
	global names
	namePrefixs |= xings
	names |= mings
	lock.release()
	print 'parse ok', url

def readCache():
	global namePrefixs
	global names

	with open('names.txt', 'rb') as fp:
		lines = fp.readlines()
		for x in lines:
			names.add(x.strip().decode('utf8'))
	with open('namePrefixs.txt', 'rb') as fp:
		lines = fp.readlines()
		for x in lines:
			namePrefixs.add(x.strip().decode('utf8'))

	print 'readCache', len(namePrefixs), len(names)

def parseNames():
	global NAMES
	global namePrefixs
	global names

	for x in NAMES:
		xx = x.split()
		if len(xx) == 2:
			namePrefixs.add(xx[0].strip().decode('utf8'))
			names.add(xx[1].strip().decode('utf8'))
		elif x[0] == ' ':
			names.add(x.strip().decode('utf8'))
		elif x[-1] == ' ':
			namePrefixs.add(x.strip().decode('utf8'))

	print 'parseNames', len(namePrefixs), len(names)

def main():
	readCache()
	parseNames()

	threads = []
	# for url, reg in URLS:
	# 	th = threading.Thread(target = download, args = (url, reg))
	# 	threads.append(th)

	for url, times, reg in TRYURLS:
		for i in xrange(times):
			th = threading.Thread(target = download, args = (url, reg))
			threads.append(th)

	map(lambda th: th.start(), threads)
	map(lambda th: th.join(), threads)

	print len(namePrefixs), len(names)
	with open('names.txt', 'wb') as fp:
		fp.write('\n'.join(sorted([x.encode('utf8') for x in names])))
	with open('namePrefixs.txt', 'wb') as fp:
		fp.write('\n'.join(sorted([x.encode('utf8') for x in namePrefixs])))

if __name__ == '__main__':
	main()