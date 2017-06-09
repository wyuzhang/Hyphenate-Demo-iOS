/************************************************************
 *  * Hyphenate
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 */

#import "EMChatViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import "EMChatToolBar.h"
#import "EMLocationViewController.h"
#import "EMChatBaseCell.h"
#import "EMMessageReadManager.h"
#import "EMCDDeviceManager.h"
#import "EMSDKHelper.h"
#import "EaseCallManager.h"
#import "EMGroupInfoViewController.h"
#import "EMConversationModel.h"
#import "EMMessageModel.h"
#import "EMNotificationNames.h"
#import "EMUserProfileManager.h"

#import "EMChatroomInfoViewController.h"
#import "UIViewController+HUD.h"
#import "NSObject+EMAlertView.h"
#import "EMAlertView.h"

@interface EMChatViewController () <EMChatToolBarDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,EMLocationViewDelegate,EMChatManagerDelegate, EMChatroomManagerDelegate,EMChatBaseCellDelegate,UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet EMChatToolBar *chatToolBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) UIImagePickerController *imagePickerController;

@property (strong, nonatomic) NSMutableArray *dataSource;
@property (strong, nonatomic) UIRefreshControl *refresh;
@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) UIButton *camButton;
@property (strong, nonatomic) UIButton *photoButton;
@property (strong, nonatomic) UIButton *detailButton;
@property (strong, nonatomic) UIButton *deleteButton;
@property (strong, nonatomic) NSIndexPath *longPressIndexPath;

@property (strong, nonatomic) EMConversation *conversation;
@property (strong, nonatomic) EMMessageModel *prevAudioModel;

@end

@implementation EMChatViewController

- (instancetype)initWithConversationId:(NSString*)conversationId conversationType:(EMConversationType)type
{
    self = [super init];
    if (self) {
        _conversation = [[EMClient sharedClient].chatManager getConversation:conversationId type:type createIfNotExist:YES];
        [_conversation markAllMessagesAsRead:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endChatWithConversationId:) name:KEM_END_CHAT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteAllMessages:) name:KNOTIFICATIONNAME_DELETEALLMESSAGE object:nil];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyBoardHidden:)];
    [self.view addGestureRecognizer:tap];
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.tableView addSubview:self.refresh];
    
    self.chatToolBar.delegate = self;
    [self.chatToolBar setupInputTextInfo:self.conversation.ext[@"Draft"]];
    
    [self tableViewDidTriggerHeaderRefresh];
    
    [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
    [[EMClient sharedClient].roomManager addDelegate:self delegateQueue:nil];
    
    [self _setupNavigationBar];
    [self _setupViewLayout];
    
    if (_conversation.type == EMConversationTypeChatRoom) {
        [self _joinChatroom:_conversation.conversationId];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSMutableArray *unreadMessages = [NSMutableArray array];
    for (EMMessageModel *model in self.dataSource) {
        if ([self _shouldSendHasReadAckForMessage:model.message read:NO]) {
            [unreadMessages addObject:model.message];
        }
    }
    if ([unreadMessages count]) {
        [self _sendHasReadResponseForMessages:unreadMessages isRead:YES];
    }
    [_conversation markAllMessagesAsRead:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeGroupsNotification:)
                                                 name:KEM_REMOVEGROUP_NOTIFICATION
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSMutableDictionary *dic = [self.conversation.ext mutableCopy];
    if(!dic) dic = [NSMutableDictionary dictionary];
    dic[@"Draft"] = [self.chatToolBar fetchInputTextInfo];
    self.conversation.ext = dic;
}

- (void)dealloc
{
    // delete the conversation if no message found
    NSString *draft = _conversation.ext[@"Draft"];
    if (_conversation.latestMessage == nil && draft.length == 0) {
        [[EMClient sharedClient].chatManager deleteConversation:_conversation.conversationId isDeleteMessages:YES completion:nil];
    }
    
    [[EMClient sharedClient].chatManager removeDelegate:self];
    [[EMClient sharedClient].roomManager removeDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:KEM_REMOVEGROUP_NOTIFICATION
                                                  object:nil];
}

#pragma mark - Private Layout Views

- (void)_setupNavigationBar
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    
    if (_conversation.type == EMConversationTypeChat) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.deleteButton];
