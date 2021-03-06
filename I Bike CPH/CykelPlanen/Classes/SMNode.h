//
//  SMNode.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/23/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Route node. Has reference string, role string, and coordinate. Used in SMTransportation and SMTransportationLine
 */
@interface SMNode : NSObject

@property(nonatomic, strong) NSString* ref;
@property(nonatomic, strong) NSString* role;
@property(nonatomic, assign) CLLocationCoordinate2D coordinate;
@end
