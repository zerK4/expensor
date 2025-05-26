import Foundation
import SwiftUI
// Add these stubs to resolve missing type errors

struct Company {
    var name: String
    var cif: String
}

struct Item: Identifiable {
    var id = UUID()
    var name: String
    var quantity: Int
    var unitPrice: Double
    var total: Double
}

struct Totals {
    var total: Double
    var paidCard: Double?
    var paidCash: Double?
}

struct Category: Identifiable {
    var id = UUID()
    var name: String
}

struct ReceiptEntry {
    var id: String
    var company: Company
    var items: [Item]
    var totals: Totals
    var taxes: [String: Double]
    var date: Date
    var category: Category?
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
    var body: some View { EmptyView() }
}

struct ReceiptDateCategorySection: View {
    @Binding var date: Date
    @Binding var selectedCategory: Category?
    @Binding var showCategoryPicker: Bool
    var body: some View { EmptyView() }
}

struct ReceiptItemsSection: View {
    @Binding var items: [Item]
    var body: some View { EmptyView() }
}

struct ReceiptTaxesSection: View {
    @Binding var taxes: [String: Double]
    var body: some View { EmptyView() }
}

struct CategoryPickerViewFixed: View {
    @Binding var selectedCategory: Category?
    var body: some View { EmptyView() }
}
