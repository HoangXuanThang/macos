import os
import json
import tjz
import pprint

def main():
	with open('repo.mapping', 'rb') as fp:
		data = fp.read()

	# tjz.encodeAndCompressToFile(data, tjz.XXTEA_KEY, outputPath, useLZ4=True)
	data = tjz.decode(data, tjz.XXTEA_KEY)
	d = json.loads(data)

	with open('repo.mapping.json', 'wb') as fp:
		json.dump(d, fp, indent=2)
	pprint.pprint(d)


if __name__ == '__main__':
	main()