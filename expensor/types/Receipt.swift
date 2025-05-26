//import Foundation
//
//// Assuming ReceiptEntry, Company, Item, and Category structs are defined as previously discussed.
//// Specifically, ensure `date`, `createdAt`, and `updatedAt` are `Date` types in ReceiptEntry,
//// and you have a `JSONDecoder` configured for date parsing.
//
//struct ReceiptEntry: Identifiable, Codable {
//    var id: String
//    var userId: String
//    var companies: Company
//    var items: [Item]
//    var taxes: [String: Double]?
//    var date: Date // Changed to Date type
//    var paidCash: Double?
//    var paidCard: Double?
//    var categories: Category?
//    var total: Double
//    var categoryId: String
//    var companyId: String
//    var createdAt: Date?
//    var updatedAt: Date?
//
//    enum CodingKeys: String, CodingKey {
//        case id, userId = "user_id", companies, items, taxes, date, categories, categoryId = "category_id", companyId = "company_id",
//             paidCash = "paid_cash", paidCard = "paid_card", total
//        case createdAt = "created_at", updatedAt = "updated_at"
//    }
//
//    // init and other methods for ReceiptEntry
//    init(
//        id: String,
//        userId: String,
//        companies: Company,
//        items: [Item],
//        taxes: [String: Double]?,
//        date: Date,
//        categories: Category?,
//        categoryId: String = "",
//        companyId: String = "",
//        paidCash: Double? = nil,
//        paidCard: Double? = nil,
//        total: Double = 0.0,
//        createdAt: Date?,
//        updatedAt: Date?
//    ) {
//        self.id = id
//        self.userId = userId
//        self.companies = companies
//        self.items = items
//        self.total = total
//        self.taxes = taxes
//        self.date = date
//        self.categories = categories
//        self.categoryId = categoryId
//        self.companyId = companyId
//        self.paidCash = paidCash
//        self.paidCard = paidCard
//        self.createdAt = createdAt
//        self.updatedAt = updatedAt
//    }
//}
