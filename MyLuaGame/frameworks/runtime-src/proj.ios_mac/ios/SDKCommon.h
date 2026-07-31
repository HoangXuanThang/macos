//
//  SDKCommon.h
//  MyLuaGame
//
//  Created by MacMini2 on 17/8/23.
//
//

#import <Foundation/Foundation.h>
#import "SDKIOS.h"
#include <string>

@interface SDKCommon : NSObject
+(void) master: (NSDictionary *)dic;
+(void) masterCallback: (SDKIOS *) sdk withData:(NSString *)data;
+(void) masterCallbackDelete: (SDKIOS *) sdk;
+(void) masterCallbackByName: (NSString *)name withData:(NSString *)data;
@end


NSDictionary* stdstring2NSDict(const std::string& jsonStr);
NSString* NSDict2NSString(const NSDictionary* dic);
