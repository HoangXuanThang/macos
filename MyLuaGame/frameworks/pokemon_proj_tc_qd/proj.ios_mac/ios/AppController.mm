#import "AppController.h"
#import "cocos2d.h"
#import "AppDelegate.h"
#import "RootViewController.h"
//#import "XGPush.h"
#import "BreakpadController.h" // ถ้าไม่ใช้จริง สามารถลบได้

#import <GavegameSDK/GavegameSDK.h>
#import <GavegameSDK/GameInfoVO.h>
#import <GavegameSDK/ProductVO.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

@implementation AppController

@synthesize window;

static AppDelegate s_sharedApplication;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    cocos2d::Application *app = cocos2d::Application::getInstance();
    
    app->initGLContextAttrs();
    cocos2d::GLViewImpl::convertAttrs();
    
    window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    _viewController = [[RootViewController alloc]init];
    _viewController.wantsFullScreenLayout = YES;

    if ( [[UIDevice currentDevice].systemVersion floatValue] < 6.0) {
        [window addSubview: _viewController.view];
    } else {
        [window setRootViewController:_viewController];
    }

    [window makeKeyAndVisible];
    
    [[UIApplication sharedApplication] setStatusBarHidden:true];
    
    cocos2d::GLView *glview = cocos2d::GLViewImpl::createWithEAGLView((__bridge void *)_viewController.view);
    cocos2d::Director::getInstance()->setOpenGLView(glview);
    
    [[GavegameSDK sharedInstance] initSDK:^(BOOL result) {
        NSLog(@"GavegameSDK initSDK %d", result);
    }];
    
    // [NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLogout) name:SG_NOTIFICATION_LOGOUT object:nil];

    app->run();
    
    [self writeFileArray];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {}
- (void)applicationDidBecomeActive:(UIApplication *)application {}
- (void)applicationDidEnterBackground:(UIApplication *)application {
    cocos2d::Application::getInstance()->applicationDidEnterBackground();
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
    cocos2d::Application::getInstance()->applicationWillEnterForeground();
}
- (void)applicationWillTerminate:(UIApplication *)application {}
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"[XGDemo] register APNS fail.\n[XGDemo] reason : %@", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"registerDeviceFailed" object:nil];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    cocos2d::Director::getInstance()->notifyLuaMemoryWarning();
}

#if __has_feature(objc_arc)
#else
- (void)dealloc {
    [window release];
    [_viewController release];
    [super dealloc];
}
#endif

- (int64_t)getTotalDiskSpace {
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) return -1;
    return [[attrs objectForKey:NSFileSystemSize] longLongValue];
}
- (int64_t)getFreeDiskSpace {
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) return -1;
    return [[attrs objectForKey:NSFileSystemFreeSize] longLongValue];
}
- (int64_t)getUsedDiskSpace {
    int64_t totalDisk = [self getTotalDiskSpace];
    int64_t freeDisk = [self getFreeDiskSpace];
    if (totalDisk < 0 || freeDisk < 0) return -1;
    return totalDisk - freeDisk;
}

- (void)writeFileArray {
    NSMutableDictionary *dic= [[NSMutableDictionary alloc]initWithCapacity:10];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSDate *datenow = [NSDate date];
    NSString *game_start_time = [formatter stringFromDate:datenow];
    NSLog(@"game_start_time = %@", game_start_time);
    
    NSString *game_name = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *app_Version = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *app_build = [[NSBundle mainBundle]bundleIdentifier];
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"res/version" ofType:@"plist"];
    NSString *channelPath = [[NSBundle mainBundle] pathForResource:@"res/channel" ofType:@"plist"];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    NSDictionary *channelDictionary = [[NSDictionary alloc] initWithContentsOfFile:channelPath];
    
    NSString *svn_version = [dictionary objectForKey:@"app_version"];
    NSString *svn_patch = [dictionary objectForKey:@"patch"];
    NSString *sdk = [channelDictionary objectForKey:@"channel"];
    NSString *systemName = [UIDevice currentDevice].systemName;
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *totalDisk = [NSString stringWithFormat:@"%llu GB", (([self getTotalDiskSpace] / 1024) / 1024 / 1024)];
    NSString *freeDisk = [NSString stringWithFormat:@"%llu MB", (([self getFreeDiskSpace] / 1024) / 1024 )];

    [dic setValue:game_start_time forKey:@"game_start_time"];
    [dic setValue:@"ios" forKey:@"type"];
    [dic setValue:game_name forKey:@"game_name"];
    [dic setValue:app_Version forKey:@"version_code"];
    [dic setValue:app_build forKey:@"package_name"];
    [dic setValue:svn_version forKey:@"svn_version"];
    [dic setValue:svn_patch forKey:@"svn_patch"];
    [dic setValue:uuid forKey:@"imei"];
    [dic setValue:@"ios" forKey:@"type"];
    [dic setValue:systemVersion forKey:@"type_int"];
    [dic setValue:systemName forKey:@"manufacturer"];
    [dic setValue:totalDisk forKey:@"total_memory"];
    [dic setValue:freeDisk forKey:@"available_memory"];
    [dic setValue:sdk forKey:@"sdk"];
    NSLog(@"%@", dic);
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:[self documentsPath:@"tj_device.log"] atomically:YES];
}

- (void)readFileArray {
    NSString *filePath = [self documentsPath:@"tj_device.log"];
    NSArray *userinfo = [NSArray arrayWithContentsOfFile:filePath];
    NSLog(@"%@", [userinfo objectAtIndex:1]);
}

- (NSString *)bundlePath:(NSString *)fileName {
    return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:fileName];
}
- (NSString *)documentsPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
}
- (NSString *)documentsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    [[GavegameSDK sharedInstance] application:application
                                      openURL:url
                            sourceApplication:sourceApplication
                                   annotation:annotation];
    return true;
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary *)options {
    [[GavegameSDK sharedInstance] application:app
                                      openURL:url
                                      options:options];
    return true;
}

- (BOOL)application:(UIApplication *)application
      handleOpenURL:(NSURL *)url {
    [[GavegameSDK sharedInstance] application:application
                                handleOpenURL:url];
    return true;
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(id)restorationHandler {
    [[GavegameSDK sharedInstance] application:application
                         continueUserActivity:userActivity
                           restorationHandler:restorationHandler];
    return true;
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[GavegameSDK sharedInstance] application:application
                 didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[GavegameSDK sharedInstance] application:application
                 didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[GavegameSDK sharedInstance] application:application
didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

@end
