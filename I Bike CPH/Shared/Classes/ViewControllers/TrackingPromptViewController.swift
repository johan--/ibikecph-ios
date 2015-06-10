//
//  TrackingPromptViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 17/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit
import PSTAlertController

class TrackingPromptViewController: SMTranslatedViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "tracking".localized
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        dismiss()
    }
    @IBAction func EnableTrackingButtonTapped(sender: UIButton) {
        if !UserHelper.loggedIn() {
            let alertController = PSTAlertController(title: "", message: "log_in_to_track_prompt".localized, preferredStyle: .Alert)
            alertController.addCancelActionWithHandler(nil)
            let loginAction = PSTAlertAction(title: "log_in".localized) { [weak self] action in
                self?.performSegueWithIdentifier("trackingPromptToLogin", sender: self)
            }
            alertController.addAction(loginAction)
            alertController.showWithSender(self, controller: self, animated: true, completion: nil)
            return
        }
        settings.tracking.on = true
        dismiss()
    }
}
