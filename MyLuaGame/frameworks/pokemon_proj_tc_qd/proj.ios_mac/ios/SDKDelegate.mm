//
//  SDKDelegate.m
//  MyLuaGame
//
//  Created by MacMini2 on 17/8/23.
//
//

#import "SDKDelegate.h"
#import "cocos2d.h"
#import "CCLuaEngine.h"
#import "CCLuaBridge.h"

@implementation SDKDelegate

// ตัด proxy ทั้งหมดออก

@end

// คงไว้เฉพาะฟังก์ชันแปลง JSON
NSDictionary* stdstring2NSDict(const std::string& jsonStr)
{
    NSString *s = [[NSString alloc] initWithUTF8String: jsonStr.c_str()];
    NSData *jsonData = [s dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err = nil;
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
