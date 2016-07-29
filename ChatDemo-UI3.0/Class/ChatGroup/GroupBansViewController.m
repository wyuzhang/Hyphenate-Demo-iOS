/************************************************************
 *  * Hyphenate  
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Hyphenate Inc.
 */

#import "GroupBansViewController.h"

#import "ContactView.h"
#import "EMGroup.h"

#define kColOfRow 5
#define kContactSize 60

@interface GroupBansViewController ()<EMGroupManagerDelegate>

@property (strong, nonatomic) EMGroup *group;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;
@property (nonatomic) BOOL isUpdate;
@property (nonatomic) BOOL isEditing;

@end

@implementation GroupBansViewController

@synthesize scrollView = _scrollView;
@synthesize longPress = _longPress;

- (instancetype)initWithGroup:(EMGroup *)group
{
    self = [self init];
    
    if (self) {
        
        self.group = group;
        self.isEditing = NO;
        self.isUpdate = NO;
        
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"title.groupBlackList", @"Group's Blacklist");
    
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"]
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(backAction)];
    self.navigationItem.leftBarButtonItem = backBarButtonItem;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapView:)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    
    [self.view addSubview:self.scrollView];
    
    [self fetchGroupBans];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - getter

- (UIScrollView *)scrollView
{
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, kContactSize)];
        _scrollView.tag = 0;
        _scrollView.backgroundColor = [UIColor clearColor];
        
        _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        _longPress.minimumPressDuration = 0.5;
        [_scrollView addGestureRecognizer:_longPress];
    }
    
    return _scrollView;
}

#pragma mark - action

- (void)backAction
{
    if (self.isUpdate) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GroupBansChanged" object:nil];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tapView:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateEnded) {
        
        if (self.isEditing) {
        
            [self setScrollViewEditing:NO];
            self.isEditing = NO;
        }
    }
}

- (void)longPressAction:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan)
    {
        if (!self.isEditing) {
            [self setScrollViewEditing:YES];
            self.isEditing = YES;
        }
    }
}

- (void)setScrollViewEditing:(BOOL)isEditing
{
    NSString *loginUsername = [[EMClient sharedClient] currentUsername];
    
    for (ContactView *contactView in self.scrollView.subviews)
    {
        if ([contactView isKindOfClass:[ContactView class]]) {
            if ([contactView.remark isEqualToString:loginUsername]) {
                continue;
            }
            
            [contactView setEditing:isEditing];
        }
    }
}

#pragma mark - other

- (void)refreshScrollView
{
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    //    [self.scrollView removeGestureRecognizer:_longPress];
    
    NSArray *blackList = _group.blackList;
    int tmp = (int)([blackList count] + 1) % kColOfRow;
    int row = (int)([blackList count] + 1) / kColOfRow;
    row += tmp == 0 ? 0 : 1;
    self.scrollView.tag = row;
    self.scrollView.frame = CGRectMake(10, 20, self.view.frame.size.width - 20, row * kContactSize);
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, row * kContactSize);
    
    if ([blackList count] == 0) {
        return;
    }
    
    NSString *loginUsername = [[EMClient sharedClient] currentUsername];
    
    int i = 0;
    int j = 0;
    for (i = 0; i < row; i++) {
        for (j = 0; j < kColOfRow; j++) {
            NSInteger index = i * kColOfRow + j;
            NSArray *blackList = _group.blackList;
            if (index < [blackList count]) {
                NSString *username = [blackList objectAtIndex:index];
                ContactView *contactView = [[ContactView alloc] initWithFrame:CGRectMake(j * kContactSize, i * kContactSize, kContactSize, kContactSize)];
                contactView.index = i * kColOfRow + j;
                contactView.image = [UIImage imageNamed:@"chatListCellHead.png"];
                contactView.remark = username;
                if (![username isEqualToString:loginUsername]) {
                    contactView.editing = _isEditing;
                }
                
                __weak typeof(self) weakSelf = self;
                [contactView setDeleteContact:^(NSInteger index) {
                    weakSelf.isUpdate = YES;
                    [weakSelf showHudInView:weakSelf.view hint:NSLocalizedString(@"group.ban.removing", @"members are removing from the blacklist...")];
                    NSArray *occupants = [NSArray arrayWithObject:[blackList objectAtIndex:index]];
                    [[EMClient sharedClient].groupManager unblockMembers:occupants fromGroup:weakSelf.group.groupId completion:^(EMGroup *aGroup, EMError *aError) {
                        [weakSelf hideHud];
                        if (!aError) {
                            weakSelf.group = aGroup;
                            [weakSelf refreshScrollView];
                        }
                        else {
                            [weakSelf showHint:aError.errorDescription];
                        }
                    }];
                }];
                
                [self.scrollView addSubview:contactView];
            }
        }
    }
}

- (void)fetchGroupBans
{
    __weak typeof(self) weakSelf = self;
    [[EMClient sharedClient].groupManager getGroupBlackListFromServerByID:self.group.groupId completion:^(NSArray *aList, EMError *aError) {
        [weakSelf hideHud];
        if (!aError) {
            [weakSelf refreshScrollView];
        }
        else {
            NSString *errorStr = [NSString stringWithFormat:NSLocalizedString(@"group.ban.fetchFail", @"fail to get blacklist: %@"), aError.errorDescription];
            [weakSelf showHint:errorStr];
        }
    }];
}

@end
