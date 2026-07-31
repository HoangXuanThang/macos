import os
import json

def listFiles(rootDir):
	list_dirs = os.walk(rootDir)
	list_ret = {}
	for root, dirs, files in list_dirs:
		for f in files:
			pf = os.path.join(root, f)
			s = os.stat(pf)
			pf = pf.replace('\\', '/')
			# if pf[-8:] == '.pvr.ccz':
			# 	pf = pf[:-8] + '.png'
			list_ret[pf] = int(s.st_size)
	return list_ret

def main():
	with open('repo_mapping.log') as fp:
		d = json.load(fp)

	print(len(d))
	oldsize, newsize = 0, 0
	filesize = 0
	for k, info in d.iteritems():
		oldsize += info['size']
		newsize += info['reposize']

	files = listFiles('res')
	# print files
	for k, size in files.iteritems():
		filesize += size

	print oldsize, newsize, filesize

	for k, info in d.iteritems():
		if k in files:
			if info['reposize'] > files[k]:
				delta = info['reposize']-files[k]
				print k, files[k], '|', info['size'], info['reposize'], '(%s%d)' % ('+' if delta > 0 else '', delta)
			del files[k]
		else:
			print '!!!', k, 'not in res'

	for k, size in files.iteritems():
		print '!!!', k, size, 'only in res'

if __name__ == '__main__':
	main()