//        self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView:self.photoButton],[[UIBarButtonItem alloc] initWithCustomView:self.camButton]];
        self.title = [[EMUserProfileManager sharedInstance] getNickNameWithUsername:_conversation.conversationId];
    } else if (_conversation.type == EMConversationTypeGroupChat) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.detailButton];
        self.title = [[EMConversationModel alloc] initWithConversation:self.conversation].title;
    } else if (_conversation.type == EMConversationTypeChatRoom) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.detailButton];
    }
}

- (void)_setupViewLayout
{
    self.tableView.width = KScreenWidth;
    self.tableView.height = KScreenHeight - self.chatToolBar.height - 64;
    
    self.chatToolBar.width = KScreenWidth;
    self.chatToolBar.top = KScreenHeight - self.chatToolBar.height - 64;
}

#pragma mark - getter

- (NSString*)conversationId
{
    return _conversation.conversationId;
}

- (UIButton*)backButton
{
    if (_backButton == nil) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backButton.frame = CGRectMake(0, 0, 50, 50);
        _backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_backButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
        [_backButton setImage:[UIImage imageNamed:@"Icon_Back"] forState:UIControlStateNormal];
    }
    return _backButton;
}

- (UIButton *)deleteButton
{
    if (_deleteButton == nil) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteButton.frame = CGRectMake(0, 0, 44, 44);
        _deleteButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_deleteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_deleteButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        [_deleteButton setTitle:@"清空" forState:UIControlStateNormal];
        [_deleteButton setTitle:@"清空" forState:UIControlStateHighlighted];
        [_deleteButton addTarget:self action:@selector(deleteMessages:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

- (UIButton*)camButton
{
    if (_camButton == nil) {
        _camButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _camButton.frame = CGRectMake(0, 0, 25, 12);
        [_camButton setImage:[UIImage imageNamed:@"iconVideo"] forState:UIControlStateNormal];
        [_camButton addTarget:self action:@selector(makeVideoCall) forControlEvents:UIControlEventTouchUpInside];
    }
    return _camButton;
}

- (UIButton*)photoButton
{
    if (_photoButton == nil) {
        _photoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _photoButton.frame = CGRectMake(0, 0, 25, 15);
        [_photoButton setImage:[UIImage imageNamed:@"iconCall"] forState:UIControlStateNormal];
        [_photoButton addTarget:self action:@selector(makeAudioCall) forControlEvents:UIControlEventTouchUpInside];
    }
    return _photoButton;
}

- (UIButton*)detailButton
{
    if (_detailButton == nil) {
        _detailButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _detailButton.frame = CGRectMake(0, 0, 44, 44);
        [_detailButton setImage:[UIImage imageNamed:@"icon_info"] forState:UIControlStateNormal];
        [_detailButton addTarget:self action:@selector(enterDetailView) forControlEvents:UIControlEventTouchUpInside];
    }
    return _detailButton;
}

- (UIImagePickerController *)imagePickerController
{
    if (_imagePickerController == nil) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.modalPresentationStyle= UIModalPresentationOverFullScreen;
        _imagePickerController.allowsEditing = NO;
        _imagePickerController.delegate = self;
    }
    return _imagePickerController;
}

- (NSMutableArray*)dataSource
{
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (UIRefreshControl*)refresh
{
    if (_refresh == nil) {
        _refresh = [[UIRefreshControl alloc] init];
        _refresh.tintColor = [UIColor lightGrayColor];
        [_refresh addTarget:self action:@selector(_loadMoreMessage) forControlEvents:UIControlEventValueChanged];
    }
    return _refresh;
}

#pragma mark - Notification Method

- (void)removeGroupsNotification:(NSNotification *)notification {
    [self.navigationController popToViewController:self animated:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EMMessageModel *model = [self.dataSource objectAtIndex:indexPath.row];
    NSString *CellIdentifier = [EMChatBaseCell cellIdentifierForMessageModel:model];
    EMChatBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[EMChatBaseCell alloc] initWithMessageModel:model];
        cell.delegate = self;
    }
    [cell setMessageModel:model];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EMMessageModel *model = [self.dataSource objectAtIndex:indexPath.row];
    return [EMChatBaseCell heightForMessageModel:model];
}

#pragma mark - EMChatToolBarDelegate

- (void)chatToolBarDidChangeFrameToHeight:(CGFloat)toHeight
{
    [UIView animateWithDuration:0.25 animations:^{
        self.tableView.top = 0.f;
        self.tableView.height = self.view.frame.size.height - toHeight;
    }];
    [self _scrollViewToBottom:NO];
}

- (void)didSendText:(NSString *)text
{
    EMMessage *message = [EMSDKHelper initTextMessage:text
                                                   to:_conversation.conversationId
                                             chatType:[self _messageType]
                                           messageExt:nil];
    [self _sendMessage:message];
}

- (void)didSendAudio:(NSString *)recordPath duration:(NSInteger)duration
{
    EMMessage *message = [EMSDKHelper initVoiceMessageWithLocalPath:recordPath
                                                        displayName:@"audio"
                                                           duration:duration
                                                                 to:_conversation.conversationId
                                                        chatType:[self _messageType]
                                                         messageExt:nil];
    [self _sendMessage:message];
}

- (void)didTakePhotos
{
    [self.chatToolBar endEditing:YES];
#if TARGET_IPHONE_SIMULATOR

#elif TARGET_OS_IPHONE
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
    [self presentViewController:self.imagePickerController animated:YES completion:NULL];
#endif

}

- (void)didSelectPhotos
{
    [self.chatToolBar endEditing:YES];
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self presentViewController:self.imagePickerController animated:YES completion:NULL];
}

- (void)didSelectLocation
{
    [self.chatToolBar endEditing:YES];
    EMLocationViewController *locationViewController = [[EMLocationViewController alloc] init];
    locationViewController.delegate = self;
    [self.navigationController pushViewController:locationViewController animated:YES];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        NSURL *mp4 = [self _convert2Mp4:videoURL];
        NSFileManager *fileman = [NSFileManager defaultManager];
        if ([fileman fileExistsAtPath:videoURL.path]) {
            NSError *error = nil;
            [fileman removeItemAtURL:videoURL error:&error];
            if (error) {
                NSLog(@"failed to remove file, error:%@.", error);
            }
        }
        EMMessage *message = [EMSDKHelper initVideoMessageWithLocalURL:mp4
                                                           displayName:@"video.mp4"
                                                              duration:0
                                                                    to:_conversation.conversationId
                                                              chatType:[self _messageType]
                                                            messageExt:nil];
        [self _sendMessage:message];
        
    }else{
        NSURL *url = info[UIImagePickerControllerReferenceURL];
        if (url == nil) {
            UIImage *orgImage = info[UIImagePickerControllerOriginalImage];
            NSData *data = UIImageJPEGRepresentation(orgImage, 1);
            EMMessage *message = [EMSDKHelper initImageData:data
                                                displayName:@"image.png"
                                                         to:_conversation.conversationId
                                                   chatType:[self _messageType]
                                                 messageExt:nil];
            [self _sendMessage:message];
        } else {
            if ([[UIDevice currentDevice].systemVersion doubleValue] >= 9.0f) {
                PHFetchResult *result = [PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil];
                [result enumerateObjectsUsingBlock:^(PHAsset *asset , NSUInteger idx, BOOL *stop){
                    if (asset) {
                        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData *data, NSString *uti, UIImageOrientation orientation, NSDictionary *dic){
                            if (data.length > 10 * 1000 * 1000) {
                                // Warning - large image size
                            }
                            if (data != nil) {
                                EMMessage *message = [EMSDKHelper initImageData:data
                                                                    displayName:@"image.png"
                                                                             to:_conversation.conversationId
                                                                    chatType:[self _messageType]
                                                                     messageExt:nil];
                                [self _sendMessage:message];
                            } else {
                                // Warning - large image size
                            }
                        }];
                    }
                }];
            } else {
                ALAssetsLibrary *alasset = [[ALAssetsLibrary alloc] init];
                [alasset assetForURL:url resultBlock:^(ALAsset *asset) {
                    if (asset) {
                        ALAssetRepresentation* assetRepresentation = [asset defaultRepresentation];
                        Byte* buffer = (Byte*)malloc((size_t)[assetRepresentation size]);
                        NSUInteger bufferSize = [assetRepresentation getBytes:buffer fromOffset:0.0 length:(NSUInteger)[assetRepresentation size] error:nil];
                        NSData* fileData = [NSData dataWithBytesNoCopy:buffer length:bufferSize freeWhenDone:YES];
                        if (fileData.length > 10 * 1000 * 1000) {
                            // Warning - large image size
                        }
                        EMMessage *message = [EMSDKHelper initImageData:fileData
                                                            displayName:@"image.png"
                                                                     to:_conversation.conversationId
                                                               chatType:[self _messageType]
                                                             messageExt:nil];
                        [self _sendMessage:message];
                    }
                } failureBlock:NULL];
            }
        }
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - EMLocationViewDelegate

