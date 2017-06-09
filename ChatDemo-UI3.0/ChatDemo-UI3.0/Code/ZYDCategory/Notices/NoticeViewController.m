//
//  NoticeViewController.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 27/02/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "NoticeViewController.h"
#import <Hyphenate/Hyphenate.h>
#import "NoticeInfoViewController.h"
#import "NoticeTableViewCell.h"
#import "UIViewController+HUD.h"
@interface NoticeViewController () {
    NSString *_currentId;
}
@property (nonatomic, strong) EMConversation *conversation;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic) NSInteger pageNum;
@end

@implementation NoticeViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _dataSource = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"公告";
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    backButton.accessibilityIdentifier = @"back";
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backItem];

    self.tableView.sectionIndexColor = BrightBlueColor;
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    
    self.showRefreshHeader = YES;
    self.conversation = [[EMClient sharedClient].chatManager getConversation:@"admin"
                                                                        type:EMConversationTypeChat
                                                            createIfNotExist:YES];

    [self fetchChatWithMessageId:nil isHeader:YES];
    [self registNotifications];
    UINib *nib = [UINib nibWithNibName:@"NoticeTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"NOTICECELL"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)registNotifications {
    [self unRegistNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveNotices:)
                                                 name:@"haveReceiveNotices"
                                               object:nil];
}

- (void)unRegistNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"haveReceiveNotices" object:nil];
}

-(void)dealloc {
    [self unRegistNotifications];
}

- (void)didReceiveNotices:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSArray class]]) {
        [self fetchChatWithMessageId:nil isHeader:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        EMMessage *msg = self.dataSource[indexPath.row];
        [self.conversation deleteMessageWithId:msg.messageId error:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setupUnreadMessageCount" object:nil];
        [self.dataSource removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoticeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NOTICECELL"];
    EMMessage *msg = self.dataSource[indexPath.row];
    EMTextMessageBody *textBody = (EMTextMessageBody *)msg.body;
    cell.noticeLabel.text = textBody.text;
    if (msg.isRead) {
        cell.unreadLabel.text = @"已读";
    }else {
        cell.unreadLabel.text = @"未读";
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    EMMessage *msg = self.dataSource[indexPath.row];
    [self.conversation markMessageAsReadWithId:msg.messageId error:nil];
    NoticeInfoViewController *noticeInfo = [[NoticeInfoViewController alloc] initWithMessage:msg];
    [self.navigationController pushViewController:noticeInfo animated:YES];
}

- (void)tableViewDidTriggerHeaderRefresh
{
    _currentId = nil;
    [self fetchChatWithMessageId:_currentId isHeader:YES];
}

- (void)tableViewDidTriggerFooterRefresh
{
    [self fetchChatWithMessageId:_currentId isHeader:NO];
}

- (void)fetchChatWithMessageId:(NSString *)aMessageId
                 isHeader:(BOOL)aIsHeader
{
    [self hideHud];
    [self showHudInView:self.view hint:NSLocalizedString(@"loadData", @"Load data...")];
    
    WEAK_SELF
    [self.conversation loadMessagesStartFromId:aIsHeader?nil:aMessageId count:15
                               searchDirection:EMMessageSearchDirectionUp
                                    completion:^(NSArray *aMessages, EMError *aError) {
                                        if (aMessages) {
                                            [weakSelf hideHud];
                                            EMMessage *msg = aMessages.firstObject;
                                            self->_currentId = msg.messageId;
                                            NSArray* unTopSorted = [aMessages sortedArrayUsingComparator:
                                                                    ^(EMMessage *obj1, EMMessage* obj2){
                                                                        if(obj1.timestamp > obj2.timestamp) {
                                                                            return(NSComparisonResult)NSOrderedAscending;
                                                                        }else {
                                                                            return(NSComparisonResult)NSOrderedDescending;
                                                                        }
                                                                    }];
                                            
                                            
                                            
                                            if(aIsHeader) {
                                                [weakSelf.dataSource removeAllObjects];
                                            }
                                            [weakSelf.dataSource addObjectsFromArray:unTopSorted];
                                            [weakSelf.tableView reloadData];
                                            if (aMessages.count == 15) {
                                                weakSelf.showRefreshFooter = YES;
                                            } else {
                                                weakSelf.showRefreshFooter = NO;
                                            }
                                            [weakSelf tableViewDidFinishTriggerHeader:aIsHeader];
                                        }
                                    }];
}

@end
