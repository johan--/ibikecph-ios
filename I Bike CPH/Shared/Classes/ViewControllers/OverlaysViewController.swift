//
//  OverlaysViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class OverlaysViewController: UIViewController {

    private let cellID = "OverlayCellID"
    
    private let items: [OverlayType] = {
        if Macro.instance().isCykelPlanen {
            return [
//               .CycleSuperHighways,
                .BikeServiceStations
            ]
        }
        if Macro.instance().isIBikeCph {
            return [
                .HarborRing,
                .GreenPaths
            ]
        }
        return []
        
        }()
    
    private var observerTokens = [AnyObject]()
    
    deinit {
        unobserve()
    }
    
    private func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "map_overlays".localized
        
        observerTokens.append(NotificationCenter.observe(overlaysUpdatedNotification) { [weak self] notification in
            // Find relevant table view in messy Nib labyrinth and update it
            if let view = self?.view {
                for v: UIView in view.subviews {
                    if let tv = v as? UITableView {
                        tv.reloadData()
                    }
                }
            }
        })
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}


extension OverlaysViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as IconLabelTableViewCell
        let item = items[indexPath.row]
        
        let title = OverlaysManager.sharedInstance.titleForOverlay(item)
        let iconImage = OverlaysManager.sharedInstance.iconImageForOverlay(item)
        let selected = OverlaysManager.sharedInstance.isOverlaySelected(item)
        
        cell.configure(title, icon: iconImage)
        cell.accessoryType = selected ? .Checkmark : .None
        
        return cell
    }
}

extension OverlaysViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView .deselectRowAtIndexPath(indexPath, animated: true)
        
        let item = items[indexPath.row]
        let selected = OverlaysManager.sharedInstance.isOverlaySelected(item)
        OverlaysManager.sharedInstance.selectOverlay(!selected, type: item)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
}