- (void)sendLocationLatitude:(double)latitude
                   longitude:(double)longitude
                  andAddress:(NSString *)address
{
    EMMessage *message = [EMSDKHelper initLocationMessageWithLatitude:latitude
                                                            longitude:longitude
                                                              address:address
                                                                   to:_conversation.conversationId
                                                          chatType:[self _messageType]
                                                           messageExt:nil];
    [self _sendMessage:message];
}

#pragma mark - EMChatBaseCellDelegate

- (void)didHeadImagePressed:(EMMessageModel *)model
{
    
}

- (void)didImageCellPressed:(EMMessageModel *)model
{
    if ([self _shouldSendHasReadAckForMessage:model.message read:YES]) {
        [self _sendHasReadResponseForMessages:@[model.message] isRead:YES];
    }
    EMImageMessageBody *body = (EMImageMessageBody*)model.message.body;
    if (model.message.direction == EMMessageDirectionSend && body.localPath.length > 0) {
        UIImage *image = [UIImage imageWithContentsOfFile:body.localPath];
        [[EMMessageReadManager shareInstance] showBrowserWithImages:@[image]];
    } else {
        [[EMMessageReadManager shareInstance] showBrowserWithImages:@[[NSURL URLWithString:body.remotePath]]];
    }
}

- (void)didAudioCellPressed:(EMMessageModel *)model
{
    EMVoiceMessageBody *body = (EMVoiceMessageBody*)model.message.body;
    EMDownloadStatus downloadStatus = [body downloadStatus];
    if (downloadStatus == EMDownloadStatusDownloading) {
        return;
    } else if (downloadStatus == EMDownloadStatusFailed) {
        [[EMClient sharedClient].chatManager downloadMessageAttachment:model.message progress:nil completion:nil];
        return;
    }
    
    if (body.type == EMMessageBodyTypeVoice) {
        if ([self _shouldSendHasReadAckForMessage:model.message read:YES]) {
            [self _sendHasReadResponseForMessages:@[model.message] isRead:YES];
        }
        
        BOOL isPrepare = YES;
        if (_prevAudioModel == nil) {
            _prevAudioModel= model;
            model.isPlaying = YES;
        } else if (_prevAudioModel == model){
            model.isPlaying = NO;
            _prevAudioModel = nil;
            isPrepare = NO;
        } else {
            _prevAudioModel.isPlaying = NO;
            model.isPlaying = YES;
        }
        [self.tableView reloadData];
        
        if (isPrepare) {
            WEAK_SELF
            _prevAudioModel = model;
            [[EMCDDeviceManager sharedInstance] enableProximitySensor];
            [[EMCDDeviceManager sharedInstance] asyncPlayingWithPath:body.localPath completion:^(NSError *error) {
                [weakSelf.tableView reloadData];
                [[EMCDDeviceManager sharedInstance] disableProximitySensor];
                model.isPlaying = NO;
            }];
        }
        else{
            [[EMCDDeviceManager sharedInstance] disableProximitySensor];
//            _isPlayingAudio = NO;
        }
    }
}

