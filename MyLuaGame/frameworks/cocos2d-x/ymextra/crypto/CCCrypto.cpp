
#include "crypto/CCCrypto.h"

extern "C" {
#include "crypto/base64/libbase64.h"
#include "crypto/md5/md5.h"
#include "crypto/xxtea/xxtea.h"
#include "crypto/AES/rijndael-api-fst.h"
}


unsigned char* CCCrypto::encryptXXTEA(unsigned char* plaintext,
                                      int plaintextLength,
                                      unsigned char* key,
                                      int keyLength,
                                      int* resultLength)
{
    xxtea_long len;
    unsigned char* result = xxtea_encrypt(plaintext, (xxtea_long)plaintextLength, key, (xxtea_long)keyLength, &len);
    *resultLength = (int)len;
    return result;
}

unsigned char* CCCrypto::decryptXXTEA(unsigned char* ciphertext,
                                      int ciphertextLength,
                                      unsigned char* key,
                                      int keyLength,
                                      int* resultLength)
{
    xxtea_long len;
    unsigned char* result = xxtea_decrypt(ciphertext, (xxtea_long)ciphertextLength, key, (xxtea_long)keyLength, &len);
    *resultLength = (int)len;
    return result;
}

int CCCrypto::encodeBase64Len(const char* input, int inputLength)
{
    return Base64encode_len(inputLength);
}

int CCCrypto::encodeBase64(const char* input,
                           int inputLength,
                           char* output,
                           int outputBufferLength)
{
    CCAssert(Base64encode_len(inputLength) <= outputBufferLength, "CCCrypto::encodeBase64() - outputBufferLength too small");
    return Base64encode(output, input, inputLength);
}

int CCCrypto::decodeBase64Len(const char* input)
{
    return Base64decode_len(input);
}

int CCCrypto::decodeBase64(const char* input,
                           char* output,
                           int outputBufferLength)
{
    CCAssert(Base64decode_len(input) <= outputBufferLength, "CCCrypto::decodeBase64() - outputBufferLength too small");
    return Base64decode(output, input);
}

void CCCrypto::MD5(void* input, int inputLength, unsigned char* output)
{
    MD5_CTX ctx;
    MD5_Init(&ctx);
    MD5_Update(&ctx, input, inputLength);
    MD5_Final(output, &ctx);
}

const string CCCrypto::MD5String(void* input, int inputLength)
{
    unsigned char buffer[MD5_BUFFER_LENGTH];
    MD5(static_cast<void*>(input), inputLength, buffer);

    char* hex = bin2hex(buffer, MD5_BUFFER_LENGTH);
    string ret(hex);
    delete[] hex;
    return ret;
}

char* CCCrypto::bin2hex(unsigned char* bin, int binLength)
{
    static const char* hextable = "0123456789abcdef";
    
    int hexLength = binLength * 2 + 1;
    char* hex = new char[hexLength];
    
    int ci = 0;
    for (int i = 0; i < binLength; ++i)
    {
        unsigned char c = bin[i];
        hex[ci++] = hextable[(c >> 4) & 0x0f];
        hex[ci++] = hextable[c & 0x0f];
    }
	hex[ci] = 0;
    
    return hex;
}

#if TJ_DEPRECATED

// unsigned char buf[1000];
// unsigned char buf2[1000];
// std::string key = ymextra::CCCrypto::keyHexAES("1234567890123456");
// int ret = ymextra::CCCrypto::encryptAES((unsigned char*)"1234567890abcdef", 16, (char*)key.c_str(), buf);
// ret = ymextra::CCCrypto::decryptAES(buf, 16, (char*)key.c_str(), buf2);


// "YouMi_Technology" -hex-> "596f754d695f546563686e6f6c6f6779"
char* ivHex = "596f754d695f546563686e6f6c6f6779";

std::string CCCrypto::keyHexAES(char key[16])
{
	char* keyHex = bin2hex((unsigned char*)key, AES_KEY_BUFFER_LENGTH);
	std::string ret(keyHex);
	delete [] keyHex;
	return ret;
}

int CCCrypto::encryptAES(unsigned char* plaintext, int plaintextLength, char key[32], unsigned char* result)
{
	if (plaintextLength % 16 != 0)
	{
		CCASSERT(false, "AES need plaintextLength is multiple of 16!");
		return 0;
	}

	keyInstance ekey;
	cipherInstance ecip;

	makeKey(&ekey, DIR_ENCRYPT, 128, key);
	cipherInit(&ecip, MODE_CBC, ivHex);

	int ret = blockEncrypt(&ecip, &ekey, (BYTE*)plaintext, plaintextLength*8, result);
	result[ret/8] = 0;

	return ret/8;
}

int CCCrypto::decryptAES(unsigned char* ciphertext, int ciphertextLength, char key[32], unsigned char* result)
{
	if (ciphertextLength % 16 != 0)
	{
		CCASSERT(false, "AES need ciphertextLength is multiple of 16!");
		return 0;
	}

	keyInstance dkey;
	cipherInstance dcip;

	makeKey(&dkey, DIR_DECRYPT, 128, key);
	cipherInit(&dcip, MODE_CBC, ivHex);

	int ret = blockDecrypt(&dcip, &dkey, (BYTE*)ciphertext, ciphertextLength*8, result);
	result[ret/8] = 0;

	return ret;
}

#endif