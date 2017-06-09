//
//  ChatDemoHelper+Category.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 27/02/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//


#import "EMChatDemoHelper+Category.h"
//#import "ShareLocationAnnotation.h"
//#import "EMConversation+Draft.h"
#import <Hyphenate/Hyphenate.h>
//#import "EaseMessageViewController+GroupRead.h"
#import <objc/runtime.h>

#import "DefineKey.h"
//#import "LocalDataTools.h"


//#import "ChatDemoHelper+Retracement.h"

@implementation EMChatDemoHelper (Category)
+ (void)load {
    Method oldUpdataMessagesMethod = class_getInstanceMethod([EMChatDemoHelper class], @selector(didReceiveMessages:));
    Method newUpdataMessagesMethod = class_getInstanceMethod([EMChatDemoHelper class], @selector(ZYDDidReceiveMessages:));
    method_exchangeImplementations(oldUpdataMessagesMethod, newUpdataMessagesMethod);
    
    Method oldConversationListCallbackMethod = class_getInstanceMethod([EMChatDemoHelper class], @selector(didUpdateConversationList:));
    Method newConversationListCallbackMethod = class_getInstanceMethod([EMChatDemoHelper class], @selector(ZYDDidUpdateConversationList:));
    method_exchangeImplementations(oldConversationListCallbackMethod, newConversationListCallbackMethod);
}

- (void)ZYDDidReceiveMessages:(NSArray *)aMessages{
    NSMutableArray *msgAry = [[NSMutableArray alloc] init];
    NSMutableArray *noticeAry = [[NSMutableArray alloc] init];
    for (EMMessage *msg in aMessages) {
        if ([msg.from isEqualToString:@"admin"] && msg.chatType == EMChatTypeChat) {
            [noticeAry addObject:msg];
        }else {
            [msgAry addObject:msg];
        }
    }
    
    if (noticeAry.count > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"haveReceiveNotices" object:noticeAry];
    }
    
    if (msgAry.count > 0) {
        [self ZYDDidReceiveMessages:msgAry];
    }
}

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages {
    
//    [self tCmdRevokeMessagesDidReceive:aCmdMessages];
    
//    NSMutableSet *set = [[NSMutableSet alloc] init];
//    for (EMMessage *msg in aCmdMessages) {
//        if (msg.body.type == EMMessageBodyTypeCmd) {
//            EMCmdMessageBody *body = (EMCmdMessageBody *)msg.body;
//            if ([body.action isEqualToString:SHARE_LOCATION_MESSAGE_FLAG]) {
//                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
//                if (![msg.ext[STOP_SHARE_LOCATION_FLAG] boolValue]) {
//                    dic[LATITUDE] = msg.ext[LATITUDE];
//                    dic[LONGITUDE] = msg.ext[LONGITUDE];
//                }else {
//                    dic[STOP_SHARE_LOCATION_FLAG] = msg.ext[STOP_SHARE_LOCATION_FLAG];
//                }
//                dic[@"username"] = msg.from;
//                [set addObject:dic];
//            }
//            else if ([body.action isEqualToString:GROUP_READ_ACTION]) {
//                //群组消息已读
//                NSDictionary *ext = msg.ext;
//                NSString *groupId = ext[GROUP_READ_CONVERSATION_ID];
//                NSArray *msgIds = ext[GROUP_READ_MSG_ID_ARRAY];
//                NSString *readerName = msg.from;
//                [[LocalDataTools tools] addDataToPlist:groupId msgIds:msgIds readerName:readerName];
//            }
//        }
//    }
//    
//    if (set.count > 0) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:SHARE_LOCATION_NOTI_KEY object:set];
//    }
}

- (void)ZYDDidUpdateConversationList:(NSArray *)aConversationList{
    NSMutableArray *conversationAry = [[NSMutableArray alloc] init];
    for (EMConversation *conversation in aConversationList) {
        if ([conversation.conversationId isEqualToString:@"admin"]) {            
        }else {
            [conversationAry addObject:conversation];
        }
    }
    [self ZYDDidUpdateConversationList:conversationAry];
}


@end