- (void)didVideoCellPressed:(EMMessageModel*)model
{
    EMVideoMessageBody *videoBody = (EMVideoMessageBody *)model.message.body;
    if (videoBody.downloadStatus == EMDownloadStatusSuccessed) {
        if ([self _shouldSendHasReadAckForMessage:model.message read:YES]) {
            [self _sendHasReadResponseForMessages:@[model.message] isRead:YES];
        }
        NSURL *videoURL = [NSURL fileURLWithPath:videoBody.localPath];
        MPMoviePlayerViewController *moviePlayerController = [[MPMoviePlayerViewController alloc] initWithContentURL:videoURL];
        [moviePlayerController.moviePlayer prepareToPlay];
        moviePlayerController.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
        [self presentMoviePlayerViewControllerAnimated:moviePlayerController];
    } else {
        [[EMClient sharedClient].chatManager downloadMessageAttachment:model.message progress:nil completion:^(EMMessage *message, EMError *error) {
        }];
    }
}

- (void)didLocationCellPressed:(EMMessageModel*)model
{
    EMLocationMessageBody *body = (EMLocationMessageBody*)model.message.body;
    EMLocationViewController *locationController = [[EMLocationViewController alloc] initWithLocation:CLLocationCoordinate2DMake(body.latitude, body.longitude)];
    [self.navigationController pushViewController:locationController animated:YES];
}

