#include "aes.h"
#include "rijndael-api-fst.h"

#include <stdlib.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"

#include "confuse.h"
#ifdef __cplusplus
extern "C" {
#endif
	void* tj_malloc(size_t size);
	void* tj_calloc(size_t num, size_t size);
	void tj_free(void* ptr);
	void* tj_realloc(void* ptr, size_t size);

#ifdef __cplusplus
}
#endif

// "YouMi_Technology" -hex-> "596f754d695f546563686e6f6c6f6779"

//////////////////// CONST_STRING BEGIN
const char _mapping[128] = {
	60,58,10,37,35,105,32,118,31,65,2,68,98,25,4,62,
	46,77,84,39,53,45,15,106,95,72,66,19,54,111,116,52,
	48,110,73,42,90,30,126,119,79,22,99,120,74,93,88,56,
	86,94,70,1,85,107,13,49,17,78,64,100,20,7,44,16,
	18,43,63,33,112,61,28,29,109,89,123,11,92,27,59,67,
	51,96,24,21,97,41,101,104,125,57,71,81,113,34,122,26,
	47,127,108,76,36,75,8,121,102,12,117,82,38,5,91,83,
	69,23,9,124,114,40,80,0,6,103,50,14,55,3,115,87
};


static const char* _mappingChars(const char* arr, int n)
{
	static char ret[1024];
	for (int i = 0; i < n; i++)
	{
		ret[i] = _mapping[arr[i]];
	}
	ret[n] = 0;
	return ret;
}


// ivHex = "596f754d695f546563686e6f6c6f6779";
// _mappingChars(ivHex, sizeof(ivHex))
const char ivHex[32] = {20,89,28,104,124,20,31,59,28,89,20,104,20,31,28,20,28,80,28,47,28,86,28,104,28,42,28,104,28,124,124,89};
//////////////////// CONST_STRING END

const char* realIVHex = NULL;

static int key128Hex(lua_State *L);
static int encryptCBC(lua_State *L);
static int decryptCBC(lua_State *L);

/* code support functions */
static luaL_Reg func[] = {
	{"key128Hex",   key128Hex},
	{"encryptCBC",  encryptCBC},
	{"decryptCBC",  decryptCBC},
	{NULL,          NULL}
};

static char* bin2hex(unsigned char* bin, int binLength)
{
	static const char* hextable = "0123456789abcdef";

	int hexLength = binLength * 2 + 1;
	char* hex = (char*)tj_malloc(hexLength);

	int i = 0;
	int ci = 0;
	for (i = 0; i < binLength; ++i)
	{
		unsigned char c = bin[i];
		hex[ci++] = hextable[(c >> 4) & 0x0f];
		hex[ci++] = hextable[c & 0x0f];
	}
	hex[ci] = 0;

	return hex;
}

//************************************
// Method:    keyHexAES
// Returns:   key hex string
// Parameter: char key[16]
//************************************
static int key128Hex(lua_State *L)
{
	size_t keyLen = 0;
	const char* key = luaL_checklstring(L, 1, &keyLen);
	char keyBuf[17];
	char* keyHex = NULL;
	if (keyLen < 16)
	{
		memset(keyBuf, 0, sizeof(keyBuf));
		memcpy(keyBuf, key, keyLen);
		key = keyBuf;
	}

	keyHex = bin2hex((unsigned char*)key, 16);
	lua_pushstring(L, keyHex);
	tj_free(keyHex);
	return 1;
}

