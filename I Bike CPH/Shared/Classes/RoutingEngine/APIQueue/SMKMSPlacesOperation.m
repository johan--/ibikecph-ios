//
//  SMKMSPlacesOperation.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/11/2013.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "SMKMSPlacesOperation.h"
#import "SMLocationManager.h"

@implementation SMKMSPlacesOperation

- (void)startOperation
{
    self.searchString = self.startItem.street;

#warning The `stednavn` parameter should be able to accept wildcard (*) both as prefix and suffix of the parameter value string
    NSString *URLString = [[NSString
        stringWithFormat:@"https://kortforsyningen.kms.dk/"
                         @"?servicename=%@&method=stedv2&stednavn=%@*&geop=%lf,%lf&georef=EPSG:4326&outgeoref=EPSG:4326&login=%@&password=%@&hits=%@",
                         KORT_SERVICE, self.searchString, [SMLocationManager sharedInstance].lastValidLocation.coordinate.longitude,
                         [SMLocationManager sharedInstance].lastValidLocation.coordinate.latitude, [SMRouteSettings sharedInstance].kort_username,
                         [SMRouteSettings sharedInstance].kort_password, [SMRouteSettings sharedInstance].kort_max_results]
        stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    debugLog(@"*** URL: %@", URLString);

    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URLString]];

    self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    [self.conn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.conn start];
    self.timeoutTimer =
        [NSTimer scheduledTimerWithTimeInterval:URL_CONNECTION_TIMEOUT target:self selector:@selector(timeoutCancel:) userInfo:nil repeats:NO];
}

- (void)processResult:(id)result
{
    NSDictionary *json = (NSDictionary *)result;
    NSMutableCharacterSet *set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [set addCharactersInString:@","];
    NSMutableArray *addressArray = [NSMutableArray new];

    for (NSDictionary *feature in json[@"features"]) {
        KortforItem *item = [[KortforItem alloc] initWithJsonDictionary:feature];

        NSInteger relevance = [SMRouteUtils
            pointsForName:[[NSString stringWithFormat:@"%@ , %@ %@", item.street, item.zip, item.city] stringByTrimmingCharactersInSet:set]
                  address:[[NSString stringWithFormat:@"%@ , %@ %@", item.street, item.zip, item.city] stringByTrimmingCharactersInSet:set]
                    terms:self.searchString];
        item.relevance = relevance;
        item.distance = [[SMLocationManager sharedInstance].lastValidLocation distanceFromLocation:item.location];

        [addressArray addObject:item];
    }

    [addressArray sortUsingComparator:^NSComparisonResult(KortforItem *obj1, KortforItem *obj2) {
      long first = obj1.distance;
      long second = obj2.distance;

      if (first < second) {
          return NSOrderedAscending;
      }
      else if (first > second) {
          return NSOrderedDescending;
      }
      else {
          return NSOrderedSame;
      }
    }];

    self.results = addressArray;
}

@end