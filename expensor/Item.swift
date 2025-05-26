//
//  Item.swift
//  expensor
//
//  Created by Sebastian Pavel on 26.05.2025.
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
