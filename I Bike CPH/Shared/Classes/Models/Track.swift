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
    
    dynamic var startTimestamp: Double = 0
    dynamic var endTimestamp: Double = 0
    
    var startDate: NSDate? {
        return (locations.firstObject() as? TrackLocation)?.date
    }
    var endDate: NSDate? {
        return (locations.lastObject() as? TrackLocation)?.date
    }
    
    func recalculate() {
        recalculateTimestamps()
        recalculateDuration()
        recalculateLength()
    }
    
    private func recalculateTimestamps() {
        realm.beginWriteTransaction()
        if let location = locations.firstObject() as? TrackLocation {
            startTimestamp = location.timestamp
        }
        if let location = locations.lastObject() as? TrackLocation {
            endTimestamp = location.timestamp
        }
        realm.commitWriteTransaction()
    }
    
    private func recalculateLength() {
        var newLength: Double = 0
        for (index, location) in enumerate(locations) {
            if index + 1 >= locations.count {
                continue
            }
            if let nextLocation = locations[index+1] as? TrackLocation {
                if let location = location as? TrackLocation {
                    newLength += location.location().distanceFromLocation(nextLocation.location())
                }
            }
        }
        realm.beginWriteTransaction()
        length = newLength
        realm.commitWriteTransaction()
    }
    
    private func recalculateDuration() {
        realm.beginWriteTransaction()
        if let newDuration = endDate?.timeIntervalSinceDate(startDate ?? endDate!) {
            duration = newDuration
        } else {
            duration = 0
        }
        realm.commitWriteTransaction()
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
    
    func flightDistance() -> Double {
        if let firstLocation = locations.firstObject() as? TrackLocation {
            if let lastLocation = locations.lastObject() as? TrackLocation {
                return firstLocation.location().distanceFromLocation(lastLocation.location())
            }
        }
        return 0
    }
}
