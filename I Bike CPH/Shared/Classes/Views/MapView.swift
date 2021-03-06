//
//  MapView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit


protocol MapViewTrackingDelegate {
    func didChangeUserTrackingMode(mode: MapView.UserTrackingMode)
}
protocol MapViewDelegate {
    func didSelectCoordinate(coordinate: CLLocationCoordinate2D)
    func didSelectAnnotation(annotation: Annotation)
}

class MapView: UIView {
    
    enum UserTrackingMode: Int {
        case None, Follow, FollowWithHeading
        
        func rmUserTrackingMode() -> RMUserTrackingMode {
            switch self {
                case .None: return RMUserTrackingModeNone
                case .Follow: return RMUserTrackingModeFollow
                case .FollowWithHeading: return RMUserTrackingModeFollowWithHeading
            }
        }
        
        static func build(rmUserTrackingMode: RMUserTrackingMode) -> UserTrackingMode {
            switch rmUserTrackingMode {
                case RMUserTrackingModeNone: return .None
                case RMUserTrackingModeFollow: return .Follow
                case RMUserTrackingModeFollowWithHeading: return .FollowWithHeading
                default: return .None
            }
        }
    }
    
    private(set) lazy var mapView: RMMapView = {
        let tileSource = SMiBikeCPHMapTileSource()
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        RMConfiguration.sharedInstance().accessToken = "sk.eyJ1IjoiZW1pbHRpbiIsImEiOiJkM2M2ZjAwYzAzMmM1YTRmMzNlZDI1YzM3OTNiZjMxMCJ9.Oh1XyjGZjFB_RQBzfbC2bg"
        let map = RMMapView(frame: rect, andTilesource: tileSource)
        return map
    }()
    
    var delegate: MapViewDelegate?
    var trackingDelegate: MapViewTrackingDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    init() {
        super.init(frame: CGRectZero)
        setup()
    }
    
    func setup() {
        addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([
            NSLayoutConstraint(item: mapView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: mapView, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: mapView, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: mapView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)
            ])
        
        mapView.delegate = self
        
        self.setupBackgroundHandling()
    }
    
    var initialRegionLoadNecessary = true
    func loadInitialRegionIfNecessary() {
        if initialRegionLoadNecessary {
            // Default map
            centerCoordinate = macro.initialMapCoordinate
            zoomLevel = macro.initialMapZoom
            initialRegionLoadNecessary = false
        }
    }

    /// Convenience for Objective-C compatibility
    func addPathWithLocations(locations: [CLLocation], lineColor: UIColor = Styler.tintColor(), lineWidth: Float = 4.0) -> Annotation {
        let coordinates = locations.map { $0.coordinate }
        return addPath(coordinates, lineColor: lineColor, lineWidth: lineWidth)
    }

    let lineDashLengths = [1, 0.1, 1, 10, 100]
    func addPath(coordinates: [CLLocationCoordinate2D], lineColor: UIColor = Styler.tintColor(), lineWidth: Float = 4.0) -> Annotation {
        // Shape
        let shape = RMShape(view: mapView)
        shape.lineColor = lineColor
        shape.lineWidth = lineWidth
        shape.lineJoin = "round"
        shape.lineCap = "round"
        
        // Add coordinates
        var waypoints: [CLLocation] = [CLLocation]()
        for coordinate in coordinates {
            shape.addLineToCoordinate(coordinate)
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoints.append(location)
        }
        // Annotation
        let pathAnnotation = LayerAnnotation(layer: shape, mapView: self)
        if let firstCoordinate = coordinates.first {
            pathAnnotation.coordinate = firstCoordinate
        }
        // Bounding box
        pathAnnotation.setBoundingBoxFromLocations(waypoints)
        // Add to map
        addAnnotation(pathAnnotation)
        return pathAnnotation
    }
    
    func zoomToAnnotation(annotation: Annotation, animated: Bool = true, padding: Double = 0.25) {
        // Padding
        let bounds = mapView.sphericalTrapezium(forProjectedRect: annotation.projectedBoundingBox).padded(padding)
        // Zoom
        mapView.zoomWithLatitudeLongitudeBoundsSouthWest(bounds.southWest, northEast: bounds.northEast, animated: animated)

        initialRegionLoadNecessary = false
    }

