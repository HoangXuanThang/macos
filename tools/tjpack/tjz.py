#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import struct
import binascii

import md5
import lz4 # pip install lz4==0.8.2
# import zstd # 1.4.3.2
import subprocess

import tjutil

kCompanyName = "uzHdYxKiVqWABMptN0nX7fc4"
kCompanyShortName = "YpQA9T3n6wLjgrZXubvF"

#####################################
# static char _toConfuse(char ch)
# {
# 	if (ch >= 'a' && ch <= 'z') return ch - 'a' + 'A';
# 	else if (ch == '_') return '+';
# 	else if (ch == '.' || ch == '6') return ';';
# 	return ch;
# }

# static std::string _toLuaPwd(std::string version)
# {
# 	// for code confusion
# 	// 1. a = _toConfuse("hello"+kCompanyShortName+",world"+kCompanyName)
# 	// 2. b = MD5(a) + string("20140516"+version+kCompanyShortName)
# 	// 3. c = _toConfuse(b)
# 	// 4. d = reverse(c)
# 	// 5. e = MD5(d)
# 	int pos = version.find_last_of('.'); //把最后一位舍掉了
# 	std::string confusion = "hello" + std::string(kCompanyShortName) + ",world" + kCompanyName;
# 	std::transform(confusion.begin(), confusion.end(), confusion.begin(), _toConfuse);
# 	std::string updatePass = ymextra::CCCrypto::MD5String((void*)confusion.c_str(), confusion.length());
# 	updatePass += "20140516" + version.substr(0, pos) + kCompanyShortName;
# 	std::transform(updatePass.begin(), updatePass.end(), updatePass.begin(), _toConfuse);
# 	std::reverse(updatePass.begin(), updatePass.end());
# 	return ymextra::CCCrypto::MD5String((void*)updatePass.c_str(), updatePass.length());
# }

def reverse(str):
	return str[::-1]
def toConfuse(str):
	ret = str.upper()
	ret = ret.replace('_','+')
	ret = ret.replace('.',';')
	ret = ret.replace('6',';')
	#return reverse(ret)
	return ret
def getMd5(str) :
	hash = md5.new()
	hash.update(str)
	return hash.hexdigest()
def toLuaPwd(version):
    pos = version[::-1].find('.')+1
    a = toConfuse("minzxcf"+kCompanyShortName+",jingaxr"+kCompanyName+"FXR5mWPoAqCbvUdYT68clEpMuO9jJKNnV0szGy3xfQZrhBLwk41tgaHei72MXn"+"12031999"+"FUCKYOU")
    b = getMd5(a) + str("fX9wB7nqLmYk82UtrDdVa0jQc5RgZ6XoH41MNsKTAb3EiCuvPWlyJGmhNzxOE9F"+version[:-pos]+kCompanyShortName+"dUzXLjVWhbmMCfq39x8kiN5PAKlrG0weY2stJvBMoXTHR4ZgdQa7LEyncuIp6F"+"08091999" + "EXTRA_SECRET_2025")
    c = toConfuse(b)
    d = reverse(c)
    e = getMd5(d)
    f = "minzxcf" + e + ",minzxcf"
    g = getMd5(f)
    h = "jingaxr" + g + ",jingaxr"
    i = getMd5(h)
    j = "minzxcf" + i + ",minzxcf"
    k = getMd5(j)
    l = "jingaxr" + k + ",jingaxr"
    m = getMd5(l)
    return m


kAppVersion = str(os.environ.get('kAppVersion', '2.1.0.0'))
XXTEA_SIGN = kCompanyShortName
XXTEA_KEY = toLuaPwd(kAppVersion)

print 'tjz.kAppVersion', kAppVersion
print 'tjz.XXTEA_SIGN', XXTEA_SIGN
print 'tjz.XXTEA_KEY', XXTEA_KEY
print 'lz4.VERSION', lz4.VERSION

lz4compress = None
lz4uncompress = None
if lz4.VERSION == '0.8.2':
	# def compress(s):
	# 	lenpack = struct.pack('>L', len(s))[:4]
	# 	return lenpack + lz4.compress(s)
	lz4compress = lz4.compress
	lz4uncompress = lz4.uncompress

else:
	import lz4.block # pip install lz4==1.1.0
	lz4compress = lz4.block.compress
	lz4uncompress = lz4.block.decompress


def dataCompress(data, mode='lz4'):
	if mode == 'lz4':
		return lz4compress(data)
	# elif mode == 'zstd':
		# return zstd.compress(data)
	raise Exception('no such compress mode')

def isCompressed(data):
	# tj! = tjz + tje, use lz4
	# 整包少10+MB，暂时不替换，仍然用lz4
	# tj# = tjs + tje, use zstd
	return data[:3] in ('tjz', 'tje', 'tj!', 'tjs', 'tj#')

