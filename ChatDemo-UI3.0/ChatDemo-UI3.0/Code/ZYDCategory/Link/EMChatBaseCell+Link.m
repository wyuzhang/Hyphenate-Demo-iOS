//
//  EaseMessageCell+Link.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/16.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "EMChatBaseCell+Link.h"
#import <objc/runtime.h>
#import <CoreText/CoreText.h>
#import "EMChatTextBubbleView.h"
#import "EMMessageModel.h"

static char matchsKey;
static char textContentKey;

@interface EMChatBaseCell()

@property (nonatomic, strong) NSMutableArray *matchs;

@property (nonatomic, copy) NSString *textContent;

@end

@implementation EMChatBaseCell (Link)

+ (void)load {
    Method oldSetMethod = class_getInstanceMethod([EMChatBaseCell class], @selector(setMessageModel:));
    Method newSetMethod = class_getInstanceMethod([EMChatBaseCell class], @selector(linkSetMessageModel:));
    method_exchangeImplementations(oldSetMethod, newSetMethod);
    
    Method oldInitMethod = class_getInstanceMethod([EMChatBaseCell class], @selector(initWithMessageModel:));
    Method newInitMethod = class_getInstanceMethod([EMChatBaseCell class], @selector(linkInitWithMessageModel:));
    method_exchangeImplementations(oldInitMethod, newInitMethod);
    
    Method oldTapMethod = class_getInstanceMethod([EMChatBaseCell class], @selector(didBubbleViewPressed:));
    Method newTapMethod = class_getInstanceMethod([EMChatBaseCell class], @selector(linkDidBubbleViewPressed:));
    method_exchangeImplementations(oldTapMethod, newTapMethod);
}


#pragma mark - getter

- (NSMutableArray *)matchs {
    return objc_getAssociatedObject(self, &matchsKey);
}

- (NSString *)textContent {
    return objc_getAssociatedObject(self, &textContentKey);
}

#pragma mark - setter

- (void)setMatchs:(NSMutableArray *)matchs {
    objc_setAssociatedObject(self, &matchsKey, matchs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setTextContent:(NSString *)textContent {
    objc_setAssociatedObject(self, &textContentKey, textContent, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - private

- (UILabel *)textLabel {
    EMChatTextBubbleView *_bubbleView = (EMChatTextBubbleView *)[self _bubbleView];
    UILabel *_textLabel = [_bubbleView valueForKey:@"textLabel"];
    return _textLabel;
}

- (void)setTextLabel:(UILabel *)label {
    [[self _bubbleView] setValue:label forKey:@"textLabel"];
}

- (EMChatBaseBubbleView *)_bubbleView {
    EMChatBaseBubbleView *bubbleView = [self valueForKey:@"bubbleView"];
    return bubbleView;
}


- (instancetype)linkInitWithMessageModel:(EMMessageModel*)model;
{
    EMChatBaseCell *cell = [self linkInitWithMessageModel:model];
    
    if (cell && model.message.body.type == EMMessageBodyTypeText) {
        cell.matchs = [NSMutableArray array];
    }
    return cell;
}


- (void)linkSetMessageModel:(EMMessageModel *)model {
    [self linkSetMessageModel:model];
    if (model.message.body.type == EMMessageBodyTypeText) {
        
        EMTextMessageBody *body = (EMTextMessageBody *)model.message.body;
        self.textContent = body.text;
        
        self.matchs = [NSMutableArray arrayWithArray:[self regularExpression]];
        if (self.matchs.count > 0) {
            [self highlightLinksWithMatchs];
        }
    }
}

- (NSArray *)regularExpression {
    NSString *regular = @"((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
    
    NSString *linkString = self.textContent;
    if (linkString.length == 0) {
        return nil;
    }
    NSRegularExpression *exp = [NSRegularExpression regularExpressionWithPattern:regular options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *match = [exp matchesInString:linkString options:NSMatchingReportProgress range:NSMakeRange(0, linkString.length)];
    
    NSMutableArray *results = [NSMutableArray array];
    
    for (NSTextCheckingResult *result in match) {
        NSString *str = [linkString substringWithRange:result.range];
        NSURL *url = [NSURL URLWithString:str];
        //为不包含http/https的url添加前缀http
        if ([str rangeOfString:@"http"].location == NSNotFound &&
            [str rangeOfString:@"https"].location == NSNotFound) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",str]];
        }
        [results addObject:[NSTextCheckingResult linkCheckingResultWithRange:result.range URL:url]];
    }
    return results;
}

//加下划线
- (void)highlightLinksWithMatchs {
    
    UILabel *_textLabel = [self textLabel];
    NSMutableAttributedString* attributedString = [_textLabel.attributedText mutableCopy];
    
    for (NSTextCheckingResult *match in self.matchs) {
        
        if ([match resultType] == NSTextCheckingTypeLink) {
            NSRange matchRange = [match range];
            [attributedString addAttribute:NSForegroundColorAttributeName value:_textLabel.textColor range:matchRange];
            [attributedString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:matchRange];
        }
    }
    _textLabel.attributedText = attributedString;
    [self setTextLabel:_textLabel];
}

- (BOOL)isIndex:(CFIndex)index inRange:(NSRange)range
{
    return index >= range.location && index < range.location+range.length;
}


#pragma mark - action

/*!
 @method
 @brief 气泡的点击手势事件
 @discussion
 @result
 */
- (void)linkDidBubbleViewPressed:(EMMessageModel *)model {
    EMMessageModel *_model = (EMMessageModel *)[self valueForKey:@"model"];
    [self linkDidBubbleViewPressed:model];
    if (_model.message.body.type == EMMessageBodyTypeText && self.matchs.count > 0) {
        UILabel *_textLabel = [self textLabel];
        
        __block UITapGestureRecognizer *tapG = nil;
        [[self _bubbleView].gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UITapGestureRecognizer class]]) {
                tapG = (UITapGestureRecognizer *)obj;
                *stop = YES;
            }
        }];
        if (tapG) {
            CGPoint point = [tapG locationInView:_textLabel];
            CFIndex charIndex = [self characterIndexAtPoint:point];
            for (NSTextCheckingResult *match in self.matchs) {
                if ([match resultType] == NSTextCheckingTypeLink) {
                    NSRange matchRange = [match range];
                    if ([self isIndex:charIndex inRange:matchRange]) {
                        [[UIApplication sharedApplication] openURL:match.URL];
                        break;
                    }
                }
            }
        }
    }
}


