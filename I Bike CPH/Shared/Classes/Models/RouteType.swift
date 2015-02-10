//
//  RouteType.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 08/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import Foundation

enum RouteType {
    case Regular
    case Cargo
    
    var localizedDescription: String {
        switch self {
            case .Regular: return SMTranslation.decodeString("bike_type_1")
            case .Cargo: return SMTranslation.decodeString("bike_type_2")
        }
    }
}