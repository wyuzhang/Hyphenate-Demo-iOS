//
//  MainViewController+Category.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 27/02/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "EMMainViewController+Category.h"
#import "EMChatsViewController.h"
//#import "NoticeViewController.h"
#import <objc/runtime.h>

@interface EMMainViewController()
@property (nonatomic, strong) UIBarButtonItem *noticeItem;
@property (nonatomic, strong) UIView *lightView;
@end

@implementation EMMainViewController (Category)

- (NSObject *)noticeItem {
    return objc_getAssociatedObject(self, @selector(noticeItem));
}

- (void)setNoticeItem:(NSObject *)value {
    objc_setAssociatedObject(self, @selector(noticeItem), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSObject *)lightView {
    return objc_getAssociatedObject(self, @selector(lightView));
}

- (void)setLightView:(NSObject *)value {
    objc_setAssociatedObject(self, @selector(lightView), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


+(void)load {
    Method oldReadMethod = class_getInstanceMethod([self class], @selector(setupUnreadMessageCount));
    Method newReadMethod = class_getInstanceMethod([self class], @selector(ZYDSetupUnreadMessageCount));
    method_exchangeImplementations(oldReadMethod, newReadMethod);
    
    Method oldViewDidLoadMethod = class_getInstanceMethod([self class], @selector(viewDidLoad));
    Method newViewDidLoadMethod = class_getInstanceMethod([self class], @selector(ZYDViewDidLoad));
    method_exchangeImplementations(oldViewDidLoadMethod, newViewDidLoadMethod);
    
    Method oldChangeTabBarMethod = class_getInstanceMethod([self class], @selector(tabBar:didSelectItem:));
    Method newChangeTabBarMethod = class_getInstanceMethod([self class], @selector(ZYDTabBar:didSelectItem:));
    method_exchangeImplementations(oldChangeTabBarMethod, newChangeTabBarMethod);

}

- (void)ZYDViewDidLoad {
    [self ZYDViewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveNotices:)
                                                 name:@"haveReceiveNotices"
                                               object:nil];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    self.lightView = [[UIView alloc] initWithFrame:CGRectMake(35, 8, 10, 10)];
    self.lightView.backgroundColor = [UIColor redColor];
    self.lightView.layer.cornerRadius = 5;
    self.lightView.layer.masksToBounds = YES;
    [btn addSubview:self.lightView];
    [self lightOff];
    
    
    [btn setTitle:@"公告" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(noticeViewController) forControlEvents:UIControlEventTouchUpInside];
    self.noticeItem  = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.title = NSLocalizedString(@"title.conversation", @"Conversations");
    self.navigationItem.rightBarButtonItem = self.noticeItem;
}

- (void)lightOn{
    self.lightView.hidden = NO;
}

- (void)lightOff{
    self.lightView.hidden = YES;
}

- (void)didReceiveNotices:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSArray class]]) {
        [self lightOn];
    }else {
        [self lightOff];
    }
}
- (void)ZYDTabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item{
    if(item.tag == 0) {
        self.title = NSLocalizedString(@"title.conversation", @"Conversations");
        self.navigationItem.rightBarButtonItem = self.noticeItem;
        return;
    }
    
    [self ZYDTabBar:tabBar didSelectItem:item];
}

- (void)noticeViewController {
//    NoticeViewController *noticeVC = [[NoticeViewController alloc] initWithStyle:UITableViewStylePlain];
//    [self.navigationController pushViewController:noticeVC animated:YES];
}

- (void)ZYDSetupUnreadMessageCount{
    NSArray *conversations = [[EMClient sharedClient].chatManager getAllConversations];
    NSInteger unreadCount = 0;
    for (EMConversation *conversation in conversations) {
        if ([conversation.conversationId isEqualToString:@"admin"]) {
            if (conversation.unreadMessagesCount) {
                [self lightOn];
            }else{
                [self lightOff];
            }
            continue;
        }
        unreadCount += conversation.unreadMessagesCount;
    }
    if ([self valueForKey:@"_chatsVC"]) {
        EMChatsViewController *_chatListVC = (EMChatsViewController *)[self valueForKey:@"_chatsVC"];
        if (unreadCount > 0) {
            _chatListVC.tabBarItem.badgeValue = [NSString stringWithFormat:@"%i",(int)unreadCount];
        }else{
            _chatListVC.tabBarItem.badgeValue = nil;
        }
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    [application setApplicationIconBadgeNumber:unreadCount];

}

@end
