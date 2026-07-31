//
//  Header.h
//  MyLuaGame
//
//  Created by MacMini2 on 17/8/23.
//
//

#ifndef Header_h
#define Header_h

#include <string>

class SDKIOS
{
public:
    SDKIOS(std::string fname, std::string bundle, int handler);
    
    void pay();
    void login();
    void logout();
    void commit();
    void adEvent(int eventIdx);
    void loginSucess(const char * token, const char * displayName, const char * userId,const char * thirdPlatformName, const char * thirdPlatformUserId);
    
    static void onLogoutSuccess();

    int handlerID;
    std::string funcName;
    std::string data;
};

#endif /* Header_h */