# tjz[4 bytes size][lz4 data...]
def compress(data, useLZ4=True):
	lenpack = struct.pack('<L', len(data))[:4]
	if useLZ4:
		return 'tjz' + lenpack + dataCompress(data, 'lz4')
	# else:
		# return 'tjs' + lenpack + dataCompress(data, 'zstd')

def compressToFile(data, path, useLZ4=True):
	with open(path, 'wb') as fp:
		fp.write(compress(data, useLZ4=useLZ4))

# tje[16 bytes pass][4 bytes size][data...]
def encodeToFile(data, pwd, path, pwdIsHex=True):
	rnd = os.urandom(16)
	# rnd = '\0' * 16
	if pwdIsHex:
		pwd = binascii.unhexlify(pwd)
	bb = [ord(x) for x in pwd]
	aa = [ord(x) for x in rnd]
	cc = [0] * 16
	for i in xrange(max(len(aa), len(bb))):
		cc[i%16] = cc[i%16] ^ aa[i%len(aa)] ^ bb[i%len(bb)]
	newpwd = ''.join([chr(c) for c in cc])
	lenpack = struct.pack('<L', len(data))[:4]
	# print len(newpwd), repr(newpwd)

	with open(path, 'wb') as fp:
		fp.write(data)

	# xxtea
	XXTEA_SIGN = 'tje' + rnd + lenpack
	cmd = [tjutil.xxtea_exe, '-eh', binascii.hexlify(newpwd), '-sh', binascii.hexlify(XXTEA_SIGN), path, path]
	cmd = ' '.join(cmd)
	ret = subprocess.call(cmd, shell=True)

	if ret != 0:
		raise Exception('xxtea error')


# tj![16 bytes pass][4 bytes size][lz4 data...]
def encodeAndCompressToFile(data, pwd, path, pwdIsHex=True, useLZ4=True):
	rnd = os.urandom(16)
	# rnd = '\0' * 16
	if pwdIsHex:
		pwd = binascii.unhexlify(pwd)
	bb = [ord(x) for x in pwd]
	aa = [ord(x) for x in rnd]
	cc = [0] * 16
	for i in xrange(max(len(aa), len(bb))):
		cc[i%16] = cc[i%16] ^ aa[i%len(aa)] ^ bb[i%len(bb)]
	newpwd = ''.join([chr(c) for c in cc])

	# compress
	lenpack = struct.pack('<L', len(data))[:4]
	zdata = dataCompress(data, 'lz4' if useLZ4 else 'zstd')
	with open(path, 'wb') as fp:
		fp.write(zdata)

	# xxtea
	flag = 'tj!' if useLZ4 else 'tj#'
	XXTEA_SIGN = flag + rnd + lenpack
	cmd = [tjutil.xxtea_exe, '-eh', binascii.hexlify(newpwd), '-sh', binascii.hexlify(XXTEA_SIGN), path, path]
	cmd = ' '.join(cmd)
	ret = subprocess.call(cmd, shell=True)

	if ret != 0:
		raise Exception('xxtea error')


def decode(data, pwd, pwdIsHex=True):
	if not isCompressed(data):
		return data
	rawdata = data
	isLZ4 = data[2] == '!' or data[2] == 'z'
	isXXTEA = data[2] == '!' or data[2] == 'e'
	if pwdIsHex:
		pwd = binascii.unhexlify(pwd)

	sign = data[:3]
	data = data[3:] # flag
	if isXXTEA:
		rnd = data[:16] # rnd
		sign += rnd
		data = data[16:]
		bb = [ord(x) for x in pwd]
		aa = [ord(x) for x in rnd]
		cc = [0] * 16
		for i in xrange(max(len(aa), len(bb))):
			cc[i%16] = cc[i%16] ^ aa[i%len(aa)] ^ bb[i%len(bb)]
		pwd = ''.join([chr(c) for c in cc])

	length = struct.unpack('<L', data[:4]) # lenpack
	sign += data[:4]
	data = data[4:]
	# print '!!!sign', repr(sign)
	# print '!!!rnd', repr(rnd), len(rnd)
	# print '!!!length', length
	# print '!!!data', len(data)

	if isXXTEA:
		path = 'decode.tmp'
		with open(path, 'wb') as fp:
			fp.write(rawdata)

		cmd = [tjutil.xxtea_exe, '-dh', binascii.hexlify(pwd), '-sh', binascii.hexlify(sign), path, path]
		cmd = ' '.join(cmd)
		ret = subprocess.call(cmd, shell=True)
		if ret != 0:
			raise Exception('xxtea error')

		with open(path, 'rb') as fp:
			data = fp.read()

	if isLZ4:
		data = lz4uncompress(data)

	return data
