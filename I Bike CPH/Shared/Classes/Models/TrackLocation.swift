//
//  TrackPoint.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 16/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import CoreLocation

// Mirrors CLLocation in a Realm object
class TrackLocation: RLMObject {
    
    dynamic var timestamp: NSTimeInterval = 0
    dynamic var latitude: Double = 0
    dynamic var longitude: Double = 0
    dynamic var altitude: Double = 0
    dynamic var horizontalAccuracy: Double = 0
    dynamic var verticalAccuracy: Double = 0
    dynamic var course: Double = 0
    dynamic var speed: Double = 0
	
	// TODO: Remove when data model doesn't get corrupted by Realm
	dynamic var owned: String = ""
}

extension TrackLocation {
    func date() -> NSDate {
        return NSDate(timeIntervalSince1970: timestamp)
    }
    
    class func build(location: CLLocation) -> TrackLocation {
        let point = TrackLocation()
        point.timestamp = location.timestamp.timeIntervalSince1970
        point.latitude = location.coordinate.latitude
        point.longitude = location.coordinate.longitude
        point.altitude = location.altitude
        point.horizontalAccuracy = location.horizontalAccuracy
        point.verticalAccuracy = location.verticalAccuracy
        point.course = location.course
        point.speed = location.speed
        return point
    }
    
    func coordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func location() -> CLLocation {
        return CLLocation(coordinate: coordinate(), altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: date())
    }
    
    func speedToLocation(toLocation: TrackLocation) -> Double {
        let length = location().distanceFromLocation(toLocation.location())
        let duration = -date().timeIntervalSinceDate(toLocation.date())
        let speed = length / duration
        return speed
    }
}

