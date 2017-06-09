//
//  EaseMessageViewController+GroupMemberChange.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/15.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "EMChatViewController+GroupMemberChange.h"
#import <objc/runtime.h>
#import "DefineKey.h"
#import "EMMessageModel.h"
#import "EMPromptCell.h"
#import "EMChatBaseCell.h"

@implementation EMChatViewController (GroupMemberChange)

+ (void)load {
    Method oldMethod = class_getInstanceMethod([EMChatViewController class],
                                               @selector(tableView:cellForRowAtIndexPath:));
    Method newMethod = class_getInstanceMethod([EMChatViewController class],
                                               @selector(GMCTableView:cellForRowAtIndexPath:));
    method_exchangeImplementations(oldMethod, newMethod);
    
    Method oldHeightMethod = class_getInstanceMethod([EMChatViewController class],
                                                     @selector(tableView:heightForRowAtIndexPath:));
    Method newHeightMethod = class_getInstanceMethod([EMChatViewController class],
                                                     @selector(GMCTableView:heightForRowAtIndexPath:));
    method_exchangeImplementations(oldHeightMethod, newHeightMethod);
}

- (UITableViewCell *)GMCTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *_dataSource = [self valueForKey:@"dataSource"];
    EMMessageModel *model = _dataSource[indexPath.row];
    if (model.message.ext[GROUP_MEMBER_CHANGE_INSERT]) {
        NSString *cellIdentifier = [EMPromptCell promptCellIdentifier];
        EMPromptCell *cell = (EMPromptCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = (EMPromptCell *)[[[NSBundle mainBundle]loadNibNamed:@"EMPromptCell" owner:nil options:nil] firstObject];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        EMTextMessageBody *body = (EMTextMessageBody *)model.message.body;
        cell.promptLabel.text = body.text;
        return cell;
    }
    return [self GMCTableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)GMCTableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *_dataSource = [self valueForKey:@"dataSource"];
    EMMessageModel *model = _dataSource[indexPath.row];
    if (model.message.ext[GROUP_MEMBER_CHANGE_INSERT]) {
        return 44;
    }
    return [self GMCTableView:tableView heightForRowAtIndexPath:indexPath];
}


@end
