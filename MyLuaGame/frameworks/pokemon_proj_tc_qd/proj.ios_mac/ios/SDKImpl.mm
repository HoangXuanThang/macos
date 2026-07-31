//
//  SDKImpl.m
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

#include "SDKImpl.h"
#import "SDKDelegate.h"
#import <GavegameSDK/GavegameSDK.h>
#import <GavegameSDK/GameInfoVO.h>
#import <GavegameSDK/ProductVO.h>

//////////////////// CONFUSE_CODE BEGIN

void Notepad1667_AnimationCache_Performance()
{
    std::string res = "Illusion40133_Logical_LinearLayoutParameter";
    NSLog(@"testlog %s", res.c_str());
}

//////////////////// CONFUSE_CODE END


SDKImpl::SDKImpl(std::string fname, std::string bundle, int handler)
{
    funcName = fname;
    data = bundle;
    handlerID = handler;
}

void SDKImpl::pay()
{
//////////////////// CONFUSE_CODE_CALL BEGIN
Notepad1667_AnimationCache_Performance();
//////////////////// CONFUSE_CODE_CALL END
    
    NSLog(@"SDKImpl::pay --------------");
    NSDictionary *dic = stdstring2NSDict(this->data);
    if (dic == nil)
    {
        [SDKDelegate proxyCallback:this withData:@"error"];
        return;
    }

    ProductVO * product = [[ProductVO alloc]init];
    product.productID = [dic objectForKey:@"productID"];//商品ID
    product.productName = [dic objectForKey:@"productName"];//商品名称
    product.productDescription = [dic objectForKey:@"productDesc"];;//商品描述
    product.serverId =[dic objectForKey:@"area_id"];//玩家服务器ID
    product.serverName = [dic objectForKey:@"area"];//玩家服务器名称
    product.gameExtra = [dic objectForKey:@"extInfo"];//游戏透传信息
    product.currency = [dic objectForKey:@"currency"];//货币单位，如人民币：cny
    product.gameUserId = [dic objectForKey:@"roleId"];//玩家游戏角色ID
    product.gameUserName = [dic objectForKey:@"roleName"];//玩家游戏角色名称
    product.gameUserLevel = [dic objectForKey:@"roleLevel"];//玩家游戏角色等级
    product.amount = [[dic objectForKey:@"amount"] floatValue];//float .00支付的实际货币金额
    product.gameCoinAmount = [[dic objectForKey:@"rmb"] intValue];//int游戏币数量
    product.count = [[dic objectForKey:@"count"] intValue];//购买数量

    [[GavegameSDK sharedInstance] doBusiness:product result:^(NSInteger result, NSString *orderId) {
        NSLog(@"支付结果 result = %ld",(long)result);
        if (result == GAVEGAME_NO_ERROR)
        {
            NSLog(@"支付成功");
            [SDKDelegate proxyCallback:this withData:@"ok"];
        }
        else
        {
           NSLog(@"支付失败");
           [SDKDelegate proxyCallback:this withData:@"error"];
        }
    }];
}

void SDKImpl::login()
{
//////////////////// CONFUSE_CODE_CALL BEGIN
Notepad1667_AnimationCache_Performance();
//////////////////// CONFUSE_CODE_CALL END

    NSLog(@"SDKImpl::login --------------");
    [[GavegameSDK sharedInstance] doLogin:^(NSInteger result, NSString *userId, NSString *nickName, NSString *accessToken, NSString *thirdPlatformName, NSString *thirdPlatformUserId) {
        if (result == GAVEGAME_NO_ERROR)
        {
            NSLog(@"登录成功");
            NSDictionary *dict = @{
                @"token":accessToken,
                @"channelId":[[GavegameSDK sharedInstance] channelId],
                @"userId":[[GavegameSDK sharedInstance] userId],
                @"thirdPlatformName":[[GavegameSDK sharedInstance] thirdPlatformName],
                @"thirdPlatformUserId":[[GavegameSDK sharedInstance] thirdPlatformUserId]
            };
            NSString *jStr = NSDict2NSString(dict);
            NSLog(@"%@",dict);

            [SDKDelegate proxyCallback:this withData:jStr];
        }
        else if (result == GAVEGAME_ERROR_LOGIN_CANCEL)
        {
            NSLog(@"取消登录");
            [SDKDelegate proxyCallback:this withData:@"cancel"];
        }
        else
        {
            NSLog(@"登录失败");
            [SDKDelegate proxyCallback:this withData:@"error"];
         }
    }];
}

void SDKImpl::logout()
{
    if (this->data == "game")
    {
        [[GavegameSDK sharedInstance] doLogout];
    }
    // 等待AppController userLogout通知
}

void SDKImpl::commit()
{
    NSLog(@"SDKImpl::commit --------------");
    NSDictionary *dic = stdstring2NSDict(this->data);
    if (dic == nil)
    {
        [SDKDelegate proxyCallback:this withData:@"error"];
        return;
    }

    GameInfoVO *gameInfo = [[GameInfoVO alloc]init];
    gameInfo.gameUserId = [dic objectForKey:@"user_id"];
    gameInfo.gameUserName = [dic objectForKey:@"user_name"];
    gameInfo.gameServerId = [dic objectForKey:@"area_id"];
    gameInfo.gameServerName = [dic objectForKey:@"area"];
    gameInfo.gameUserLevel = [dic objectForKey:@"level"];
    gameInfo.gameUserVipLevel = [dic objectForKey:@"vip"];
    gameInfo.gameRoleCreateAt = [dic objectForKey:@"created_time"];
    gameInfo.uploadType = [dic objectForKey:@"upload_type"];
    [[GavegameSDK sharedInstance] uploadGameUserInfo:gameInfo];
    [SDKDelegate proxyCallback:this withData:@"ok"];
}

void SDKImpl::onLogoutSuccess()
{
    auto vec = [SDKDelegate getProxyCallbackByName:@"logout"];
    bool callbackOK = false;
    for (int i = 0; i < vec.size(); ++i)
    {
        SDKImpl* sdk = vec[i];
        //游戏内点击退出
        if (sdk->data == "game")
        {
            [SDKDelegate proxyCallback:sdk withData:@"ok"];
            callbackOK = true;
            vec.erase(vec.begin() + i);
            break;
        }
    }
    for (SDKImpl* sdk: vec)
    {
        if (!callbackOK)
        {
            [SDKDelegate proxyCallback:sdk withData:@"ok"];
            callbackOK = true;
            continue;
        }
        [SDKDelegate proxyCallbackDelete:sdk];
    }
}
