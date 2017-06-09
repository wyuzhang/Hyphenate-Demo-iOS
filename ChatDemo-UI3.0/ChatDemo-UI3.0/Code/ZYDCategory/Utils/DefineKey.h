//
//  DefineKey.h
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/11.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#ifndef DefineKey_h
#define DefineKey_h



#endif /* DefineKey_h */

#define CLEAR_QUEUE_TIME               5.0f
#define READ_CMD_TIMEINTERVAL          2.0f

#define GROUP_READ_ACTION              @"group_read_action"
#define GROUP_READ_MSG_ID_ARRAY        @"group_read_msg_id_array"
#define GROUP_READ_CONVERSATION_ID     @"group_read_conversation_id"

#define UPDATE_GROUPMSG_READCOUNT      @"updateGroupMessageReadCount"
#define ENTRY_GROUPMSG_READERLIST      @"entryGroupMessageReadersList"


#define REVOCATION @"Revocation"
#define REVOCATION_DELETE @"Revocation_delete"
#define REVOCATION_REFRESHCONVERSATIONS @"Revocation_refreshConversations"
#define REVOCATION_UPDATE_UNREAD_COUNT @"Revocation_updateUnreadCount"

#define GROUP_MEMBER_CHANGE_INSERT     @"group_member_change_insert"

#define REVOKE_FLAG                    @"revoke_flag"
#define MSG_ID                         @"msg_id"
#define INSERT                         @"insert"

#pragma mark - shareLocation
#define SHARE_LOCATION_NOTI_KEY @"ShareLocationNoti"

#define SHARE_LOCATION_MESSAGE_FLAG @"shareLocation"
#define STOP_SHARE_LOCATION_FLAG @"isStop"

#define LATITUDE @"latitude"
#define LONGITUDE @"longitude"


#define mark - draft
#define DRAFT_NOTI_KEY @"DraftNotifications"

#define kGoneAfterReadKey @"goneAfterReadKey"
/** @brief NSUserDefaults中保存当前已阅读但未发送ack回执的阅后即焚消息信息 */
#define NEED_REMOVE_MESSAGE_DIC            @"em_needRemoveMessages"
/** @brief 已读阅后即焚消息在NSUserDefaults保存的key前缀 */
#define KEM_REMOVEAFTERREAD_PREFIX                @"readFirePrefix"
//需要发送ack的阅后即焚消息信息在NSUserDefaults中的存放key
#define UserDefaultKey(username) [[KEM_REMOVEAFTERREAD_PREFIX stringByAppendingString:@"_"] stringByAppendingString:username]
/** @brief NSUserDefaults中保存当前阅读的阅后即焚消息信息 */
#define NEED_REMOVE_CURRENT_MESSAGE        @"em_needRemoveCurrnetMessage"
#define kReconnectAction @"RemoveUnFiredMsg"
#define kReconnectMsgIdKey @"REMOVE_UNFIRED_MSG"
