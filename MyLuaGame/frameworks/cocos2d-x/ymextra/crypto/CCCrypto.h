
#ifndef __CC_EXTENSION_CCCRYPTO_H_
#define __CC_EXTENSION_CCCRYPTO_H_

#include "ymextra/ymextra.h"
#include "ymextra/crypto/lz4/lz4.h"


class CC_DLL CCCrypto
{
public:
	static const int MD5_BUFFER_LENGTH = 16;
	static const int AES_KEY_BUFFER_LENGTH = 16;
    
    
    /** @brief Encrypt data with XXTEA algorithm, return ciphertext, free ciphertext after used */
    static unsigned char* encryptXXTEA(unsigned char* plaintext,
                                       int plaintextLength,
                                       unsigned char* key,
                                       int keyLength,
                                       int* resultLength);
    
    /** @brief Decrypt data with XXTEA algorithm, return plaintext, free plaintext after used */
    static unsigned char* decryptXXTEA(unsigned char* ciphertext,
                                       int ciphertextLength,
                                       unsigned char* key,
                                       int keyLength,
                                       int* resultLength);

    /** @brief Get length of encoding data with Base64 algorithm */
    static int encodeBase64Len(const char* input, int inputLength);
    
    /** @brief Encoding data with Base64 algorithm, return encoded string length */
    static int encodeBase64(const char* input, int inputLength,
                            char* output, int outputBufferLength);
    
    /** @brief Get length of Decoding Base 64 */
    static int decodeBase64Len(const char* input);

    /** @brief Decoding Base64 string to data, return decoded data length */
    static int decodeBase64(const char* input,
                            char* output, int outputBufferLength);
    
    /** @brief Calculate MD5, get MD5 code (not string) */
    static void MD5(void* input, int inputLength,
                    unsigned char* output);

    static const string MD5String(void* input, int inputLength);

#if TJ_DEPRECATED

	/** @brief key hexlify with AES algorithm, key must be 16 bytes */
	static string keyHexAES(char key[16]);

	/** @brief Encrypt data with AES algorithm, plaintextLength must be multiple of 16, key must be 32 bytes */
	static int encryptAES(unsigned char* plaintext,
		int plaintextLength,
		char key[32],
		unsigned char* result);
    
	/** @brief Decrypt data with AES algorithm, ciphertextLength must be multiple of 16, key must be 32 bytes */
	static int decryptAES(unsigned char* ciphertext,
		int ciphertextLength,
		char key[32],
		unsigned char* result);

#endif


private:
    CCCrypto(void) {}
    
    static char* bin2hex(unsigned char* bin, int binLength);
    
};


#endif // __CC_EXTENSION_CCCRYPTO_H_
