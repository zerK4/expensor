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
    var categoryId: String
    var companyId: String
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", companies, items, taxes, date, categories, categoryId = "category_id", companyId = "company_id"
        case paidCash = "paid_cash", paidCard = "paid_card", total
        case createdAt = "created_at", updatedAt = "updated_at"
    }

    init(
        id: String,
        userId: String,
        companies: Company,
        items: [Item],
        taxes: [String: Double]?,
        date: Date,
        categories: Category?,
        categoryId: String = "",
        companyId: String = "",
        paidCash: Double? = nil,
        paidCard: Double? = nil,
        total: Double = 0.0,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.companies = companies
        self.items = items
        self.total = total
        self.taxes = taxes
        self.date = date
        self.categories = categories
        self.categoryId = categoryId
        self.companyId = companyId
        self.paidCash = paidCash
        self.paidCard = paidCard
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