- (void)didCellLongPressed:(EMChatBaseCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    EMMessageModel *model = [self.dataSource objectAtIndex:indexPath.row];
    if (model.message.body.type == EMMessageBodyTypeText) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"chat.cancel", @"Cancel")
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:NSLocalizedString(@"chat.copy", @"Copy"),NSLocalizedString(@"chat.delete", @"Delete"), nil];
        sheet.tag = 1000;
        [sheet showInView:self.view];
        _longPressIndexPath = indexPath;
    } else {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"chat.cancel", @"Cancel")
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:NSLocalizedString(@"chat.delete", @"Delete"), nil];
        sheet.tag = 1001;
        [sheet showInView:self.view];
        _longPressIndexPath = indexPath;
    }
}

- (void)didResendButtonPressed:(EMMessageModel*)model
{
    WEAK_SELF
    [self.tableView reloadData];
    [[EMClient sharedClient].chatManager resendMessage:model.message progress:nil completion:^(EMMessage *message, EMError *error) {
        NSLog(@"%@",error.errorDescription);
        [weakSelf.tableView reloadData];
    }];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 1000) {
        if (buttonIndex == 0) {
            if (_longPressIndexPath && _longPressIndexPath.row > 0) {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                if (_longPressIndexPath.row > 0) {
                    EMMessageModel *model = [self.dataSource objectAtIndex:_longPressIndexPath.row];
                    if (model.message.body.type == EMMessageBodyTypeText) {
                        EMTextMessageBody *body = (EMTextMessageBody*)model.message.body;
                        pasteboard.string = body.text;
                    }
                }
                _longPressIndexPath = nil;
            }
        } else if (buttonIndex == 1){
            if (_longPressIndexPath && _longPressIndexPath.row >= 0) {
                EMMessageModel *model = [self.dataSource objectAtIndex:_longPressIndexPath.row];
                NSMutableIndexSet *indexs = [NSMutableIndexSet indexSetWithIndex:_longPressIndexPath.row];
                [self.conversation deleteMessageWithId:model.message.messageId error:nil];
                NSMutableArray *indexPaths = [NSMutableArray arrayWithObjects:_longPressIndexPath, nil];;
                if (_longPressIndexPath.row - 1 >= 0) {
                    id nextMessage = nil;
                    id prevMessage = [self.dataSource objectAtIndex:(_longPressIndexPath.row - 1)];
                    if (_longPressIndexPath.row + 1 < [self.dataSource count]) {
                        nextMessage = [self.dataSource objectAtIndex:(_longPressIndexPath.row + 1)];
                    }
                    if ((!nextMessage || [nextMessage isKindOfClass:[NSString class]]) && [prevMessage isKindOfClass:[NSString class]]) {
                        [indexs addIndex:_longPressIndexPath.row - 1];
                        [indexPaths addObject:[NSIndexPath indexPathForRow:(_longPressIndexPath.row - 1) inSection:0]];
                    }
                }
                [self.dataSource removeObjectsAtIndexes:indexs];
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            }
            _longPressIndexPath = nil;
        }
    } else if (actionSheet.tag == 1001) {
        if (buttonIndex == 0){
            if (_longPressIndexPath && _longPressIndexPath.row > 0) {
                EMMessageModel *model = [self.dataSource objectAtIndex:_longPressIndexPath.row];
                NSMutableIndexSet *indexs = [NSMutableIndexSet indexSetWithIndex:_longPressIndexPath.row];
                [self.conversation deleteMessageWithId:model.message.messageId error:nil];
                NSMutableArray *indexPaths = [NSMutableArray arrayWithObjects:_longPressIndexPath, nil];;
                if (_longPressIndexPath.row - 1 >= 0) {
                    id nextMessage = nil;
                    id prevMessage = [self.dataSource objectAtIndex:(_longPressIndexPath.row - 1)];
                    if (_longPressIndexPath.row + 1 < [self.dataSource count]) {
                        nextMessage = [self.dataSource objectAtIndex:(_longPressIndexPath.row + 1)];
                    }
                    if ((!nextMessage || [nextMessage isKindOfClass:[NSString class]]) && [prevMessage isKindOfClass:[NSString class]]) {
                        [indexs addIndex:_longPressIndexPath.row - 1];
                        [indexPaths addObject:[NSIndexPath indexPathForRow:(_longPressIndexPath.row - 1) inSection:0]];
                    }
                }
                [self.dataSource removeObjectsAtIndexes:indexs];
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            }
            _longPressIndexPath = nil;
        }
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
    _longPressIndexPath = nil;
}

