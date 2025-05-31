import Foundation
import SwiftUI

struct Company: Codable, Identifiable {
    var id: String
    var userId: String
    var name: String
    var cif: String? // Make this optional to handle null values
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", name, cif
    }
    
    init(id: String = UUID().uuidString, userId: String = "", name: String, cif: String? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.cif = cif
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? ""
        self.name = try container.decode(String.self, forKey: .name)
        self.cif = try container.decodeIfPresent(String.self, forKey: .cif) // Changed to decodeIfPresent
    }
}

struct Item: Identifiable, Codable {
    var id: String
    var name: String
    var quantity: Int
    var unitPrice: Double
    var total: Double
    var category: Category?
    
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, unitPrice = "unit_price", total, category
    }
    
    init(id: String = UUID().uuidString, name: String, quantity: Int, unitPrice: Double, total: Double, category: Category? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.total = total
        self.category = category
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.name = try container.decode(String.self, forKey: .name)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
        self.unitPrice = try container.decode(Double.self, forKey: .unitPrice)
        self.total = try container.decode(Double.self, forKey: .total)
        self.category = try container.decodeIfPresent(Category.self, forKey: .category)
    }
}

struct Category: Identifiable, Codable {
    var id: String
    var userId: String
    var name: String
    var icon: String
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", name, icon
    }
    
    init(id: String = UUID().uuidString, userId: String = "", name: String, icon: String) {
        self.id = id
        self.userId = userId
        self.name = name
        self.icon = icon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? ""
        self.name = try container.decode(String.self, forKey: .name)
        self.icon = try container.decode(String.self, forKey: .icon)
    }
}

struct Tax: Identifiable, Codable {
    var id: String = UUID().uuidString
    var receiptEntryId: String
    var name: String
    var value: Double
    
    enum CodingKeys: String, CodingKey {
        case id, receiptEntryId = "receipt_entry_id", name, value
    }
}

struct ReceiptEntry: Identifiable, Codable {
    var id: String
    var userId: String
    var companies: Company
    var items: [Item]
    var taxes: [String: Double]?
    var date: Date
    var paidCash: Double?
    var paidCard: Double?
    var categories: Category?
    var total: Double
    var createdAt: Date
    var updatedAt: Date

    // Transient properties to indicate search match source
    var matchedName: Bool = false
    var matchedItem: Bool = false
    var matchedCategory: Bool = false
    var matchedCategoryName: String? = nil // New property to store the matched category name

    // Memberwise initializer for preview and manual creation
    init(id: String,
         userId: String,
         companies: Company,
         items: [Item],
         taxes: [String: Double]?,
         date: Date,
         paidCash: Double?,
         paidCard: Double?,
         categories: Category?,
         total: Double,
         createdAt: Date,
         updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.companies = companies
        self.items = items
        self.taxes = taxes
        self.date = date
        self.paidCash = paidCash
        self.paidCard = paidCard
        self.categories = categories
        self.total = total
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.matchedName = false
        self.matchedItem = false
        self.matchedCategory = false
        self.matchedCategoryName = nil // Initialize the new property
    }

    // Manual Codable implementation to exclude transient properties
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", companies, items, taxes, date, paidCash = "paid_cash", paidCard = "paid_card", categories, total, createdAt = "created_at", updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        companies = try container.decode(Company.self, forKey: .companies)
        items = try container.decode([Item].self, forKey: .items)
        taxes = try container.decodeIfPresent([String: Double].self, forKey: .taxes)
        date = try container.decode(Date.self, forKey: .date)
        paidCash = try container.decodeIfPresent(Double.self, forKey: .paidCash)
        paidCard = try container.decodeIfPresent(Double.self, forKey: .paidCard)
        categories = try container.decodeIfPresent(Category.self, forKey: .categories)
        total = try container.decode(Double.self, forKey: .total)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        // Initialize transient properties to default values
        matchedName = false
        matchedItem = false
        matchedCategory = false
        matchedCategoryName = nil // Initialize the new transient property
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(companies, forKey: .companies)
        try container.encode(items, forKey: .items)
        try container.encodeIfPresent(taxes, forKey: .taxes)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(paidCash, forKey: .paidCash)
        try container.encodeIfPresent(paidCard, forKey: .paidCard)
        try container.encodeIfPresent(categories, forKey: .categories)
        try container.encode(total, forKey: .total)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        // Do not encode transient properties
    }
}

// MARK: - JSON Decoding Helper
extension JSONDecoder {
    static var receiptDecoder: JSONDecoder {
        let decoder = JSONDecoder()

        // Configure date decoding for ISO 8601 format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS+00:00"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        // Fallback formatter for dates without microseconds
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss+00:00"
        fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
        fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = formatter.date(from: dateString) {
                return date
            } else if let date = fallbackFormatter.date(from: dateString) {
                return date
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
        }

        return decoder
    }
}

// MARK: - Usage Example
func decodeReceipts(from jsonData: Data) throws -> [ReceiptEntry] {
    let decoder = JSONDecoder.receiptDecoder
    return try decoder.decode([ReceiptEntry].self, from: jsonData)
}
