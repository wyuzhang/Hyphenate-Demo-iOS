/************************************************************
 *  * Hyphenate
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 */

#import "AppDelegate.h"

#import <UserNotifications/UserNotifications.h>
#import "EMMainViewController.h"
#import "EMLoginViewController.h"
#import "EMLaunchViewController.h"
#import "EMChatDemoHelper.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "AppDelegate+Parse.h"

@interface AppDelegate () <EMClientDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0) {
        [[UITabBar appearance] setBarTintColor:DefaultBarColor];
        [[UITabBar appearance] setTintColor:KermitGreenTwoColor];
        [[UINavigationBar appearance] setBarTintColor:DefaultBarColor];
        [[UINavigationBar appearance] setTintColor:AlmostBlackColor];
        [[UINavigationBar appearance] setTranslucent:NO];
    }
    
    [self parseApplication:application didFinishLaunchingWithOptions:launchOptions];
    
    // init HyphenateSDK
    EMOptions *options = [EMOptions optionsWithAppkey:@"hyphenatedemo#hyphenatedemo"];

    // Hyphenate cert keys
    NSString *apnsCertName = nil;
    #if DEBUG
        apnsCertName = @"DevelopmentCertificate";
    #else
        apnsCertName = @"ProductionCertificate";
    #endif
    
    [options setApnsCertName:apnsCertName];
    [options setEnableConsoleLog:YES];
    [[EMClient sharedClient] initializeSDKWithOptions:options];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginStateChange:)
                                                 name:KNOTIFICATION_LOGINCHANGE
                                               object:nil];
    
    [EaseCallManager sharedManager];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    EMLaunchViewController *launch = [[EMLaunchViewController alloc] init];
    self.window.rootViewController = launch;
    [self.window makeKeyAndVisible];
    
    [self _registerAPNS];
    [self registerNotifications];
    
    // Fabric
    [Fabric with:@[[Crashlytics class]]];
    
    return YES;
}

- (void)loginStateChange:(NSNotification *)notification
{
    BOOL loginSuccess = [notification.object boolValue];
    if (loginSuccess) {

        EMMainViewController *main = [[EMMainViewController alloc] init];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:main];
        navigationController.interactivePopGestureRecognizer.delegate = (id)self;
        self.window.rootViewController = navigationController;
        [EMChatDemoHelper shareHelper].mainVC = main;
        
    } else {
        EMLoginViewController *login = [[EMLoginViewController alloc] init];
        self.window.rootViewController = login;
        [EMChatDemoHelper shareHelper].mainVC = nil;
    }
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[EMClient sharedClient] applicationDidEnterBackground:application];
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[EMClient sharedClient] applicationWillEnterForeground:application];
    
    if ([EMChatDemoHelper shareHelper].pushVC) {
        [[EMChatDemoHelper shareHelper].pushVC reloadNotificationStatus];
    }
    
    if ([EMChatDemoHelper shareHelper].settingsVC) {
        [[EMChatDemoHelper shareHelper].settingsVC reloadNotificationStatus];
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    if ([EMChatDemoHelper shareHelper].mainVC) {
        [[EMChatDemoHelper shareHelper].mainVC didReceiveLocalNotification:notification];
    }
}

#pragma mark - App Delegate

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[EMClient sharedClient] registerForRemoteNotificationsWithDeviceToken:deviceToken completion:^(EMError *aError) {
        
    }];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"apns.failToRegisterApns", Fail to register apns)
                                                    message:error.description
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)_registerAPNS
{
    UIApplication *application = [UIApplication sharedApplication];
    application.applicationIconBadgeNumber = 0;
    
    if (NSClassFromString(@"UNUserNotificationCenter")) {
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert completionHandler:^(BOOL granted, NSError *error) {
            if (granted) {
#if !TARGET_IPHONE_SIMULATOR
                [application registerForRemoteNotifications];
#endif
            }
        }];
        return;
    }
    
    if([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationType notificationTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    
#if !TARGET_IPHONE_SIMULATOR
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        [application registerForRemoteNotifications];
    }
#endif
}

- (void)registerNotifications
{
    [self unregisterNotifications];
    [[EMClient sharedClient] addDelegate:self delegateQueue:nil];
}

- (void)unregisterNotifications
{
    [[EMClient sharedClient] removeDelegate:self];
}

#pragma mark - EMClientDelegate

- (void)autoLoginDidCompleteWithError:(EMError *)aError
{
#if DEBUG
    NSString *alertMsg = aError == nil ? NSLocalizedString(@"login.endAutoLogin.succeed", @"Automatic login succeed") : NSLocalizedString(@"login.endAutoLogin.failure", @"Automatic login failed");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:alertMsg delegate:nil cancelButtonTitle:NSLocalizedString(@"login.ok", @"Ok") otherButtonTitles:nil, nil];
    [alert show];
#endif
}

@end
