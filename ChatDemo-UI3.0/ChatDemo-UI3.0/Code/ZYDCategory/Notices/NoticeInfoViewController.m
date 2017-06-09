//
//  NoticeInfoViewController.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 27/02/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "NoticeInfoViewController.h"
#import <Hyphenate/Hyphenate.h>
#import "SDImageCache.h"
#define SIZE CGSizeMake([UIScreen mainScreen].applicationFrame.size.width,270)
#define PADDING 20

@interface NoticeInfoViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) EMMessage *msg;
@end

@implementation NoticeInfoViewController

- (instancetype)initWithMessage:(EMMessage *)aMessage {
    if (self = [super init]) {
        self.msg = aMessage;
    }
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    EMTextMessageBody *textBody = (EMTextMessageBody *)self.msg.body;
    self.title = @"公告详情";
    self.msg.isRead = YES;
    id info = nil;
    NSDictionary *dic = self.msg.ext;
    if(dic){
        info = dic.allValues.firstObject;
    }
    
    int y = 10;
    
    UILabel *titlelabel = [[UILabel alloc] init];
    titlelabel.font = [UIFont systemFontOfSize:20 weight:3];
    titlelabel.text = [NSString stringWithFormat:@"%@\n",textBody.text];
    titlelabel.numberOfLines = 0;
    CGRect frame = titlelabel.frame;
    
    frame.origin.y = y;
    frame.origin.x = PADDING;
    frame.size.width = SIZE.width - 2 * PADDING;
    titlelabel.frame = frame;
    [titlelabel sizeToFit];
    [self.scrollView addSubview:titlelabel];
    y += titlelabel.frame.size.height;

    
    if (info && [info isKindOfClass:[NSArray class]]) {
        NSArray *ary = (NSArray *)info;
        for (NSDictionary *infoDic in ary) {
            y += 5;
            if (infoDic[@"img"]) {
                UIImageView *img = [[UIImageView alloc] initWithFrame:CGRectMake(PADDING, y, SIZE.width - PADDING * 2, SIZE.height)];
                [img sd_setImageWithURL:[NSURL URLWithString:infoDic[@"img"]] placeholderImage:nil];
                [self.scrollView addSubview:img];
                y +=  img.frame.size.height;
            }
            
            if (infoDic[@"txt"]) {
                UILabel *label = [[UILabel alloc] init];
                label.text = infoDic[@"txt"];
                label.numberOfLines = 0;
                CGRect frame = label.frame;
                
                frame.origin.y = y;
                frame.origin.x = PADDING;
                frame.size.width = SIZE.width - 2 * PADDING;
                label.frame = frame;
                [label sizeToFit];
                [self.scrollView addSubview:label];
                y += label.frame.size.height;
            }
        }
    }
    
    self.scrollView.contentSize = CGSizeMake(SIZE.width, y + 10);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setupUnreadMessageCount" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