#pragma mark - action

- (void)tableViewDidTriggerHeaderRefresh
{
    WEAK_SELF
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_conversation loadMessagesStartFromId:nil
                                         count:20
                               searchDirection:EMMessageSearchDirectionUp
                                    completion:^(NSArray *aMessages, EMError *aError) {
                                        if (!aError) {
                                            [weakSelf.dataSource removeAllObjects];
                                            for (EMMessage * message in aMessages) {
                                                [weakSelf _addMessageToDataSource:message];
                                            }
                                            [weakSelf.refresh endRefreshing];
                                            [weakSelf.tableView reloadData];
                                            [weakSelf _scrollViewToBottom:NO];
                                        }
                                    }];
    });
}

- (void)makeVideoCall
{
    [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_CALL object:@{@"chatter":self.conversation.conversationId, @"type":[NSNumber numberWithInt:1]}];
}

- (void)makeAudioCall
{
    [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_CALL object:@{@"chatter":self.conversation.conversationId, @"type":[NSNumber numberWithInt:0]}];
}

- (void)enterDetailView
{
    if (_conversation.type == EMConversationTypeGroupChat) {
        EMGroupInfoViewController *groupInfoViewController = [[EMGroupInfoViewController alloc] initWithGroupId:_conversation.conversationId];
        [self.navigationController pushViewController:groupInfoViewController animated:YES];
    } else if (_conversation.type == EMConversationTypeChatRoom) {
        EMChatroomInfoViewController *infoController = [[EMChatroomInfoViewController alloc] initWithChatroomId:self.conversation.conversationId];
        [self.navigationController pushViewController:infoController animated:YES];
    }
}

- (void)deleteMessages:(id)sender {
    WEAK_SELF
    [EMAlertView showAlertWithTitle:NSLocalizedString(@"button.prompt", @"Prompt")
                            message:NSLocalizedString(@"chat.clearMsg", @"Do you want to delete all messages?")
                    completionBlock:^(NSUInteger buttonIndex, EMAlertView *alertView) {
                        if (buttonIndex == 1) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATIONNAME_DELETEALLMESSAGE object:weakSelf.conversationId];
                        }
                    } cancelButtonTitle:NSLocalizedString(@"button.cancel", @"Cancel")
                  otherButtonTitles:NSLocalizedString(@"button.ok", @"OK"), nil];
}

- (void)backAction
{
    if (_conversation.type == EMConversationTypeChatRoom) {
        [self showHudInView:[UIApplication sharedApplication].keyWindow hint:NSLocalizedString(@"chatroom.leaving", @"Leaving the chatroom...")];
        WEAK_SELF
        [[EMClient sharedClient].roomManager leaveChatroom:_conversation.conversationId completion:^(EMError *aError) {
            [weakSelf hideHud];
            if (aError) {
                [self showAlertWithMessage:[NSString stringWithFormat:@"Leave chatroom '%@' failed [%@]", weakSelf.conversation.conversationId, aError.errorDescription] ];
            }
            [weakSelf.navigationController popToViewController:self animated:YES];
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }];
    } else {
        [self.navigationController popToViewController:self animated:YES];
        [self.navigationController popViewControllerAnimated:YES];
    }
}




- (void)deleteAllMessages:(id)sender
{
    if (self.dataSource.count == 0) {
        return;
    }
    
    if ([sender isKindOfClass:[NSNotification class]]) {
        NSString *groupId = (NSString *)[(NSNotification *)sender object];
        BOOL isDelete = [groupId isEqualToString:self.conversation.conversationId];
        if (isDelete) {
            [self.conversation deleteAllMessages:nil];
            [self.dataSource removeAllObjects];
            
            [self.tableView reloadData];
        }
    }
}

