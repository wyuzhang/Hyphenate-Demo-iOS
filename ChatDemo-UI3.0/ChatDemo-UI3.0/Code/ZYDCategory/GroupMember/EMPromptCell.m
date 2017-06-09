//
//  EMPromptCell.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/6/9.
//  Copyright © 2017年 easemob. All rights reserved.
//

#import "EMPromptCell.h"

@implementation EMPromptCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (NSString *)promptCellIdentifier
{
    return @"Prompt_Message_Cell";
}

@end
