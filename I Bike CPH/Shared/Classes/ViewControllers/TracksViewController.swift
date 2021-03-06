//
//  TracksViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class TracksViewController: SMTranslatedViewController {

    @IBOutlet weak var tableView: UITableView!
    private var tracks: RLMResults?
    private var selectedTrack: Track?
    private var observerTokens = [AnyObject]()
    
    deinit {
        unobserve()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        observerTokens.append(NotificationCenter.observe(processedSmallNoticationKey) { [weak self] notification in
            self?.updateUI()
        })
        observerTokens.append(NotificationCenter.observe(processedBigNoticationKey) { [weak self] notification in
            self?.updateUI()
        })
        observerTokens.append(NotificationCenter.observe(processedGeocodingNoticationKey) { [weak self] notification in
            self?.updateUI()
        })
        updateUI()
    }
    
    func updateUI() {
        tracks = Track.allObjects().sortedResultsUsingProperty("startTimestamp", ascending: false)
        tableView.reloadData()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if
            segue.identifier == "trackListToDetail",
            let track = selectedTrack,
            trackDetailViewController = segue.destinationViewController as? TrackDetailViewController
        {
            trackDetailViewController.track = track
        }
    }
    
    private func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    @IBAction func didTapCleanUp(sender: AnyObject) {
        TracksHandler.setNeedsProcessData(true)
    }
}


private let cellID = "TrackCell"

extension TracksViewController: UITableViewDataSource {
    
    func track(indexPath: NSIndexPath?) -> Track? {
        if let indexPath = indexPath {
            return tracks?[UInt(indexPath.row)] as? Track
        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(tracks?.count ?? 0)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as DebugTrackTableViewCell
        cell.updateToTrack(track(indexPath), index: indexPath.row)
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
            track(indexPath)?.deleteFromRealmWithRelationships()
            tableView.endUpdates()
        }
    }
}

extension TracksViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let track = track(indexPath) {
            selectedTrack = track
            performSegueWithIdentifier("trackListToDetail", sender: self)
        }
    }
}







class DebugTrackTableViewCell: UITableViewCell {
    
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var mapView: TrackMapView!
    
    let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .MediumStyle
        return formatter
    }()
    
    func updateToTrack(track: Track?, index: Int = 0) {
        if let track = track {
            var title = "\(index)) "
            if let date = track.startDate() {
                title += dateFormatter.stringFromDate(date)
            }
            if let date = track.endDate() {
                title += " to " + dateFormatter.stringFromDate(date)
            }
            var subtitle = "\(track.activity.confidence)"
            if track.activity.stationary { subtitle += ",st" }
            if track.activity.cycling { subtitle += ",bk" }
            if track.activity.walking { subtitle += ",wk" }
            if track.activity.running { subtitle += ",rn" }
            if track.activity.automotive { subtitle += ",aut" }
            if track.activity.unknown { subtitle += ",un" }
            let horizontal = track.locations.objectsWithPredicate(NSPredicate(value: true)).maxOfProperty("horizontalAccuracy")?.intValue ?? -1
            let vertical = track.locations.objectsWithPredicate(NSPredicate(value: true)).maxOfProperty("verticalAccuracy")?.intValue ?? -1
            subtitle += "\(horizontal) \(vertical)"
            subtitle += ",\(Int(round(track.length)))m,\(Int(round(track.length)))s,\(round(track.length/1000/(track.duration/3600)))kmh"
            subtitle += ",fy:\(round(track.flightDistance() ?? 0))m"
            
            subtitle += " " + dateFormatter.stringFromDate(track.activity.startDate)
            
            fromLabel.text = title
            toLabel.text = subtitle
        }
        mapView.track = track
    }
}






import MapKit

class TrackMapView: MKMapView {
    
    var track: Track? {
        didSet {
            if let track = track {
                delegate = self
                updateToTrack(track)
            } else {
                removeOverlays(overlays)
            }
        }
    }
    
    func updateToTrack(track: Track) {
        removeOverlays(overlays)
        
        let overlay = polylineForLocationPoints(track.locations)
        zoomToTrack(track)
        addOverlay(overlay, level: .AboveRoads)
    }
    
    private func polylineForLocationPoints(locationPoints: RLMArray) -> MKPolyline {
        var coordinates = coordinatesForLocationPoints(locationPoints)
        return MKPolyline(coordinates: &coordinates, count: coordinates.count)
    }
    
    private func coordinatesForLocationPoints(locationPoints: RLMArray) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
        for rlmLocationPoint in locationPoints {
            if let locationPoint = rlmLocationPoint as? TrackLocation {
                coordinates.append(locationPoint.coordinate())
            }
        }
        return coordinates
    }
    
    private func zoomToTrack(track: Track) {
        
        var zoomRect: MKMapRect? = nil
        for location in track.locations
        {
            if let location = location as? TrackLocation {
                let annotationPoint = location.coordinate().mapPoint()
                let pointRect = MKMapRect(origin: annotationPoint, size: MKMapSize(width: 0, height: 0))
                if let _zoomRect = zoomRect {
                    zoomRect = MKMapRectUnion(_zoomRect, pointRect)
                } else {
                    zoomRect = pointRect
                }
            }
        }
        if let zoomRect = zoomRect {
            setVisibleMapRectPadded(zoomRect)
        }
    }
    
}

extension TrackMapView: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = Styler.tintColor()
            renderer.lineWidth = 4
            return renderer
        }
        assert(false,"Unexpected overlay!")
        return MKOverlayRenderer()
    }
}

extension MKMapRect {
    
    var center: MKMapPoint {
        return MKMapPoint(x: self.origin.x + self.size.width / 2, y: self.origin.y + self.size.height/2)
    }
    
    var minimumRect: MKMapRect {
        let currentSize = fmax(self.size.width, self.size.height)
        let size = currentSize * 1.1
        let newOrigin = MKMapPoint(x: center.x - size/2, y: center.y - size/2)
        let newSize = MKMapSize(width: size, height: size)
        return MKMapRect(origin: newOrigin, size: newSize)
    }
}

extension MKMapView {
    
    func setVisibleMapRectPadded(mapRect: MKMapRect) {
        let padding: CGFloat = 10
        let edgePadding = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        setVisibleMapRect(mapRect.minimumRect, edgePadding: edgePadding, animated: false)
    }
}


extension CLLocationCoordinate2D {
    
    func mapPoint() -> MKMapPoint {
        return MKMapPointForCoordinate(self)
    }
}