//************************************
// Method:    encryptCBC
// Returns:   encrypt string
// Parameter: unsigned char * plaintext
// Parameter: char key[32], from key128Hex
//************************************
static int encryptCBC(lua_State *L)
{
	keyInstance ekey;
	cipherInstance ecip;
	char* result = NULL;
	int ret = 0;
	size_t plaintextLength = 0, keyLen = 0;
	const char* plaintext = luaL_checklstring(L, 1, &plaintextLength);
	const char* key = luaL_checklstring(L, 2, &keyLen);
	if (plaintextLength % 16 != 0)
	{
		lua_pushstring(L, "AES need plaintextLength is multiple of 16!");
		lua_error(L);
		return 0;
	}
	if (keyLen != 64 && keyLen != 32)
	{
		lua_pushstring(L, "AES need hex key, use key128Hex() convert!");
		lua_error(L);
		return 0;
	}

	ret = makeKey(&ekey, DIR_ENCRYPT, keyLen*8/2, (char*)key);
	if (ret != TRUE)
	{
		char err[128];
		sprintf(err, "AES makeKey error %d!", ret);
		lua_pushstring(L, err);
		lua_error(L);
		return 0;
	}

	ret = cipherInit(&ecip, MODE_CBC, (char*)realIVHex);
	if (ret != TRUE)
	{
		char err[128];
		sprintf(err, "AES cipherInit error %d!", ret);
		lua_pushstring(L, err);
		lua_error(L);
		return 0;
	}

	result = (char*)tj_malloc(plaintextLength+1);
	ret = blockEncrypt(&ecip, &ekey, (BYTE*)plaintext, plaintextLength*8, (BYTE*)result);
	lua_pushlstring(L, result, ret/8);
	tj_free(result);

	return 1;
}

//************************************
// Method:    decryptCBC
// Returns:   decrypt string
// Parameter: unsigned char * ciphertext
// Parameter: char key[32], from key128Hex
//************************************
static int decryptCBC(lua_State *L)
{
	keyInstance dkey;
	cipherInstance dcip;
	char* result = NULL;
	int ret = 0;
	size_t ciphertextLength = 0, keyLen = 0;
	const char* ciphertext = luaL_checklstring(L, 1, &ciphertextLength);
	const char* key = luaL_checklstring(L, 2, &keyLen);
	if (ciphertextLength % 16 != 0)
	{
		lua_pushstring(L, "AES need ciphertextLength is multiple of 16!");
		lua_error(L);
		return 0;
	}
	if (keyLen != 64 && keyLen != 32)
	{
		lua_pushstring(L, "AES need hex key, use key128Hex() convert!");
		lua_error(L);
		return 0;
	}

	
	ret = makeKey(&dkey, DIR_DECRYPT, keyLen*8/2, (char*)key);
	if (ret != TRUE)
	{
		char err[128];
		sprintf(err, "AES makeKey error %d!", ret);
		lua_pushstring(L, err);
		lua_error(L);
		return 0;
	}

	ret = cipherInit(&dcip, MODE_CBC, (char*)realIVHex);
	if (ret != TRUE)
	{
		char err[128];
		sprintf(err, "AES cipherInit error %d!", ret);
		lua_pushstring(L, err);
		lua_error(L);
		return 0;
	}

	result = (char*)tj_malloc(ciphertextLength+1);
	ret = blockDecrypt(&dcip, &dkey, (BYTE*)ciphertext, ciphertextLength*8, (BYTE*)result);
	lua_pushlstring(L, result, ret/8);
	tj_free(result);

	return 1;
}

LUAAES_API int luaopen_aes(lua_State *L)
{
	if (realIVHex == NULL)
	{
		realIVHex = _mappingChars(ivHex, sizeof(ivHex));
	}

#if LUA_VERSION_NUM > 501 && !defined(LUA_COMPAT_MODULE)
	lua_newtable(L);
	luaL_setfuncs(L, func, 0);
#else
	luaL_openlib(L, "aes", func, 0);
#endif
	/* make version string available to scripts */
	lua_pushstring(L, "_VERSION");
	lua_pushstring(L, LUAAES_VERSION);
	lua_rawset(L, -3);
	lua_pushstring(L, "_COPYRIGHT");
	lua_pushstring(L, LUAAES_COPYRIGHT);
	lua_rawset(L, -3);
	lua_pushstring(L, "_AUTHORS");
	lua_pushstring(L, LUAAES_AUTHORS);
	lua_rawset(L, -3);
	/* initialize lookup tables */
	return 1;
}

