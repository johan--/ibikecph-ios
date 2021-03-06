//
//  SMEvents.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 28/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SMEventsDelegate <NSObject>
- (void)localEventsFound:(NSArray*) evnts;
- (void)facebookEventsFound:(NSArray*) evnts;
@end

/**
 * Handler for fetching events from system calendar on iOS + Facebook
 */
@interface SMEvents : NSObject

/**
 * \ingroup libs
 * Events (local) import
 */
@property (nonatomic, weak) id<SMEventsDelegate> delegate;

- (void)getLocalEvents;

- (void)getAllEvents;

@end
