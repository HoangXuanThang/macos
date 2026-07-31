//
//  SDKIOS.m
//  MyLuaGame
//
//  相关sdk接入实现放在这里
//  从lua传递的数据为json字符串
//  json中的数据均为直接对于sdk参数
//  不要在这里做数据转换工作，应当在lua中处理，以支持热更新
//  解决所有xcode的warning
//  ！！！ 未按上述提及方式实现，后果自负 ！！！
//  ！！！ 未按上述提及方式实现，后果自负 ！！！
//  ！！！ 未按上述提及方式实现，后果自负 ！！！
//

#include "SDKIOS.h"
#import "SDKCommon.h"


SDKIOS::SDKIOS(std::string fname, std::string bundle, int handler)
{
    funcName = fname;
    data = bundle;
    handlerID = handler;
}

void SDKIOS::pay()
{
    NSLog(@"SDKIOS::pay--------------");
    NSDictionary *dic = stdstring2NSDict(this->data);
    if (dic == nil)
    {
        [SDKCommon masterCallback:this withData:@"1"];
        return;
    }
    
}

void SDKIOS::login()
{
    NSLog(@"SDKIOS::login--------------");
}

void SDKIOS::logout()
{
    // 等待AppController userLogout通知
}

void SDKIOS::commit()
{
    NSLog(@"SDKIOS::commit--------------");
    NSDictionary *dic = stdstring2NSDict(this->data);
    if (dic == nil)
    {
        [SDKCommon masterCallback:this withData:@"1"];
        return;
    }
    

}

void SDKIOS::adEvent(int eventIdx)
{
    
}

void SDKIOS::onLogoutSuccess()
{
    [SDKCommon masterCallbackByName:@"logout" withData:@"0"];
}
