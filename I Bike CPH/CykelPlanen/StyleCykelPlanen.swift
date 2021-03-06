//
//  StyleCykelPlanen.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 30/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

import UIKit

extension UIColor {
    
    class func orange() -> UIColor {
        return UIColor(red: 255/255, green: 102/255, blue: 0/255, alpha: 1)
    }
}

class Styler: NSObject, StyleProtocol {
    
    class func backgroundColor() -> UIColor {
        return .whiteColor()
    }
    
    class func tintColor() -> UIColor {
        return .orange()
    }
    
    class func foregroundColor() -> UIColor {
        return .darkGrayColor()
    }

    class func foregroundSecondaryColor() -> UIColor {
        return .lightGrayColor()
    }
    
    class func navigationBarTintColor() -> UIColor {
        return .orange()
    }
    
    class func navigationBarContentTintColor() -> UIColor {
        return .whiteColor()
    }
    
    class func logo() -> UIImage? {
        return UIImage(named: "Logo")
    }
}