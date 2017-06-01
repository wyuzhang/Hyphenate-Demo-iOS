/************************************************************
 *  * Hyphenate
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, EMGroupInfoPermissionType) {
    EMGroupInfoPermissionType_groupType            =      0,
    EMGroupInfoPermissionType_canAllInvite,
    EMGroupInfoPermissionType_openJoin,
    EMGroupInfoPermissionType_mute,
    EMGroupInfoPermissionType_pushSetting,
    EMGroupInfoPermissionType_groupId
};
@class EMGroupPermissionModel;

@interface EMGroupPermissionCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *permissionTitleLabel;

@property (strong, nonatomic) IBOutlet UISwitch *permissionSwitch;

@property (copy, nonatomic) void (^ReturnSwitchState)(BOOL isOn);

@property (strong, nonatomic) EMGroupPermissionModel *model;

@end

@interface EMGroupPermissionModel : NSObject

@property (nonatomic, assign) EMGroupInfoPermissionType type;

@property (nonatomic, assign) BOOL isEdit;

@property (nonatomic, strong) NSString *title;

@property (nonatomic, assign) BOOL switchState;

@property (nonatomic, strong) NSString *permissionDescription;

@end
