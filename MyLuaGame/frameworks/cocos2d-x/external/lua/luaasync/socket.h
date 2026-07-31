// copy from luasocket

#if __cplusplus
extern "C" {
#endif 

#include "lua.h"
#include "lauxlib.h"
#include "tolua/tolua++.h"



/*=========================================================================*\
* Platform specific compatibilization
\*=========================================================================*/
#ifdef _WIN32
#include "luasocket/wsocket.h"
#else
#include "luasocket/usocket.h"
#endif
#include "luasocket/socket.h"
#include "luasocket/select.h"

#if __cplusplus
}
#endif 