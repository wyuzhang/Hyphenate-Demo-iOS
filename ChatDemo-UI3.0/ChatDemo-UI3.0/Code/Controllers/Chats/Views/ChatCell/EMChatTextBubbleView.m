/************************************************************
 *  * Hyphenate
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 */

#import "EMChatTextBubbleView.h"

#import "EMConvertToCommonEmoticonsHelper.h"
#import "EMMessageModel.h"

#define LABEL_FONT_SIZE 13.f
#define BUBBLE_VIEW_PADDING 12.f
#define TEXTLABEL_MAX_WIDTH 200
#define LABEL_LINESPACE 4.f

@interface EMChatTextBubbleView ()

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation EMChatTextBubbleView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _textLabel.numberOfLines = 0;
        _textLabel.lineBreakMode = NSLineBreakByCharWrapping;
        _textLabel.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
        _textLabel.textColor = AlmostBlackColor;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.userInteractionEnabled = NO;
        _textLabel.multipleTouchEnabled = NO;
        [self addSubview:_textLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.bounds;
    frame = CGRectInset(frame, BUBBLE_VIEW_PADDING, BUBBLE_VIEW_PADDING);
    frame.origin.x = BUBBLE_VIEW_PADDING;
    frame.origin.y = BUBBLE_VIEW_PADDING;
    [self.textLabel setFrame:frame];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize textBlockMinSize = {TEXTLABEL_MAX_WIDTH, CGFLOAT_MAX};
    CGSize retSize;
    EMMessageBody *body = self.model.message.body;
    NSString *text = @"";
    if ([body isKindOfClass:[EMTextMessageBody class]]) {
        text = [EMConvertToCommonEmoticonsHelper convertToSystemEmoticons:((EMTextMessageBody *)self.model.message.body).text];
    }
    else if ([body isKindOfClass:[EMFileMessageBody class]]) {
        text = [NSString stringWithFormat:@"(文件)%@",[(EMFileMessageBody *)body displayName]];
    }
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:[[self class] lineSpacing]];
    retSize = [text boundingRectWithSize:textBlockMinSize options:NSStringDrawingUsesLineFragmentOrigin
                              attributes:@{
                                           NSFontAttributeName:[[self class] textLabelFont],
                                           NSParagraphStyleAttributeName:paragraphStyle
                                           }
                                 context:nil].size;
    
    CGFloat height = 2*BUBBLE_VIEW_PADDING + retSize.height;
//    if (2*BUBBLE_VIEW_PADDING + retSize.height > height) {
//        height = 2*BUBBLE_VIEW_PADDING + retSize.height;
//    }
    
    return CGSizeMake(retSize.width + BUBBLE_VIEW_PADDING * 2, height);
}

#pragma mark - setter

- (void)setModel:(EMMessageModel *)model
{
    [super setModel:model];
    EMMessageBody *body = self.model.message.body;
    NSString *text = @"";
    if ([body isKindOfClass:[EMTextMessageBody class]]) {
        text = [EMConvertToCommonEmoticonsHelper convertToSystemEmoticons:((EMTextMessageBody *)self.model.message.body).text];
    }
    else if ([body isKindOfClass:[EMFileMessageBody class]]) {
        text = [NSString stringWithFormat:@"(文件)%@",[(EMFileMessageBody *)body displayName]];
    }
    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc]
                                                    initWithString:text];
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:[[self class] lineSpacing]];
    [attributedString addAttribute:NSParagraphStyleAttributeName
                             value:paragraphStyle
                             range:NSMakeRange(0, [text length])];
    _textLabel.textColor = self.model.message.direction == EMMessageDirectionSend ? WhiteColor : AlmostBlackColor;
    [_textLabel setAttributedText:attributedString];
}

+ (CGFloat)heightForBubbleWithMessageModel:(EMMessageModel *)model
{
    CGSize textBlockMinSize = {TEXTLABEL_MAX_WIDTH, CGFLOAT_MAX};
    CGSize size;
    static float systemVersion;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    });
    NSString *text = [EMConvertToCommonEmoticonsHelper convertToSystemEmoticons:((EMTextMessageBody *)model.message.body).text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:[[self class] lineSpacing]];
    size = [text boundingRectWithSize:textBlockMinSize options:NSStringDrawingUsesLineFragmentOrigin
                           attributes:@{
                                        NSFontAttributeName:[[self class] textLabelFont],
                                        NSParagraphStyleAttributeName:paragraphStyle
                                        }
                              context:nil].size;
    return 2 * BUBBLE_VIEW_PADDING + size.height;
}

+(UIFont *)textLabelFont
{
    return [UIFont systemFontOfSize:LABEL_FONT_SIZE];
}

+(CGFloat)lineSpacing{
    return LABEL_LINESPACE;
}

+(NSLineBreakMode)textLabelLineBreakModel
{
    return NSLineBreakByCharWrapping;
}

@end
