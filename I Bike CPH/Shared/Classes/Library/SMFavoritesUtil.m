//
//  SMFavoritesUtil.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 24/04/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMFavoritesUtil.h"

@interface SMFavoritesUtil ()
@property(nonatomic, strong) SMAPIRequest *apr;
@property(nonatomic, readonly) SMAppDelegate *appDelegate;
@end

@implementation SMFavoritesUtil

#pragma mark - Setters and Getters {
- (SMAppDelegate *)appDelegate
{
    return (SMAppDelegate *)[UIApplication sharedApplication].delegate;
}

#pragma mark -

+ (NSArray *)favorites
{
    return [self getFavorites].copy;
}

+ (NSMutableArray *)getFavorites
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                                                             stringByAppendingPathComponent:@"favorites.plist"]]) {
        NSArray *arr = [NSArray arrayWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                                                                   lastObject] stringByAppendingPathComponent:@"favorites.plist"]];
        NSMutableArray *arr2 = [NSMutableArray array];
        if (arr) {
            for (NSDictionary *d in arr) {
                FavoriteItem *favoriteItem = [[FavoriteItem alloc] initWithPlistDictionary:d];
                [arr2 addObject:favoriteItem];
            }
            return arr2;
        }
    }
    return [NSMutableArray array];
}

+ (BOOL)saveFavorites:(NSArray *)fav
{
    NSMutableArray *r = [NSMutableArray array];
    for (FavoriteItem *item in fav) {
        [r addObject:item.plistRepresentation];
    }
    return [r writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                              stringByAppendingPathComponent:@"favorites.plist"]
               atomically:YES];
}

+ (BOOL)saveToFavorites:(FavoriteItem *)item
{
    NSMutableArray *arr = [NSMutableArray array];
    NSMutableArray *a = [self getFavorites];
    for (FavoriteItem *srch in a) {
        if ([srch.name isEqualToString:item.name] == NO) {
            [arr addObject:srch];
        }
    }
    [arr addObject:item];

    BOOL x = [SMFavoritesUtil saveFavorites:arr];

    return x;
}

+ (SMFavoritesUtil *)instance
{
    static SMFavoritesUtil *instance;
    if (instance == nil) {
        instance = [[SMFavoritesUtil alloc] init];
    }
    return instance;
}

- (SMFavoritesUtil *)initWithDelegate:(id<SMFavoritesDelegate>)delegate
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)fetchFavoritesFromServer
{
    SMAPIRequest *ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"fetchList"];
    [self.apr executeRequest:API_LIST_FAVORITES withParams:@{ @"auth_token" : [self.appDelegate.appSettings objectForKey:@"auth_token"] }];
}

- (void)addFavoriteToServer:(FavoriteItem *)favItem
{
    [SMFavoritesUtil saveToFavorites:favItem];
    SMAPIRequest *ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"addFavorite"];
    [self.apr executeRequest:API_ADD_FAVORITE
                  withParams:@{
                      @"auth_token" : [self.appDelegate.appSettings objectForKey:@"auth_token"],
                      @"favourite" : @{
                          @"name" : favItem.name,
                          @"address" : favItem.address,
                          @"lattitude" : @(favItem.location.coordinate.latitude),
                          @"longitude" : @(favItem.location.coordinate.longitude),
                          @"source" : @"favourites",
                          @"sub_source" : [self stringForOrigin:favItem.origin]
                      }
                  }];
}

- (void)deleteFavoriteFromServer:(FavoriteItem *)favItem
{
    NSMutableArray *a = [SMFavoritesUtil getFavorites];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF.identifier = %@", favItem.identifier];
    NSArray *arr = [a filteredArrayUsingPredicate:pred];
    if ([arr count] > 0) {
        [a removeObjectsInArray:arr];
    }
    [SMFavoritesUtil saveFavorites:a];

    SMAPIRequest *ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"deleteFavorite"];
    NSMutableDictionary *params = [API_DELETE_FAVORITE mutableCopy];
    params[@"service"] = [NSString stringWithFormat:@"%@/%@", params[@"service"], favItem.identifier];
    [self.apr executeRequest:params withParams:@{ @"auth_token" : [self.appDelegate.appSettings objectForKey:@"auth_token"] }];
}