    func zoomToAnnotations(annotations: [Annotation], animated: Bool = true, padding: Double = 0.25) {
        // Padding
        var totalBounds: RMSphericalTrapezium? = nil
        for annotation in annotations {
            let bounds = mapView.sphericalTrapezium(forProjectedRect: annotation.projectedBoundingBox)
            if let tempTotalBounds = totalBounds {
                let newSW = bounds.southWest
                if newSW.latitude < tempTotalBounds.southWest.latitude {
                    totalBounds?.southWest.latitude = newSW.latitude
                }
                if newSW.longitude < tempTotalBounds.southWest.longitude {
                    totalBounds?.southWest.longitude = newSW.longitude
                }
                let newNE = bounds.northEast
                if newNE.latitude > tempTotalBounds.northEast.latitude {
                    totalBounds?.northEast.latitude = newNE.latitude
                }
                if newNE.longitude > tempTotalBounds.northEast.longitude {
                    totalBounds?.northEast.longitude = newNE.longitude
                }
            } else {
                totalBounds = bounds
            }
        }
        if let bounds = totalBounds?.padded(padding) {
            // Zoom
            mapView.zoomWithLatitudeLongitudeBoundsSouthWest(bounds.southWest, northEast: bounds.northEast, animated: animated)

            initialRegionLoadNecessary = false
        }
    }

    func addAnnotationsForRoute(route: SMRoute, from: SearchListItem?, to: SearchListItem?, zoom: Bool = true) -> [Annotation] {
        var annotations = [Annotation]()
        if let locations = route.waypoints?.copy() as? [CLLocation] { // Copy since it is NSMutableArray
            let coordinates = locations.map { $0.coordinate } // Map to coordinates
            let lineColor = .Bike == route.routeType ? Styler.tintColor() : Styler.foregroundColor()
            let annotation = addPath(coordinates, lineColor: lineColor, lineWidth: 5)
            annotations.append(annotation)
            if zoom {
                // Zoom to entire path
                zoomToAnnotation(annotation)
            }
            
            if let
                pinStart = from?.location?.coordinate,
                pathStart = coordinates.first
            {
                let annotation = addPath([pinStart, pathStart], lineColor: Styler.foregroundSecondaryColor())
                annotations.append(annotation)
            }
            if let
                pinEnd = to?.location?.coordinate,
                pathEnd = coordinates.last
            {
                let annotation = addPath([pathEnd, pinEnd], lineColor: Styler.foregroundSecondaryColor())
                annotations.append(annotation)
            }
        }
        // Pins
        if let startCoordinate = from?.location?.coordinate {
            // Pin
            let startPin = PinAnnotation(mapView: self, coordinate: startCoordinate, type: .Start)
            addAnnotation(startPin)
            annotations.append(startPin)
        } else if let pinType = PinAnnotation.typeForRouteType(route.routeType),
                      coordinate = (route.waypoints?.copy() as? [CLLocation])?.first?.coordinate
        {
            let startPin = PinAnnotation(mapView: self, coordinate: coordinate, type: pinType)
            addAnnotation(startPin)
            annotations.append(startPin)
        }
        if let endCoordinate = to?.location?.coordinate {
            let endPin = PinAnnotation(mapView: self, coordinate: endCoordinate, type: .End)
            mapView.addAnnotation(endPin)
            annotations.append(endPin)
        }
        return annotations
    }

    func addAnnotationsForRouteComposite(routeComposite: RouteComposite, from: SearchListItem, to: SearchListItem, zoom: Bool = true) -> [Annotation] {
        switch routeComposite.composite {
        case .Single(let route):
            return addAnnotationsForRoute(route, from: from, to: to, zoom: zoom)
        case .Multiple(let routes):
            var annotations: [Annotation] = []
            for route in routes {
                let routeAnnotations: [Annotation] = {
                    if route == routes.first && route == routeComposite.currentRoute {
                        return self.addAnnotationsForRoute(route, from: from, to: nil, zoom: false)
                    } else if  route == routes.last {
                        return self.addAnnotationsForRoute(route, from: nil, to: to, zoom: false)
                    } else {
                        return self.addAnnotationsForRoute(route, from: nil, to: nil, zoom: false)
                    }
                }()
                annotations.appendContentsOf(routeAnnotations)
            }
            if zoom {
                zoomToAnnotations(annotations)
            }
            return annotations
        }
    }
    
// MARK: To avoid location updates when app is in background
    private var foregroundUserTrackingMode: UserTrackingMode = .None
    private var foregroundShowsUserLocation: Bool = false
    private var observerTokens = [AnyObject]()
    
    private func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    func setupBackgroundHandling() {
        // When the app is in the background userTrackingMode/showsUserLocation must be set to .None/false
        // in order to stop location updates in the map view.
        observerTokens.append(NotificationCenter.observe(UIApplicationDidEnterBackgroundNotification) { notification in
            self.foregroundUserTrackingMode = self.userTrackingMode
            self.foregroundShowsUserLocation = self.showsUserLocation
            self.userTrackingMode = .None
            self.showsUserLocation = false
        })
        observerTokens.append(NotificationCenter.observe(UIApplicationWillEnterForegroundNotification) { notification in
            self.userTrackingMode = self.foregroundUserTrackingMode
            self.showsUserLocation = self.foregroundShowsUserLocation
        })
    }
    
