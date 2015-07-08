//
//  RouteTypeToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

protocol RouteTypeToolbarDelegate {
    func didChangeType(type: RouteType)
}

class RouteTypeToolbarView: ToolbarView {

    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    private var type: RouteType {
        get {
            return RouteTypeHandler.instance.type
        }
        set {
            RouteTypeHandler.instance.type = newValue
            updateUI()
            delegate?.didChangeType(RouteTypeHandler.instance.type)
        }
    }
    private let validTypes = RouteType.validTypes()
    private var buttons: [UIButton] {
        return [leftButton, centerButton, rightButton]
    }
    
    var delegate: RouteTypeToolbarDelegate?
    
    override func setup() {
        super.setup()
        
        updateUI()
    }
    
    private func validType(index: Int) -> RouteType? {
        return index < validTypes.count ? validTypes[index] : nil
    }
    
    @IBAction func didTapLeftButton(sender: AnyObject) {
        type = validType(0) ?? .Regular
        
    }
    @IBAction func didTapCenterButton(sender: AnyObject) {
        type = validType(1) ?? .Regular
    }
    @IBAction func didTapRightButton(sender: AnyObject) {
        type = validType(2) ?? .Regular
    }
    
    func updateUI() {
        for (index, button) in enumerate(buttons) {
            if let type = validType(index) {
                button.enabled = true
                let type = validTypes[index]
                let typeViewModel = RouteTypeViewModel(type: type)
                // Set image
                button.setImage(typeViewModel.iconImage, forState: .Normal)
                // Set selection
                button.tintColor = typeViewModel.selected ? Styler.tintColor() : Styler.foregroundColor()
                continue
            }
            button.enabled = false
            button.setImage(nil, forState: .Normal)
            button.tintColor = Styler.foregroundColor()
        }
    }
}
