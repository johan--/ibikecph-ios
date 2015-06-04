//
//  TrackTableViewCell.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 16/03/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class TrackTableViewCell: UITableViewCell {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var topAddressLabel: UILabel!
    @IBOutlet weak var bottomAddressLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    private let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    
    let hourMinutesFormatter = HourMinuteFormatter()
    
    lazy var numberFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.alwaysShowsDecimalSeparator = true
        formatter.minimumIntegerDigits = 1 // "0.0" instead of ".0"
        return formatter
    }()
    
    func updateToTrack(track: Track?) {
        if let track = track where !track.invalidated {
            var time = ""
            if let date = track.startDate() {
                time += dateFormatter.stringFromDate(date)
            }
            if let date = track.endDate() {
                time += " - " + dateFormatter.stringFromDate(date)
            }
            timeLabel.text = time
            
            // Duration in minutes
            let duration = track.duration
            durationLabel.text = hourMinutesFormatter.string(seconds: duration)
            // Distance in km
            let distance = track.length
            distanceLabel.text = (numberFormatter.stringFromNumber(distance / 1000) ?? "") + " " + "unit_km".localized
            
            topAddressLabel.text = track.end == "" ? "–" : track.end
            bottomAddressLabel.text = track.start == "" ? "–" : track.start
        } else {
            timeLabel.text = "–"
            durationLabel.text = hourMinutesFormatter.string(seconds: 0)
            distanceLabel.text = "0 " + "unit_km".localized
            topAddressLabel.text = "–"
            bottomAddressLabel.text = "–"
        }
        SMTranslation.translateView(contentView)
    }
}