    deinit {
        unobserve()
    }
}


class LayerAnnotation: Annotation {
    
    let layerStore: RMMapLayer
    init(layer: RMMapLayer, mapView: MapView) {
        layerStore = layer
        super.init()
        self.mapView = mapView.mapView
    }
}

/// Proxy for RMMapView
extension MapView {
    var centerCoordinate: CLLocationCoordinate2D {
        set {
            mapView.centerCoordinate = newValue
            initialRegionLoadNecessary = false
        }
        get {
            return mapView.centerCoordinate
        }
    }
    var zoomLevel: Double {
        set {
            mapView.zoom = Float(newValue)
            initialRegionLoadNecessary = false
        }
        get {
            return Double(mapView.zoom)
        }
    }
    var showsUserLocation: Bool {
        set {
            mapView.showsUserLocation = newValue
        }
        get {
            return mapView.showsUserLocation
        }
    }
    var userTrackingMode: UserTrackingMode {
        set {
            mapView.userTrackingMode = newValue.rmUserTrackingMode()
        }
        get {
            return UserTrackingMode.build(mapView.userTrackingMode)
        }
    }
    func centerCoordinate(coordinate: CLLocationCoordinate2D, zoomLevel: Double, animated: Bool = true) {
        mapView.setZoom(Float(zoomLevel), atCoordinate: coordinate, animated: animated)
        initialRegionLoadNecessary = false
    }
    func addAnnotation(annotation: Annotation) {
        mapView.addAnnotation(annotation)
    }
    func addAnnotations(annotations: [Annotation]) {
        mapView.addAnnotations(annotations)
    }
    func removeAnnotation(annotation: Annotation) {
        mapView.removeAnnotation(annotation)
    }
    func removeAnnotations(annotations: [Annotation]) {
        mapView.removeAnnotations(annotations)
    }
    func removeAllAnnotations() {
        mapView.removeAllAnnotations()
    }
}

extension MapView: RMMapViewDelegate {
    
    func mapView(mapView: RMMapView, didSelectAnnotation annotation: RMAnnotation) {
        if let annotation = annotation as? Annotation {
            delegate?.didSelectAnnotation(annotation)
        }
    }
    
    func longPressOnMap(map: RMMapView, at point: CGPoint) {
        let coordinate = mapView.pixelToCoordinate(point)
        delegate?.didSelectCoordinate(coordinate)
    }
    
    func mapView(mapView: RMMapView, didChangeUserTrackingMode mode: RMUserTrackingMode, animated: Bool) {
        let mode = UserTrackingMode.build(mode)
        trackingDelegate?.didChangeUserTrackingMode(mode)
    }
    
    func mapView(mapView: RMMapView!, layerForAnnotation annotation: RMAnnotation!) -> RMMapLayer! {
        if let layerAnnotation = annotation as? LayerAnnotation {
            // To fix bug when setting .layer directly on annotation (layer disappears when scrolling away and back), provide layer with a property on custom LayerAnnotation class here in the delegate callback
            return layerAnnotation.layerStore
        }
        if let annotation = annotation as? Annotation {
            return RMMarker(UIImage: annotation.annotationIcon, anchorPoint: annotation.anchorPoint)
        }
        return nil
    }
}

extension RMSphericalTrapezium {
    func padded(padding: Double = 0.25) -> RMSphericalTrapezium {
        var northEast = self.northEast
        var southWest = self.southWest
        
        let latitudeDiff = abs(northEast.latitude - southWest.latitude)
        let longitudeDiff = abs(northEast.longitude - southWest.longitude)
        
        northEast.latitude += latitudeDiff * padding;
        northEast.longitude += longitudeDiff * padding;
        
        southWest.latitude -= latitudeDiff * padding;
        southWest.longitude -= longitudeDiff * padding;
        
        return RMSphericalTrapezium(southWest: southWest, northEast: northEast)
    }
}

extension RMMapView {
    func sphericalTrapezium(forProjectedRect rect: RMProjectedRect) -> RMSphericalTrapezium {
        let neProjected = RMProjectedPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height)
        let ne = projectedPointToCoordinate(neProjected)
        let swProjected = RMProjectedPoint(x: rect.origin.x, y: rect.origin.y )
        let sw = projectedPointToCoordinate(swProjected)
        return RMSphericalTrapezium(southWest: sw, northEast: ne)
    }
}