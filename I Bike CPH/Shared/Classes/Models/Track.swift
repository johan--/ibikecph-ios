//
//  Track.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 16/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import CoreLocation


class Track: RLMObject {
    dynamic var activity: TrackActivity = TrackActivity()
    dynamic var locations = RLMArray(objectClassName: TrackLocation.className())
    dynamic var start = ""
    dynamic var end = ""
    dynamic var length: Double = 0
    dynamic var duration: Double = 0
    dynamic var hasBeenGeocoded: Bool = false
    // Calculated from first and last location object
    dynamic var startTimestamp: Double = 0
    dynamic var endTimestamp: Double = 0
}


extension Track {
	
    func startDate() -> NSDate? {
        return (locations.firstObject() as? TrackLocation)?.date()
    }
	
    func endDate() -> NSDate? {
        return (locations.lastObject() as? TrackLocation)?.date()
    }
	
    func recalculate() {
        let realm = RLMRealm.defaultRealm()
        let transact = !realm.inWriteTransaction
        if transact {
            realm.beginWriteTransaction()
        }
        recalculateTimestamps()
        recalculateDuration()
        recalculateLength()
        if transact {
            realm.commitWriteTransaction()
        }
    }
    
    func deleteFromRealmWithRelationships(realm: RLMRealm = .defaultRealm(), keepLocations: Bool = false, keepActivity: Bool = false) {
        let transact = !realm.inWriteTransaction
        if transact {
            realm.beginWriteTransaction()
        }
        if !keepLocations {
            realm.deleteObjects(locations)
        }
        if !keepActivity,
            let activityRealm = activity.realm where activityRealm == realm {
            realm.deleteObject(activity)
        }
        deleteFromRealm()
        if transact {
            realm.commitWriteTransaction()
        }
    }
    
    private func recalculateTimestamps() {
        // Use first TrackLocation timestamp. Fallback to activity
        startTimestamp = (locations.firstObject() as? TrackLocation)?.timestamp ?? activity.startDate.timeIntervalSince1970 ?? 0
        endTimestamp = (locations.lastObject() as? TrackLocation)?.timestamp ?? activity.startDate.timeIntervalSince1970 ?? 0
    }
    
    private func recalculateLength() {
        var newLength: Double = 0
        for (index, location) in enumerate(locations) {
            if index + 1 >= Int(locations.count) {
                continue
            }
            if let nextLocation = locations[UInt(index+1)] as? TrackLocation {
                if let location = location as? TrackLocation {
                    newLength += location.location().distanceFromLocation(nextLocation.location())
                }
            }
        }
        length = newLength
    }
    
    private func recalculateDuration() {
        if let newDuration = endDate()?.timeIntervalSinceDate(startDate() ?? endDate()!) {
            duration = newDuration
        } else {
            duration = 0
        }
    }
    
    func speeding(#speedLimit: Double, minLength: Double = 0.050) -> Bool {
        let duration = self.duration / 3600
        if duration <= 0 {
            return false
        }
        let length = self.length / 1000
        if length < minLength {
            return false
        }
        let speed = length/duration
        if speed < speedLimit {
            return false
        }
        return true
    }
    
    func slow(#speedLimit: Double, minLength: Double = 0.05) -> Bool {
        let duration = self.duration / 3600
        if duration <= 0 {
            return false
        }
        let length = self.length / 1000
        if length < minLength {
            return false
        }
        let speed = length/duration
        if speed > speedLimit {
            return false
        }
        return true
    }
    
    func lowAccuracy(#minAccuracy: Double = 100) -> Bool {
        let horizontal = self.locations.objectsWithPredicate(nil).averageOfProperty("horizontalAccuracy").doubleValue
        let vertical = self.locations.objectsWithPredicate(nil).averageOfProperty("verticalAccuracy").doubleValue
        return min(horizontal, vertical) > minAccuracy
    }
    
    func flightDistance() -> Double? {
        if locations.count <= 1 {
            return nil
        }
        if let
            firstLocation = locations.firstObject() as? TrackLocation,
            lastLocation = locations.lastObject() as? TrackLocation
        {
            return firstLocation.location().distanceFromLocation(lastLocation.location())
        }
        return nil
    }
    
    func flightWithOneMedianStopDistance() -> Double? {
        if locations.count <= 2 {
            return nil
        }
        if let firstLocation = locations.firstObject() as? TrackLocation {
            let centerIndex = UInt(floor(Double(locations.count)/2))
            if let centerLocation = locations[centerIndex] as? TrackLocation {
                if let lastLocation = locations.lastObject() as? TrackLocation {
                    let distance1 = firstLocation.location().distanceFromLocation(centerLocation.location())
                    let distance2 = centerLocation.location().distanceFromLocation(lastLocation.location())
                    return distance1 + distance2
                }
            }
        }
        return nil
    }
    
    func speeds() -> [Double] {
        var speeds = [Double]()
        for (index, location) in enumerate(locations) {
            if index + 1 >= Int(locations.count) {
                continue
            }
            if let nextLocation = locations[UInt(index+1)] as? TrackLocation {
                if let location = location as? TrackLocation {
                    let length = location.location().distanceFromLocation(nextLocation.location())
                    let duration = nextLocation.date().timeIntervalSinceDate(location.date())
                    let speed = length / duration
                    speeds.append(speed)
                }
            }
        }
        return speeds
    }
    
    func smoothSpeeds() -> [Double] {
        var smoothSpeed: Double = length / duration // Begin at average speed
        let lowpass = 0.01
        var smoothSpeeds = [Double]()
        for speed in speeds() {
            // Ignore extreme jumps in speed
            if speed > 20*smoothSpeed {
                // Do nothing
            } else {
                smoothSpeed = lowpass * speed + (1 - lowpass) * smoothSpeed
            }
            smoothSpeeds.append(smoothSpeed)
        }
        return smoothSpeeds
    }
    
    /**
    Smoothed top speed of track
    
    :returns: Top speed in meters per second [m/s]
    */
    func topSpeed() -> Double {
        let speeds = smoothSpeeds()
        return speeds.count > 0 ? maxElement(speeds) : 0
    }
    
    func geocode(synchronous: Bool = false, completion:((Bool) -> ())? = nil) {
        if let startLocation = locations.firstObject() as? TrackLocation {
            let coordinate = startLocation.coordinate()
            SMGeocoder.reverseGeocode(coordinate, synchronous: synchronous) { (item: KortforItem?, error: NSError?) in
                let transact = !self.realm.inWriteTransaction
                if transact {
                    self.realm.beginWriteTransaction()
                }
                if self.invalidated {
                    if transact {
                        self.realm.cancelWriteTransaction()
                    }
                    completion?(false)
                    return
                }
                if let item = item {
                    self.start = item.street
                }
                if transact {
                    self.realm.commitWriteTransaction()
                }
                if let endLocation = self.locations.lastObject() as? TrackLocation {
                    let coordinate = endLocation.coordinate()
                    SMGeocoder.reverseGeocode(coordinate, synchronous: synchronous) { (item: KortforItem?, error: NSError?) in
                        let transact = !self.realm.inWriteTransaction
                        if transact {
                            self.realm.beginWriteTransaction()
                        }
                        if self.invalidated {
                            if transact {
                                self.realm.cancelWriteTransaction()
                            }
                            completion?(false)
                            return
                        }
                        if let item = item {
                            self.end = item.street
                            self.hasBeenGeocoded = true
                            completion?(true)
                        } else {
                            completion?(false)
                        }
                        if transact {
                            self.realm.commitWriteTransaction()
                        }
                    }
                }
            }
        }
    }
}