- (void)editFavorite:(FavoriteItem *)favItem
{
    SMAPIRequest *ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"editFavorite"];
    NSMutableDictionary *params = [API_EDIT_FAVORITE mutableCopy];
    params[@"service"] = [NSString stringWithFormat:@"%@/%@", params[@"service"], favItem.identifier];
    [self.apr executeRequest:params
                  withParams:@{
                      @"auth_token" : [self.appDelegate.appSettings objectForKey:@"auth_token"],
                      @"favourite" : @{
                          @"name" : favItem.name,
                          @"address" : favItem.address,
                          @"lattitude" : @(favItem.location.coordinate.latitude),
                          @"longitude" : @(favItem.location.coordinate.longitude),
                          @"source" : [self stringForOrigin:favItem.origin]
                      }
                  }];
}

- (NSString *)stringForOrigin:(FavoriteItemType)type
{
    switch (type) {
        case FavoriteItemTypeHome:
            return @"home";
        case FavoriteItemTypeWork:
            return @"work";
        case FavoriteItemTypeSchool:
            return @"school";
        case FavoriteItemTypeUnknown:
            return @"favourites";
    }
}

#pragma mark - api delegate

- (void)serverNotReachable
{
}

- (void)request:(SMAPIRequest *)req failedWithError:(NSError *)error
{
    NSLog(@"%@", error);
    //    UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[error description] delegate:nil
    //    cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
    //    [av show];
    if (self.delegate && [self.delegate respondsToSelector:@selector(favoritesOperation:failedWithError:)]) {
        [self.delegate favoritesOperation:self failedWithError:error];
    }
}

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result
{
    if ([result objectForKey:@"error"]) {
        [SMFavoritesUtil saveFavorites:@[]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kFAVORITES_CHANGED object:self];
        if (self.delegate && [self.delegate respondsToSelector:@selector(favoritesOperationFinishedSuccessfully:withData:)]) {
            [self.delegate favoritesOperationFinishedSuccessfully:req withData:result];
        }
    }
    else if ([[result objectForKey:@"success"] boolValue]) {
        if ([req.requestIdentifier isEqualToString:@"fetchList"]) {
            NSMutableArray *arr = [NSMutableArray arrayWithCapacity:result.count];
            for (NSDictionary *d in [result objectForKey:@"data"]) {
                FavoriteItem *item = [[FavoriteItem alloc] initWithJsonDictionary:d];
                [arr addObject:item];
            }
            [SMFavoritesUtil saveFavorites:arr];
            [[NSNotificationCenter defaultCenter] postNotificationName:kFAVORITES_CHANGED object:self];
            if (self.delegate && [self.delegate respondsToSelector:@selector(favoritesOperationFinishedSuccessfully:withData:)]) {
                [self.delegate favoritesOperationFinishedSuccessfully:req withData:result];
            }
        }
        else if ([req.requestIdentifier isEqualToString:@"addFavorite"]) {
            NSString *identifier = [result[@"data"][@"id"] stringValue];
            // Add id to favorite item missing it
            NSMutableArray *favorites = [SMFavoritesUtil favorites].mutableCopy;
            for (FavoriteItem *favorite in favorites) {
                if ([favorite.identifier isEqualToString:@""]) {
                    favorite.identifier = identifier;
                    break;
                }
            }
            [SMFavoritesUtil saveFavorites:favorites];
            [[NSNotificationCenter defaultCenter] postNotificationName:kFAVORITES_CHANGED object:self];
        }
        else {
            [self fetchFavoritesFromServer];
        }
    }
    else {
        if (result[@"invalid_token"]) {
            return;
        }
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error".localized
                                                     message:result[@"info"]
                                                    delegate:nil
                                           cancelButtonTitle:@"OK".localized
                                           otherButtonTitles:nil];
        [av show];
    }
}

@end
