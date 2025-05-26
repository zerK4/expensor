//
//  NumberFormatter+Currency.swift
//  expensor
//
//  Created for expensor
//

import Foundation

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ","
        return formatter
    }()
}