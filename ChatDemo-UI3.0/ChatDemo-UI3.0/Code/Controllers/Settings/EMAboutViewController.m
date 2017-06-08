/************************************************************
 *  * Hyphenate
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 */

#import "EMAboutViewController.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "UIViewController+HUD.h"

@interface EMAboutViewController ()<MFMailComposeViewControllerDelegate>
;
@property (nonatomic, strong) NSString *logPath;

@end

@implementation EMAboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configBackButton];
}


#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIndetifier = @"aboutCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndetifier];
    if (!cell) {

        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIndetifier];
    }
    if (indexPath.row == 0) {
        
        cell.textLabel.text = NSLocalizedString(@"setting.about.appversion", @"App Version");
        cell.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"setting.emailLog", @"Email send logs");
//        cell.textLabel.text = NSLocalizedString(@"setting.about.sdkversion", @"SDK Version");
//        cell.detailTextLabel.text = [[EMClient sharedClient] version];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 1) {
        if ([MFMailComposeViewController canSendMail] == false) {
            return;
        }
        
        EMError *error = nil;
        [self showHudInView:self.view hint:NSLocalizedString(@"log.fetchPath", @"Fetch the compressed package path")];
        __weak typeof(self) weakSelf = self;
        [[EMClient sharedClient] getLogFilesPathWithCompletion:^(NSString *aPath, EMError *aError) {
            __strong EMAboutViewController *strongSelf = weakSelf;
            [strongSelf hideHud];
            
            if (error == nil) {
                strongSelf.logPath = aPath;
                MFMailComposeViewController *mailCompose = [[MFMailComposeViewController alloc] init];
                if(mailCompose) {
                    //设置代理
                    [mailCompose setMailComposeDelegate:strongSelf];
                    
                    //设置收件人
                    //                    NSArray *toAddress = [NSArray arrayWithObject:@""];
                    //                    [mailCompose setToRecipients:toAddress];
                    
                    //设置邮件主题
                    [mailCompose setSubject:NSLocalizedString(@"log.thisLog", @"This is the log")];
                    //设置邮件内容
                    NSString *emailBody = NSLocalizedString(@"log.sendLog", @"send the log");
                    [mailCompose setMessageBody:emailBody isHTML:NO];
                    
                    //设置邮件附件{mimeType:文件格式|fileName:文件名}
                    NSData* pData = [[NSData alloc]initWithContentsOfFile:aPath];
                    [mailCompose addAttachmentData:pData mimeType:@"" fileName:@"log.gz"];
                    
                    //设置邮件视图在当前视图上显示方式
                    [strongSelf presentViewController:mailCompose animated:YES completion:nil];
                }
            }
        }];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(nullable NSError *)error
{
    NSString *msg = @"";
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
            msg = NSLocalizedString(@"log.cancel", @"Mail canceled");
            break;
        case MFMailComposeResultSaved:
            msg = NSLocalizedString(@"log.saveSuccessfuuly", @"Mail save successfully");
            break;
        case MFMailComposeResultSent:
            msg = NSLocalizedString(@"log.sendSuccessfully", @"Mail send successfully");
            break;
        case MFMailComposeResultFailed:
            msg = NSLocalizedString(@"log.sendFailure", @"Mail send failure");
            break;
        default:
            break;
    }
    
    
    if ([msg length] > 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:self.logPath error:nil];
    self.logPath = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
