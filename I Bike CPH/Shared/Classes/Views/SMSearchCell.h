//
//  SMEnterRouteCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 13/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

/**
 * Table view cell for search. Has name label and icon image. Used in SMSearchController.
 */
@interface SMSearchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet TTTAttributedLabel *nameLabel;
@property (weak, nonatomic) IBOutlet AsyncImageView *iconImage;

- (void)setImageWithType:(SearchListItemType)type isFromStreetSearch:(BOOL)isFromStreetSearch;
- (void)setImageWithFavoriteType:(FavoriteItemType)type;

@end
