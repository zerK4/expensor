//
//  NumberFormatter+Currency.swift
//  expensor
//
//  Created for expensor
//

import Foundation

extension NumberFormatter {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter
    }()
}
