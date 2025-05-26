//
//  Entry.swift
//  expensor
//
//  Created by Sebastian Pavel on 18.05.2025.
//

import Foundation

struct ReceiptEntry: Codable, Identifiable {
    var id: String?
    var company: Company
    var items: [Item]
    var totals: Totals
    var taxes: [String: Double]
    
    // Make id non-optional for Identifiable
    var identifier: String {
        id ?? UUID().uuidString
    }
}

struct Company: Codable {
    var name: String
    var cif: String
}

struct Item: Codable {
    var name: String
    var quantity: Int
    var unitPrice: Double
    var total: Double

    enum CodingKeys: String, CodingKey {
        case name, quantity, total
        case unitPrice = "unit_price"
    }
}

struct Totals: Codable {
    var total: Double
    var paidCard: Double?
    var paidCash: Double?

    enum CodingKeys: String, CodingKey {
        case total
        case paidCard = "paid_card"
        case paidCash = "paid_cash"
    }
}
