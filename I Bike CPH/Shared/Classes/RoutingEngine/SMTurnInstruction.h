//
//  SMTurnInstructions.h
//  I Bike CPH
//
//  Created by Petra Markovic on 1/28/13.
//  Copyright (C) 2013 City of Copenhagen.  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at
//  http://mozilla.org/MPL/2.0/.
//

#import "SMRoute.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, OSRMV4TurnDirection) {
    OSRMV4TurnDirectionNoTurn = 0,
    OSRMV4TurnDirectionGoStraight = 1,
    OSRMV4TurnDirectionTurnSlightRight = 2,
    OSRMV4TurnDirectionTurnRight = 3,
    OSRMV4TurnDirectionTurnSharpRight = 4,
    OSRMV4TurnDirectionUTurn = 5,
    OSRMV4TurnDirectionTurnSharpLeft = 6,
    OSRMV4TurnDirectionTurnLeft = 7,
    OSRMV4TurnDirectionTurnSlightLeft = 8,
    OSRMV4TurnDirectionReachViaPoint = 9,
    OSRMV4TurnDirectionHeadOn = 10,
    OSRMV4TurnDirectionEnterRoundAbout = 11,
    OSRMV4TurnDirectionLeaveRoundAbout = 12,
    OSRMV4TurnDirectionStayOnRoundAbout = 13,
    OSRMV4TurnDirectionStartAtEndOfStreet = 14,
    OSRMV4TurnDirectionReachedYourDestination = 15,
    OSRMV4TurnDirectionStartPushingBikeInOneway = 16,
    OSRMV4TurnDirectionStopPushingBikeInOneway = 17,
    OSRMV4TurnDirectionBoardPublicTransport = 18,
    OSRMV4TurnDirectionUnboardPublicTransport = 19,
    OSRMV4TurnDirectionReachingDestination = 100
};

typedef NS_ENUM(NSUInteger, OSRMV5ManeuverType) {
    OSRMV5ManeuverTypeTurn,
    OSRMV5ManeuverTypeNewName,
    OSRMV5ManeuverTypeDepart,
    OSRMV5ManeuverTypeArrive,
    OSRMV5ManeuverTypeMerge,
    OSRMV5ManeuverTypeRamp,
    OSRMV5ManeuverTypeOnRamp,
    OSRMV5ManeuverTypeOffRamp,
    OSRMV5ManeuverTypeFork,
    OSRMV5ManeuverTypeEndOfRoad,
    OSRMV5ManeuverTypeUseLane,
    OSRMV5ManeuverTypeContinue,
    OSRMV5ManeuverTypeRoundabout,
    OSRMV5ManeuverTypeRotary,
    OSRMV5ManeuverTypeRoundaboutTurn,
    OSRMV5ManeuverTypeNotification
};

typedef NS_ENUM(NSUInteger, OSRMV5ManeuverModifier) {
    OSRMV5ManeuverModifierUTurn,
    OSRMV5ManeuverModifierSharpRight,
    OSRMV5ManeuverModifierRight,
    OSRMV5ManeuverModifierSlightRight,
    OSRMV5ManeuverModifierStraight,
    OSRMV5ManeuverModifierSlightLeft,
    OSRMV5ManeuverModifierLeft,
    OSRMV5ManeuverModifierSharpLeft,
    OSRMV5ManeuverModifierNone
};

typedef NS_ENUM(NSUInteger, TurnInstructionOSRMVersion) {
    TurnInstructionOSRMVersion4,
    TurnInstructionOSRMVersion5
};

@interface SMTurnInstruction : NSObject

@property(nonatomic, assign) TurnInstructionOSRMVersion osrmVersion;
@property(nonatomic, readonly) NSString *roundedDistanceToNextTurn;
@property(nonatomic, strong) CLLocation *location;
@property int waypointsIndex;
@property int timeInSeconds;
@property(nonatomic, assign) SMRouteType routeType;
@property(nonatomic, strong) NSString *fixedLengthWithUnit;

@property(nonatomic, readonly) NSString *shortDescriptionString;
@property(nonatomic, readonly) NSString *descriptionString;
@property(nonatomic, readonly) NSString *fullDescriptionString;
@property(nonatomic, readonly) UIImage *directionIcon;

- (void)generateDescriptionString;
- (void)generateStartDescriptionString;
- (void)generateFullDescriptionString;
- (void)generateShortDescriptionString;

#pragma mark - OSRM Version 4 only properties
@property(nonatomic, assign) OSRMV4TurnDirection turnDirection;
@property(nonatomic, strong) NSDate *routeLineTime;
@property(nonatomic, strong) NSString *routeLineName;
@property(nonatomic, strong) NSString *routeLineStart;
@property(nonatomic, strong) NSString *routeLineDestination;
@property(nonatomic, strong) NSString *imageName;
@property int lengthInMeters;
@property(nonatomic, strong) NSString *ordinalDirection;
@property(nonatomic, strong) NSString *wayName;
@property(nonatomic, strong) NSString *directionAbbreviation;  // N: north, S: south, E: east, W: west, NW: North West, ...

#pragma mark - OSRM Version 5 only properties, methods
@property (nonatomic, readonly) OSRMV5ManeuverType maneuverType;
@property (nonatomic, readonly) OSRMV5ManeuverModifier maneuverModifier;

- (void)setManeuverTypeWithString:(NSString *)maneuverTypeString;
- (void)setManeuverModifierWithString:(NSString *)maneuverModifierString;
- (void)setDirectionAbbreviationWithBearingAfter:(NSUInteger)bearingAfter;

@end