//
//  SMRadioCheckedCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 07/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Table view cell w/ radio button. Has title label and text view. Used in SMErrorReportController.
 */
@interface SMRadioCheckedCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *radioTitle;
@property (weak, nonatomic) IBOutlet UITextView *radioTextBox;

+ (CGFloat)getHeight;

@end
