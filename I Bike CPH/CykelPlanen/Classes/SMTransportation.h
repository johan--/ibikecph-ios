//
//  SMTransportation.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NOTIFICATION_DID_PARSE_DATA_KEY @"NotificationDidParseDataKey"

@class SMStationInfo;

typedef enum { TravelTimeWeekDay = 0, TravelTimeWeekend = 1, TravelTimeWeekendNight = 2 } TravelTime;

/**
 * Handler for transportation. Has stations, lines (FIXME: mutable), trains, bool data loaded, bool loading stations. Used in
 * SMBreakRouteViewController, SMRouteInforViewController, SMRouteNavigationController, SMSplashController, SMStationInfo,
 * SMStationsCache, SMTransportation, SMTransportationLine, SMTripRoute.
 */
@interface SMTransportation : NSObject<NSXMLParserDelegate, NSCoding>

+ (SMTransportation *)sharedInstance;
+ (NSOperationQueue *)transportationQueue;

@property(nonatomic, strong) NSArray *allStations;
@property(nonatomic, strong) NSArray *lines;
@property(nonatomic, strong) NSArray *trains;
@property(nonatomic, assign) BOOL dataLoaded;
@property(nonatomic, assign) BOOL loadingStations;
- (void)save;
- (void)validateAndSave;
- (SMStationInfo *)stationWithName:(NSString *)name;
@end
