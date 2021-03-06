//
//  SMSearchController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 14/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAPIOperation.h"
#import "SMNearbyPlaces.h"
#import "SMRequestOSRM.h"
#import "SMTranslatedViewController.h"

@protocol SearchListItem;

@protocol SMSearchDelegate<NSObject>

- (void)locationFound:(NSObject<SearchListItem> *)locationItem;

@end

/**
 * View controller to search for address. Has search field, and results list. FIXME: Merge.
 */
@interface SMSearchController
    : SMTranslatedViewController<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, SMAPIOperationDelegate>

@property(nonatomic, strong) NSString *searchText;
@property(nonatomic, weak) id<SMSearchDelegate> delegate;
@property BOOL shouldAllowCurrentPosition;
@property(nonatomic, strong) NSObject<SearchListItem> *locationItem;

@end