- (void)endChatWithConversationId:(NSNotification *)aNotification
{
    id obj = aNotification.object;
    if ([obj isKindOfClass:[NSString class]]) {
        NSString *conversationId = (NSString *)obj;
        if ([conversationId length] > 0 && [conversationId isEqualToString:self.conversationId]) {
            [self backAction];
        }
    } else if ([obj isKindOfClass:[EMChatroom class]] && self.conversation.type == EMConversationTypeChatRoom) {
        EMChatroom *chatroom = (EMChatroom *)obj;
        if ([chatroom.chatroomId isEqualToString:self.conversationId]) {
            [self.navigationController popToViewController:self animated:YES];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

#pragma mark - GestureRecognizer

- (void)keyBoardHidden:(UITapGestureRecognizer *)tapRecognizer
{
    if (tapRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.chatToolBar endEditing:YES];
    }
}

#pragma mark - private

- (void)_joinChatroom:(NSString *)aChatroomId
{
    __weak typeof(self) weakSelf = self;
    [self showHudInView:self.view hint:NSLocalizedString(@"chatroom.joining", @"Joining the chatroom")];
    [[EMClient sharedClient].roomManager joinChatroom:aChatroomId completion:^(EMChatroom *aChatroom, EMError *aError) {
        [self hideHud];
        if (aError) {
            if (aError.code == EMErrorChatroomAlreadyJoined) {
                [[EMClient sharedClient].roomManager leaveChatroom:aChatroomId completion:nil];
            }
            
            [weakSelf showAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"chatroom.joinFailed",@"join chatroom \'%@\' failed"), aChatroomId]];
            [weakSelf backAction];
        } else {
            NSMutableDictionary *ext = [NSMutableDictionary dictionaryWithDictionary:weakSelf.conversation.ext];
            [ext setObject:aChatroom.subject forKey:@"subject"];
            weakSelf.conversation.ext = ext;
            weakSelf.title = aChatroom.subject;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:KEM_UPDATE_CONVERSATIONS object:nil];
        }
    }];
}

- (void)_sendMessage:(EMMessage*)message
{
    [self _addMessageToDataSource:message];
    [self.tableView reloadData];
    WEAK_SELF
    [[EMClient sharedClient].chatManager sendMessage:message progress:nil completion:^(EMMessage *message, EMError *error) {
        [weakSelf.tableView reloadData];
    }];
    [self _scrollViewToBottom:YES];
}

- (void)_addMessageToDataSource:(EMMessage*)message
{
    EMMessageModel *model = [[EMMessageModel alloc] initWithMessage:message];
    [self.dataSource addObject:model];
}

- (void)_scrollViewToBottom:(BOOL)animated
{
    if (self.tableView.contentSize.height > self.tableView.frame.size.height) {
        CGPoint offset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
        [self.tableView setContentOffset:offset animated:animated];
    }
}

- (void)_loadMoreMessage
{
    WEAK_SELF
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *messageId = nil;
        if ([weakSelf.dataSource count] > 0) {
            EMMessageModel *model = [weakSelf.dataSource objectAtIndex:0];
            messageId = model.message.messageId;
        }
        [_conversation loadMessagesStartFromId:messageId
                                         count:20
                               searchDirection:EMMessageSearchDirectionUp
                                    completion:^(NSArray *aMessages, EMError *aError) {
                                        if (!aError) {
                                            [aMessages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                                EMMessageModel *model = [[EMMessageModel alloc] initWithMessage:(EMMessage*)obj];
                                                [weakSelf.dataSource insertObject:model atIndex:0];
                                            }];
                                            [weakSelf.refresh endRefreshing];
                                            [weakSelf.tableView reloadData];
                                        }
                                    }];
    });
}

- (NSURL *)_convert2Mp4:(NSURL *)movUrl
{
    NSURL *mp4Url = nil;
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:movUrl options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset
                                                                              presetName:AVAssetExportPresetHighestQuality];
        NSString *dataPath = [NSString stringWithFormat:@"%@/Library/appdata/chatbuffer", NSHomeDirectory()];
        NSFileManager *fm = [NSFileManager defaultManager];
        if(![fm fileExistsAtPath:dataPath]){
            [fm createDirectoryAtPath:dataPath
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
        }
        NSString *mp4Path = [NSString stringWithFormat:@"%@/%d%d.mp4", dataPath, (int)[[NSDate date] timeIntervalSince1970], arc4random() % 100000];
        mp4Url = [NSURL fileURLWithPath:mp4Path];
        exportSession.outputURL = mp4Url;
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.outputFileType = AVFileTypeMPEG4;
        dispatch_semaphore_t wait = dispatch_semaphore_create(0l);
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed: {
                    NSLog(@"failed, error:%@.", exportSession.error);
                } break;
                case AVAssetExportSessionStatusCancelled: {
                    NSLog(@"cancelled.");
                } break;
                case AVAssetExportSessionStatusCompleted: {
                    NSLog(@"completed.");
                } break;
                default: {
                    NSLog(@"others.");
                } break;
            }
            dispatch_semaphore_signal(wait);
        }];
        long timeout = dispatch_semaphore_wait(wait, DISPATCH_TIME_FOREVER);
        if (timeout) {
            NSLog(@"timeout.");
        }
        if (wait) {
            wait = nil;
        }
    }
    
    return mp4Url;
}

