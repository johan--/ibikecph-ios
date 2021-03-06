//
//  SMEnterRouteCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 20/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "AsyncImageView.h"

/**
 * Table view cell for favorites and recent destinations. Has descriptive icon, name label, and background image
 */
@interface SMEnterRouteCell : UITableViewCell
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *nameLabel;
@property (weak, nonatomic) IBOutlet AsyncImageView *iconImage;
@property (weak, nonatomic) IBOutlet UIImageView *backImage;

+ (CGFloat)getHeight;
@end
