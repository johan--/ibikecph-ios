//
//  MotionDetector.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 16/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation
import CoreMotion

class MotionDetector {
    
    var motionActivityManager: CMMotionActivityManager?
    
    init() {
        
    }
    
    func isAvailable() -> Bool {
        return CMMotionActivityManager.isActivityAvailable()
    }
    
    func start(handler: (activity: CMMotionActivity) -> ()) {
        if !isAvailable() {
            return
        }
        println("Start activity updates")
        let manager = CMMotionActivityManager()
        manager.startActivityUpdatesToQueue(NSOperationQueue.mainQueue()) { activity in
            if !Settings.instance.tracking.on {
                return // Received activity even though it should have been stopped
            }
            println("stationary: \(activity.stationary), bike: \(activity.cycling),  walk: \(activity.walking), run: \(activity.running), automotive: \(activity.automotive), unknown: \(activity.unknown), confidence: \(activity.confidence.rawValue), start: \(activity.startDate), ")
            handler(activity: activity)
        }
        self.motionActivityManager = manager
    }
    
    func stop() {
        println("Stop activity updates")
        if let motionActivityManager = motionActivityManager {
            motionActivityManager.stopActivityUpdates()
        }
        motionActivityManager = nil
    }
}