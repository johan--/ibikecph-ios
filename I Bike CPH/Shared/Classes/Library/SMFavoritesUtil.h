//
//  SMFavoritesUtil.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 24/04/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMAPIRequest.h"

@class SMFavoritesUtil;
@class FavoriteItem;

@protocol SMFavoritesDelegate <NSObject>
- (void)favoritesOperationFinishedSuccessfully:(id)req withData:(id)data;
@optional
- (void)favoritesOperation:(id)req failedWithError:(NSError*)error;
@end

/**
 * Handler that fetches/saves favorites
 */
@interface SMFavoritesUtil : NSObject <SMAPIRequestDelegate>

@property (nonatomic, weak) id<SMFavoritesDelegate>delegate;

+ (NSArray *)favorites;
+ (NSMutableArray *)getFavorites;
+ (BOOL)saveToFavorites:(FavoriteItem *)item;
+ (BOOL)saveFavorites:(NSArray *)fav;

+ (SMFavoritesUtil *)instance;

- (SMFavoritesUtil *)initWithDelegate:(id<SMFavoritesDelegate>)delegate;
- (void)fetchFavoritesFromServer;
- (void)addFavoriteToServer:(FavoriteItem *)favItem;
- (void)deleteFavoriteFromServer:(FavoriteItem *)favItem;
- (void)editFavorite:(FavoriteItem *)favItem;

@end
