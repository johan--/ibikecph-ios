//
//  IconLabelTableViewCell.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit
import NibDesignable

class IconLabelTableViewCell: NibDesignableTableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    var enabled: Bool = true {
        didSet {
            label.enabled = enabled
            iconImageView.tintAdjustmentMode = enabled ? .Normal : .Dimmed
        }
    }
    
    func configure(text: String, textColor: UIColor = Styler.foregroundColor(), icon: UIImage? = nil) {
        
        label.textColor = textColor
        label.text = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        iconImageView.image = icon
    }
    
    func configure(item: SearchListItem) {
        var icon: UIImage?
        if let favorite = item as? FavoriteItem {
            icon = FavoriteTypeViewModel(type: favorite.origin).iconImage
        } else if item is HistoryItem {
            icon = UIImage(named: "findHistory")
        }
        configure(item.name, icon: icon)
    }
}
