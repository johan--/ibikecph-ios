//
//  TrackDetailViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 23/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


class TrackDetailViewController: SMTranslatedViewController {

    @IBOutlet weak var mapView: MapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Make map passive
        mapView.showsUserLocation = false
        mapView.userTrackingMode = .None
        
        updateUI()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    var track: Track? {
        didSet {
            updateUI()
        }
    }
    
    func updateUI() {
        
        if let track = track {
            zoomToTrack(track)
        } else {
            // Clean up
            if mapView == nil {
                return
            }
            mapView.removeAllAnnotations()
        }
    }
    
    func zoomToTrack(track: Track) {
        
        if mapView == nil {
            return
        }

        let trackLocations = track.locationsSorted().toArray(TrackLocation.self)
        let coordinates = trackLocations.map { return $0.coordinate() }
        // Draw route
        let pathAnnotation = mapView.addPath(coordinates)
        
        // Pins
//        if let startCoordinate = coordinates.first {
//            let startPin = PinAnnotation(mapView: mapView, coordinate: startCoordinate, type: .Start)
//            mapView.addAnnotation(startPin)
//        }
//        if let endCoordinate = coordinates.last {
//            let endPin = PinAnnotation(mapView: mapView, coordinate: endCoordinate, type: .End)
//            mapView.addAnnotation(endPin)
//        }
        
        // Set zoom asynchronous, else MapBox view doesn't render
        Async.main {
            self.mapView.zoomToAnnotation(pathAnnotation, animated: false)
        }
    }
}






