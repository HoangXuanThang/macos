//
//  SDKCommon.m
//  MyLuaGame
//
//  Created by MacMini2 on 17/8/23.
//
//

#import "SDKCommon.h"

#import "cocos2d.h"
#import "CCLuaEngine.h"
#import "CCLuaBridge.h"

#include <mutex>
#include <unordered_set>
using namespace cocos2d;

static std::mutex sdkreqs_mutex;
static std::unordered_set <SDKIOS*> sdkreqs;

@implementation SDKCommon

+(void) master: (NSDictionary *)dic
{
    NSString *bundle = [dic objectForKey:@"bundle"];
    NSString *callback = [dic objectForKey:@"callback"];
    NSString *fname = [dic objectForKey:@"funcName"];
    
    int handlerID = (int)[callback integerValue];
    SDKIOS* sdk = new SDKIOS([fname UTF8String], [bundle UTF8String], handlerID);
    {
        std::lock_guard<std::mutex> lk(sdkreqs_mutex);
        sdkreqs.insert(sdk);
    }
   
    NSLog(@"SDKCommon:master＋＋＋＋＋＋＋＋＋＋＋＋＋");
    NSLog(@"%p %@ %d %@", sdk, fname, handlerID, bundle);
    if ([fname isEqual: @"login"]) {
        // 登陆
        sdk->login();
        
    }else if ([fname isEqual:@"commitRoleInfo"]){
        // 提交用户数据
        sdk->commit();
        
    }else if ([fname isEqual:@"pay"]){
        // 支付
        sdk->pay();
        
    }else if ([fname isEqual:@"logout"]){
        //logout登出
        sdk->logout();
        
    }else if ([fname isEqual:@"isHasNotchScreen"]){
        // 刘海屏判断
        if (@available(iOS 11.0, *)) {
            CGFloat safeBottom = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom;
            NSLog(@"safeBottom %f", safeBottom);
            if (safeBottom > 0) {
                [self masterCallback:sdk withData:@"1"];
            }else{
                [self masterCallback:sdk withData:@"0"];
            }
        } else {
            [self masterCallback:sdk withData:@"0"];
        }
    }
}

+(void) masterCallbackDelete: (SDKIOS *) sdk
{
    NSLog(@"SDKCommon:masterCallbackDelete＋＋＋＋＋＋＋＋＋＋＋＋＋");
    NSLog(@"%p %s %d %s", sdk, sdk->funcName.c_str(), sdk->handlerID, sdk->data.c_str());
    {
        std::lock_guard<std::mutex> lk(sdkreqs_mutex);
        sdkreqs.erase(sdk);
    }
    delete sdk;
}

+(void) masterCallbackByName: (NSString *)name withData:(NSString *)data
{
    NSLog(@"SDKCommon:masterCallbackByName＋＋＋＋＋＋＋＋＋＋＋＋＋");
    NSLog(@"%@ %@", name, data);
    
    std::string fname = [name UTF8String];
    SDKIOS* sdk = nullptr;
    
    {
        std::lock_guard<std::mutex> lk(sdkreqs_mutex);
        for (auto it = sdkreqs.begin(); it != sdkreqs.end(); )
        {
            SDKIOS* p = *it;
            if (p->funcName == fname)
            {
                if (sdk)
                    delete sdk;
                sdk = p;
                it = sdkreqs.erase(it);
            }
            else
                ++it;
        }
    }
    
    [self masterCallback:sdk withData:data];
}

+(void) masterCallback: (SDKIOS *) sdk withData:(NSString *)data
{
    NSLog(@"SDKCommon:masterCallback＋＋＋＋＋＋＋＋＋＋＋＋＋");
    NSLog(@"%p %s %d %s, %@", sdk, sdk->funcName.c_str(), sdk->handlerID, sdk->data.c_str(), data);
    
    int handlerID = sdk->handlerID;
    LuaStack *stack = LuaBridge::getStack();  //获取lua栈
    const char* cstr = [data UTF8String];
    
    LuaBridge::pushLuaFunctionById(handlerID); //压入需要调用的方法id（假设方法为XG）
    stack->pushString(cstr);  //将需要通过方法XG传递给lua的参数压入lua栈
    stack->executeFunction(1);  //根据压入的方法id调用方法XG，并把XG方法参数传递给lua代码
    LuaBridge::releaseLuaFunctionById(handlerID);
    
    {
        std::lock_guard<std::mutex> lk(sdkreqs_mutex);
        sdkreqs.erase(sdk);
    }
    delete sdk;
}

@end

NSDictionary* stdstring2NSDict(const std::string& jsonStr)
{
    NSString *s = [[NSString alloc] initWithUTF8String: jsonStr.c_str()];
    NSData *jsonData = [s dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if (err)
    {
        NSLog(@"json error %@", [err localizedDescription]);
        return nil;
    }
    return dic;
}

NSString* NSDict2NSString(const NSDictionary* dic)
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:0];
    NSString *jStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jStr;
}
