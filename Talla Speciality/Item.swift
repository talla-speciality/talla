//
//  Item.swift
//  Talla Speciality
//
//  Created by Ahmad AlBuainain on 15/3/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
