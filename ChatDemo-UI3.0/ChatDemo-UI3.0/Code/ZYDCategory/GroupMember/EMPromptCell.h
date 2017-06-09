//
//  EMPromptCell.h
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/6/9.
//  Copyright © 2017年 easemob. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMPromptCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *promptLabel;

+ (NSString *)promptCellIdentifier;

@end
