//
//  MapViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import MapboxGL

class MapViewController: ToolbarViewController {

    @IBOutlet weak var mapView: MapView!
    @IBOutlet weak var compassButton: CompassButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Default map
        mapView.mapView.centerCoordinate = macro.initialMapCoordinate
        mapView.mapView.zoomLevel = macro.initialMapZoom
        // Delegate
        mapView.mapView.delegate = self
    }
    
    @IBAction func compassButtonTapped(sender: AnyObject) {
        switch mapView.mapView.userTrackingMode {
            case .None: mapView.mapView.userTrackingMode = .Follow // None -> Follow
            case .Follow: mapView.mapView.userTrackingMode = .FollowWithHeading // Follow -> Heading
            case .FollowWithHeading: mapView.mapView.userTrackingMode = .Follow // Heading -> Follow
        }
    }
    
    func removePin(pin: PinAnnotation) {
        mapView.mapView.removeAnnotation(pin)
    }
    
    func addPin(coordinate: CLLocationCoordinate2D) -> PinAnnotation {
        let pin = PinAnnotation(coordinate: coordinate)
        mapView.mapView.addAnnotation(pin)
        return pin
    }
}


extension MapViewController: MGLMapViewDelegate {
    func mapView(mapView: MGLMapView, didChangeUserTrackingMode mode: MGLUserTrackingMode, animated: Bool) {
        compassButton.userTrackingMode = mode
    }
}

