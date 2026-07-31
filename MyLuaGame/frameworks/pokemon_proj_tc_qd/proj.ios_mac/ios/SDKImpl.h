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

class SDKImpl
{
public:
    SDKImpl(std::string fname, std::string bundle, int handler);

    void pay();
    void login();
    void logout();
    void commit();

    static void onLogoutSuccess();

    int handlerID;
    std::string funcName;
    std::string data;
};

#endif /* Header_h */