- (void)_sendHasReadResponseForMessages:(NSArray*)messages
                                 isRead:(BOOL)isRead
{
    NSMutableArray *unreadMessages = [NSMutableArray array];
    for (NSInteger i = 0; i < [messages count]; i++)
    {
        EMMessage *message = messages[i];
        BOOL isSend = [self _shouldSendHasReadAckForMessage:message
                                                      read:isRead];
        if (isSend) {
            [unreadMessages addObject:message];
        }
    }
    if ([unreadMessages count]) {
        for (EMMessage *message in unreadMessages) {
            [[EMClient sharedClient].chatManager sendMessageReadAck:message completion:nil];
        }
    }
}

- (BOOL)_shouldSendHasReadAckForMessage:(EMMessage *)message
                                  read:(BOOL)read
{
    NSString *account = [[EMClient sharedClient] currentUsername];
    if (message.chatType != EMChatTypeChat || message.isReadAcked || [account isEqualToString:message.from] || ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)) {
        return NO;
    }
    
    EMMessageBody *body = message.body;
    if (((body.type == EMMessageBodyTypeVideo) ||
         (body.type == EMMessageBodyTypeVoice) ||
         (body.type == EMMessageBodyTypeImage)) &&
        !read) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)_shouldMarkMessageAsRead
{
    BOOL isMark = YES;
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        isMark = NO;
    }
    return isMark;
}

- (EMChatType)_messageType
{
    EMChatType type = EMChatTypeChat;
    switch (_conversation.type) {
        case EMConversationTypeChat:
            type = EMChatTypeChat;
            break;
        case EMConversationTypeGroupChat:
            type = EMChatTypeGroupChat;
            break;
        case EMConversationTypeChatRoom:
            type = EMChatTypeChatRoom;
            break;
        default:
            break;
    }
    return type;
}

#pragma mark - EMChatManagerDelegate

- (void)messagesDidReceive:(NSArray *)aMessages
{
    for (EMMessage *message in aMessages) {
        if ([self.conversation.conversationId isEqualToString:message.conversationId]) {
            [self _addMessageToDataSource:message];
            [self _sendHasReadResponseForMessages:@[message]
                                           isRead:NO];
            if ([self _shouldMarkMessageAsRead]) {
                [self.conversation markMessageAsReadWithId:message.messageId error:nil];
            }
        }
    }
    [self.tableView reloadData];
    [self _scrollViewToBottom:YES];
}

- (void)messageAttachmentStatusDidChange:(EMMessage *)aMessage
                                   error:(EMError *)aError
{
    if ([self.conversation.conversationId isEqualToString:aMessage.conversationId]) {
        [self.tableView reloadData];
    }
}

- (void)messagesDidRead:(NSArray *)aMessages
{
    for (EMMessage *message in aMessages) {
        if ([self.conversation.conversationId isEqualToString:message.conversationId]) {
            [self.tableView reloadData];
            break;
        }
    }
}

#pragma mark - EMChatManagerChatroomDelegate

- (void)userDidJoinChatroom:(EMChatroom *)aChatroom
                       user:(NSString *)aUsername
{
    [self showHint:[NSString stringWithFormat:NSLocalizedString(@"chatroom.join", @"\'%@\'join chatroom\'%@\'"), aUsername, aChatroom.chatroomId]];
}

- (void)userDidLeaveChatroom:(EMChatroom *)aChatroom
                        user:(NSString *)aUsername
{
    [self showHint:[NSString stringWithFormat:NSLocalizedString(@"chatroom.leave.hint", @"\'%@\'leave chatroom\'%@\'"), aUsername, aChatroom.chatroomId]];
}

- (void)didDismissFromChatroom:(EMChatroom *)aChatroom
                        reason:(EMChatroomBeKickedReason)aReason
{
    if ([_conversation.conversationId isEqualToString:aChatroom.chatroomId])
    {
        [self showHint:[NSString stringWithFormat:NSLocalizedString(@"chatroom.remove", @"be removed from chatroom\'%@\'"), aChatroom.chatroomId]];
        [self.navigationController popToViewController:self animated:NO];
        [self.navigationController popViewControllerAnimated:YES];
    }
}


@end
