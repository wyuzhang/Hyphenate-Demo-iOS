//
//  AppDelegate+PrivateDeploy.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/6/1.
//  Copyright © 2017年 easemob. All rights reserved.
//

#import "AppDelegate+PrivateDeploy.h"
#import <Hyphenate/EMOptions+PrivateDeploy.h>
#import <objc/runtime.h>

static char userDefaultsKey;

@interface AppDelegate()

@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end

@implementation AppDelegate (PrivateDeploy)

#pragma mark - Getter

- (NSUserDefaults *)userDefaults {
    return objc_getAssociatedObject(self, &userDefaultsKey);
}

#pragma mark - Setter

- (void)setUserDefaults:(NSUserDefaults *)userDefaults {
    objc_setAssociatedObject(self, &userDefaultsKey, userDefaults, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


#pragma mark - Public

- (BOOL)isUsePrivateDeploy {
    if (!self.userDefaults) {
        self.userDefaults = [NSUserDefaults standardUserDefaults];
    }
    BOOL isEnable = [self.userDefaults boolForKey:@"identifier_private_enable"];
    return isEnable;
}

- (BOOL)isUseDNSConfig {
    if (!self.userDefaults) {
        self.userDefaults = [NSUserDefaults standardUserDefaults];
    }
    BOOL isEnable = [self.userDefaults boolForKey:@"identifier_dnsconfig_enable"];
    return isEnable;
}

- (EMError *)initializeSDKWithPrivateDeploy {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (weakSelf) {
            [weakSelf.userDefaults setBool:NO forKey:@"identifier_dnsconfig_enable"];
            [weakSelf.userDefaults synchronize];
        }
    });
    
    //获取配置
    NSString *appKey = [self.userDefaults objectForKey:@"identifier_private_appkey"];
    NSString *imServer = [self.userDefaults objectForKey:@"identifier_private_imserver"];
    NSString *imPort = [self.userDefaults objectForKey:@"identifier_private_import"];
    NSString *restServer = [self.userDefaults objectForKey:@"identifier_private_restserver"];
    NSString *apnsCertName = [self.userDefaults objectForKey:@"identifier_private_cername"];
    if (apnsCertName.length == 0) {
        apnsCertName = @"chatdemoui";
    }
    BOOL useHttpsOnly = [self.userDefaults boolForKey:@"identifier_httpsonly"];

    NSString *description = @"";
    if (appKey.length <= 0) {
        description = NSLocalizedString(@"privateDeploy.appkeyError", @"Appkey input error");
        [self showAlertWithMessage:description];
        return [EMError errorWithDescription:description code:EMErrorInvalidAppkey];
    }
    else if (imServer.length <= 0) {
        description = NSLocalizedString(@"privateDeploy.imServerError", @"IM service address input error");
        [self showAlertWithMessage:description];
        return [EMError errorWithDescription:description code:EMErrorServerUnknownError];
    }
    else if (restServer.length <= 0) {
        description = NSLocalizedString(@"privateDeploy.restServerError", @"REST service address input error");
        [self showAlertWithMessage:description];
        return [EMError errorWithDescription:description code:EMErrorServerUnknownError];
    }
    
    EMOptions *options = [EMOptions optionsWithAppkey:appKey];
    options.enableConsoleLog = YES;
    options.enableDnsConfig = NO;
    options.apnsCertName = apnsCertName;
    options.usingHttpsOnly = useHttpsOnly;
    options.restServer = restServer;
    options.isAutoAcceptGroupInvitation = NO;
    if (imPort.length > 0) {
        options.chatPort = [imPort intValue];
    }
    options.chatServer = imServer;
    
    EMError *error = nil;
    error = [[EMClient sharedClient] initializeSDKWithOptions:options];
    
    return error;
}


- (EMError *)initializeSDKWithDNSConfig {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (weakSelf) {
            [weakSelf.userDefaults setBool:NO forKey:@"identifier_private_enable"];
            [weakSelf.userDefaults synchronize];
        }
    });
    
    //获取配置
    NSString *appKey = [self.userDefaults objectForKey:@"identifier_dnsconfig_appkey"];
    NSString *dnsUrl = [self.userDefaults objectForKey:@"identifier_dnsconfig_dnsurl"];
    NSString *apnsCertName = [self.userDefaults objectForKey:@"identifier_dnsconfig_cername"];
    if (apnsCertName.length == 0) {
        apnsCertName = @"chatdemoui";
    }
    BOOL useHttpsOnly = [self.userDefaults boolForKey:@"identifier_httpsonly"];
    
    
    NSString *description = @"";
    if (appKey.length <= 0) {
        description = NSLocalizedString(@"privateDeploy.appkeyError", @"Appkey input error");
        [self showAlertWithMessage:description];
        return [EMError errorWithDescription:description code:EMErrorInvalidAppkey];
    }
    else if (dnsUrl.length <= 0) {
        description = NSLocalizedString(@"privateDeploy.dnsUrlError", @"DNS Url input error");
        [self showAlertWithMessage:description];
        return [EMError errorWithDescription:description code:EMErrorServerUnknownError];
    }
    
    EMOptions *options = [EMOptions optionsWithAppkey:appKey];
    options.enableConsoleLog = YES;
    options.apnsCertName = apnsCertName;
    options.usingHttpsOnly = useHttpsOnly;
    options.dnsURL = dnsUrl;
    options.isAutoAcceptGroupInvitation = NO;
    
    EMError *error = nil;
    error = [[EMClient sharedClient] initializeSDKWithOptions:options];
    
    return error;
}


- (void)showAlertWithMessage:(NSString *)msg {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alertView show];
}

@end
