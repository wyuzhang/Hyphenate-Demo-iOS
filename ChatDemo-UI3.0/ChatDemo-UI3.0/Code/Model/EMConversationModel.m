/************************************************************
 *  * Hyphenate
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 */

#import "EMConversationModel.h"

#import "EMUserProfileManager.h"

@implementation EMConversationModel

- (instancetype)initWithConversation:(EMConversation*)conversation
{
    self = [super init];
    if (self) {
        _conversation = conversation;
        
        NSString *subject = [conversation.ext objectForKey:@"subject"];
        if ([subject length] > 0) {
            _title = subject;
        }
        
        if (_conversation.type == EMConversationTypeGroupChat) {
            NSArray *groups = [[EMClient sharedClient].groupManager getJoinedGroups];
            for (EMGroup *group in groups) {
                if ([_conversation.conversationId isEqualToString:group.groupId]) {
                    _title = group.subject;
                    break;
                }
            }
        }
        
        if ([_title length] == 0) {
            _title = _conversation.conversationId;
        }
    }
    return self;
}

- (NSString*)title
{
    if (_conversation.type == EMConversationTypeChat) {
        return [[EMUserProfileManager sharedInstance] getNickNameWithUsername:_conversation.conversationId];
    } else {
        return _title;
    }
}

- (BOOL)isTop {
    return [self.conversation.ext[@"isTop"] boolValue];
}

- (void)setIsTop:(BOOL)isTop {
    NSMutableDictionary *dic = [self.conversation.ext mutableCopy];
    if (!dic) {
        dic = [NSMutableDictionary dictionary];
    }
    dic[@"isTop"] = isTop ? @YES : @NO;
    self.conversation.ext = dic;
}

- (void)removeComplation:(void(^)())aComplation {
    [[EMClient sharedClient].chatManager deleteConversation:self.conversation.conversationId isDeleteMessages:YES completion:^(NSString *aConversationId, EMError *aError) {
        if (aComplation) {
            aComplation();
        }
    }];
}

@end
