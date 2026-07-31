//
//  SDKDelegate.h
//  MyLuaGame
//
//  Created by MacMini2 on 17/8/23.
//
//

#import <Foundation/Foundation.h>
#include <string>

@interface SDKDelegate : NSObject
@end

NSDictionary* stdstring2NSDict(const std::string& jsonStr);
NSString* NSDict2NSString(const NSDictionary* dic);