- (CFIndex)characterIndexAtPoint:(CGPoint)point
{
    UILabel *_textLabel = [self textLabel];
    NSMutableAttributedString* optimizedAttributedText = [_textLabel.attributedText mutableCopy];
    
    // use label's font and lineBreakMode properties in case the attributedText does not contain such attributes
    [_textLabel.attributedText enumerateAttributesInRange:NSMakeRange(0, [_textLabel.attributedText length]) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        
        if (!attrs[(NSString*)kCTFontAttributeName])
        {
            [optimizedAttributedText addAttribute:(NSString*)kCTFontAttributeName value:_textLabel.font range:NSMakeRange(0, [_textLabel.attributedText length])];
        }
    }];
    
    if (!CGRectContainsPoint(_textLabel.bounds, point)) {
        return NSNotFound;
    }
    
    CGRect textRect = _textLabel.frame;
    
    if (!CGRectContainsPoint(textRect, point)) {
        return NSNotFound;
    }
    
    // Offset tap coordinates by textRect origin to make them relative to the origin of frame
    point = CGPointMake(point.x - textRect.origin.x, point.y - textRect.origin.y);
    // Convert tap coordinates (start at top left) to CT coordinates (start at bottom left)
    point = CGPointMake(point.x, textRect.size.height - point.y);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)optimizedAttributedText);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, textRect);
    
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [_textLabel.attributedText length]), path, NULL);
    
    if (frame == NULL) {
        CFRelease(path);
        return NSNotFound;
    }
    
    CFArrayRef lines = CTFrameGetLines(frame);
    
    NSInteger numberOfLines = _textLabel.numberOfLines > 0 ? MIN(_textLabel.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    
    //NSLog(@"num lines: %d", numberOfLines);
    
    if (numberOfLines == 0) {
        CFRelease(frame);
        CFRelease(path);
        return NSNotFound;
    }
    NSUInteger idx = NSNotFound;
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);
    
    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
        
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        // Get bounding information of line
        CGFloat ascent, descent, leading, width;
        width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        CGFloat yMin = floor(lineOrigin.y - descent);
        CGFloat yMax = ceil(lineOrigin.y + ascent);
        // Check if we've already passed the line
        if (point.y > yMax) {
            break;
        }
        // Check if the point is within this line vertically
        if (point.y >= yMin) {
            
            // Check if the point is within this line horizontally
            if (point.x >= lineOrigin.x && point.x <= lineOrigin.x + width) {
                
                // Convert CT coordinates to line-relative coordinates
                CGPoint relativePoint = CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
                idx = CTLineGetStringIndexForPosition(line, relativePoint);
                
                break;
            }
        }
    }
    CFRelease(frame);
    CFRelease(path);
    
    return idx;
}


@end
