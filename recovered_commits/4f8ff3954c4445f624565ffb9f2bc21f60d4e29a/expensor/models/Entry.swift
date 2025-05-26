import Foundation
import SwiftUI

struct User: Codable, Identifiable {
    var id: String
    var email: String?
}

struct Company: Codable, Identifiable {
    var id: String
    var userId: String // Reference to Supabase auth.users
    var name: String
    var cif: String?
    
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
        self.cif = try container.decodeIfPresent(String.self, forKey: .cif)
    }
}

struct Item: Identifiable, Codable, Equatable {
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

struct Totals: Codable {
    var total: Double
    var paidCard: Double?
    var paidCash: Double?
    
    enum CodingKeys: String, CodingKey {
        case total, paidCard = "paid_card", paidCash = "paid_cash"
    }
}

struct Category: Identifiable, Codable {
    var id: String
    var userId: String // Reference to Supabase auth.users
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

struct ReceiptEntry: Identifiable, Codable {
    let id: String
    let userId: String
    let companyId: String
    let date: Date
    let categoryId: String?
    let total: Double
    let paidCard: Double?
    let paidCash: Double?
    let createdAt: Date?
    let updatedAt: Date?
    
    let company: Company?
    let category: Category?
    var items: [Item]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case companyId = "company_id"
        case date
        case categoryId = "category_id"
        case total
        case paidCard = "paid_card"
        case paidCash = "paid_cash"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case company = "companies"
        case category = "categories"
        case items
    }

    init(
        id: String,
        userId: String,
        companyId: String,
        date: Date,
        categoryId: String?,
        total: Double,
        paidCard: Double? = nil,
        paidCash: Double? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        company: Company? = nil,
        category: Category? = nil,
        items: [Item]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.companyId = companyId
        self.date = date
        self.categoryId = categoryId
        self.total = total
        self.paidCard = paidCard
        self.paidCash = paidCash
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.company = company
        self.category = category
        self.items = items
    }
}


// Tax model to match the database structure
struct Tax: Identifiable, Codable {
    var id: String = UUID().uuidString
    var receiptEntryId: String
    var name: String
    var value: Double
    
    enum CodingKeys: String, CodingKey {
        case id, receiptEntryId = "receipt_entry_id", name, value
    }
}

// Dummy subviews
struct ReceiptImageSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    @Binding var showSourcePicker: Bool
    @Binding var imageSourceType: UIImagePickerController.SourceType
    var body: some View { EmptyView() }
}

struct ReceiptCompanySection: View {
    @Binding var company: Company
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Company Name", text: $company.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if company.cif != nil {
                TextField("CIF", text: Binding(
                    get: { company.cif ?? "" },
                    set: { company.cif = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(.vertical)
    }
}

struct ReceiptDateCategorySection: View {
    @Binding var date: Date
    @Binding var selectedCategory: Category?
    @Binding var showCategoryPicker: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DatePicker("Date", selection: $date, displayedComponents: .date)
            Button {
                showCategoryPicker = true
            } label: {
                HStack {
                    Text(selectedCategory?.name ?? "Select Category")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
        }
        .padding(.vertical)
    }
}

struct ReceiptItemsSection: View {
    @Binding var items: [Item]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Items")
                .font(.headline)
            ForEach($items) { $item in
                HStack {
                    TextField("Name", text: $item.name)
                    TextField("Qty", value: $item.quantity, formatter: NumberFormatter())
                        .frame(width: 40)
                    TextField("Unit Price", value: $item.unitPrice, formatter: NumberFormatter())
                        .frame(width: 80)
                    TextField("Total", value: $item.total, formatter: NumberFormatter())
                        .frame(width: 80)
                }
            }
            Button("Add Item") {
                items.append(Item(name: "", quantity: 1, unitPrice: 0, total: 0))
            }
        }
        .padding(.vertical)
    }
}

struct ReceiptTaxesSection: View {
    @Binding var taxes: [String: Double]
    @State private var newTaxName = ""
    @State private var newTaxValue: Double = 0
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Taxes")
                .font(.headline)
            ForEach(Array(taxes.keys), id: \.self) { key in
                HStack {
                    Text(key)
                    Spacer()
                    TextField("Value", value: Binding(
                        get: { taxes[key] ?? 0 },
                        set: { taxes[key] = $0 }
                    ), formatter: NumberFormatter())
                        .frame(width: 80)
                }
            }
            HStack {
                TextField("Tax Name", text: $newTaxName)
                TextField("Value", value: $newTaxValue, formatter: NumberFormatter())
                    .frame(width: 80)
                Button("Add") {
                    if !newTaxName.isEmpty {
                        taxes[newTaxName] = newTaxValue
                        newTaxName = ""
                        newTaxValue = 0
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

struct CategoryPickerViewFixed: View {
    @Binding var selectedCategory: Category?
    var body: some View { EmptyView() }
}

// Profile model
struct Profile: Decodable {
    let id: String
    let first_name: String
    let last_name: String
    let currency: String
}

enum AuthResultState: Equatable {
    case none
    case success
    case failure(String)
}
