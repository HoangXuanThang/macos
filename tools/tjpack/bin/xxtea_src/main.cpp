#include <stdio.h>
#include <string.h>
#include <string>

extern "C" {
#include "xxtea.h"
};

using namespace std;


std::string hex2bin(const char* hex, int hexLength)
{
	int binLength = hexLength / 2;
	if (binLength * 2 != hexLength)
		return "";

	char* bin = (char*)malloc(binLength + 1);

	int i = 0;
	for (i = 0; i < binLength; ++i)
	{
		unsigned char c1 = hex[2 * i];
		unsigned char c2 = hex[2 * i + 1];
		if ('a' <= c1 && c1 <= 'z')
			c1 = c1 - 'a' + 10;
		else if ('A' <= c1 && c1 <= 'Z')
			c1 = c1 - 'A' + 10;
		else if ('0' <= c1 && c1 <= '9')
			c1 -= '0';
		if ('a' <= c2 && c2 <= 'z')
			c2 = c2 - 'a' + 10;
		else if ('A' <= c2 && c2 <= 'Z')
			c2 = c2 - 'A' + 10;
		else if ('0' <= c2 && c2 <= '9')
			c2 -= '0';
		c1 &= 0x0f;
		c2 &= 0x0f;
		bin[i] = (c1 << 4) | c2;
	}
	bin[binLength] = 0;

	std::string ret;
	ret.assign(bin, binLength);
	free(bin);
	return ret;
}

int main(int narg, char** varg)
{
	bool encrypt = true;
	std::string srcPath, dstPath;
	std::string key, sign;

	for (int i = 1; i < narg; ++i)
	{
		// 加密密钥
		if (strcmp(varg[i], "-e") == 0)
		{
			encrypt = true;
			key = varg[++i];
		}
		// 加密密钥(十六进制字符串，转为二进制)
		else if (strcmp(varg[i], "-eh") == 0)
		{
			encrypt = true;
			key = varg[++i];
			key = hex2bin(key.c_str(), key.length());
			if (key.empty())
			{
				puts("hex key must be odd!");
				return 1;
			}
		}
		// 解密密钥
		else if (strcmp(varg[i], "-d") == 0)
		{
			encrypt = false;
			key = varg[++i];
		}
		// 解密密钥(十六进制字符串，转为二进制)
		else if (strcmp(varg[i], "-dh") == 0)
		{
			encrypt = false;
			key = varg[++i];
			key = hex2bin(key.c_str(), key.length());
			if (key.empty())
			{
				puts("hex key must be odd!");
				return 1;
			}
		}
		// 头部签名
		else if (strcmp(varg[i], "-s") == 0)
		{
			sign = varg[++i];
		}
		// 头部签名(十六进制字符串，转为二进制)
		else if (strcmp(varg[i], "-sh") == 0)
		{
			sign = varg[++i];
			sign = hex2bin(sign.c_str(), sign.length());
			if (sign.empty())
			{
				puts("hex sign must be odd!");
				return 1;
			}
		}
		else if (varg[i][0] != '-')
		{
			if (srcPath.empty())
				srcPath = varg[i];
			else
				dstPath = varg[i];
		}
	}

	if (key.empty())
	{
		puts("key must be not empty!");
		return 1;
	}

	if (dstPath.empty())
		dstPath = srcPath;

	FILE* fp = fopen(srcPath.c_str(), "rb");
	if (fp == NULL)
	{
		puts("file can't be open!");
		return 1;
	}
	fseek(fp, 0, SEEK_END);
	int size = ftell(fp);
	unsigned char* data = new unsigned char[size];
	fseek(fp, 0, SEEK_SET);
	fread(data, 1, size, fp);
	fclose(fp);
	
	unsigned int ret_len = 0;
	unsigned char* outData = NULL;
	if (encrypt)
	{
		outData = xxtea_encrypt(data, size, (unsigned char*)key.c_str(), key.size(), &ret_len);
	}
	else
	{
		outData = xxtea_decrypt(data + sign.size(), size - sign.size(), (unsigned char*)key.c_str(), key.size(), &ret_len);
	}

	if (outData == NULL)
	{
		puts("xxtea_encrypt error!");
		return 1;
	}

	fp = fopen(dstPath.c_str(), "wb");
	if (fp == NULL)
	{
		puts("file can't be write!");
		return 1;
	}

	if (encrypt && !sign.empty())
	{
		fwrite(sign.c_str(), sign.size(), 1, fp);
	}
	fwrite(outData, ret_len, 1, fp);
	fclose(fp);

	xxtea_free(outData);
	delete [] data;
	return 0;
}