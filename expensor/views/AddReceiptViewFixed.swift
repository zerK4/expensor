import SwiftUI
import PhotosUI

struct AddReceiptViewFixed: View {
    @Environment(\.dismiss) private var dismiss
    @State private var newReceipt = ReceiptEntry(
        id: UUID().uuidString,
        company: Company(name: "", cif: ""),
        items: [Item(name: "", quantity: 1, unitPrice: 0, total: 0)],
        totals: Totals(total: 0),
        taxes: [:],
        date: Date(), // Added initialization
        category: nil // Added initialization
    )
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showSourcePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedPaymentMethod: PaymentMethod? = nil
    @State private var selectedCategory: Category? = nil
    @State private var date = Date()
    @State private var showCategoryPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ReceiptImageSection(selectedImage: $selectedImage, showImagePicker: $showImagePicker, showSourcePicker: $showSourcePicker, imageSourceType: $imageSourceType)
                        .padding(.top)
                    ReceiptCompanySection(company: $newReceipt.company)
                    ReceiptDateCategorySection(date: $date, selectedCategory: $selectedCategory, showCategoryPicker: $showCategoryPicker)
                    ReceiptItemsSection(items: $newReceipt.items)
                    ReceiptPaymentSection(selectedPaymentMethod: $selectedPaymentMethod, totals: $newReceipt.totals)
                    ReceiptTaxesSection(taxes: $newReceipt.taxes)
                    Button(action: saveReceipt) {
                        Text("Save Receipt")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.vertical)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Add Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: imageSourceType)
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerViewFixed(selectedCategory: $selectedCategory)
            }
        }
    }
    
    private func saveReceipt() {
        // Compose the receipt data
        let updatedReceipt = ReceiptEntry(
            id: newReceipt.id,
            company: newReceipt.company,
            items: newReceipt.items,
            totals: newReceipt.totals,
            taxes: newReceipt.taxes,
            date: date,
            category: selectedCategory
        )
        newReceipt = updatedReceipt // Update the entire struct
        // Print all data to console
        print("--- Saved Receipt ---")
        print("ID: \(updatedReceipt.id)")
        print("Date: \(updatedReceipt.date)")
        print("Company: \(updatedReceipt.company.name), CIF: \(updatedReceipt.company.cif)") 
        print("Category: \(updatedReceipt.category?.name ?? "-")")
        print("Items: \(updatedReceipt.items)")
        print("Totals: \(updatedReceipt.totals)")
        print("Taxes: \(updatedReceipt.taxes)")
        print("Payment Method: \(selectedPaymentMethod?.rawValue ?? "-")")
        if let _ = selectedImage {
            print("Image: selected")
        } else {
            print("Image: none")
        }
        dismiss()
    }
}

// MARK: - Subviews

private struct ReceiptImageSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    @Binding var showSourcePicker: Bool
    @Binding var imageSourceType: UIImagePickerController.SourceType
    
    var body: some View {
        VStack(spacing: 8) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 220)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 220)
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            Button(action: { showSourcePicker = true }) {
                Label(selectedImage == nil ? "Add Photo" : "Change Photo", systemImage: "camera")
            }
            .confirmationDialog("Select Photo", isPresented: $showSourcePicker) {
                Button("Take Photo") {
                    imageSourceType = .camera
                    showImagePicker = true
                }
                Button("Choose from Library") {
                    imageSourceType = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

private struct ReceiptCompanySection: View {
    @Binding var company: Company
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Company Information").font(.headline)
            TextField("Company Name", text: $company.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("CIF", text: $company.cif)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

private struct ReceiptDateCategorySection: View {
    @Binding var date: Date
    @Binding var selectedCategory: Category?
    @Binding var showCategoryPicker: Bool
    var body: some View {
        HStack(spacing: 16) {
            DatePicker("Date", selection: $date, displayedComponents: .date)
            Spacer()
            Button(action: { showCategoryPicker = true }) {
                HStack {
                    Text(selectedCategory?.name.capitalized ?? "Select Category")
                    Image(systemName: "chevron.down")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

private struct ReceiptItemsSection: View {
    @Binding var items: [Item]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Items").font(.headline)
            ForEach(Array(items.enumerated()), id: \.offset) { index, _ in
                ReceiptItemRow(item: $items[index], canBeRemoved: items.count > 1) {
                    if items.count > 1 { items.remove(at: index) }
                }
            }
            Button(action: {
                items.append(Item(name: "", quantity: 1, unitPrice: 0, total: 0))
            }) {
                Label("Add Item", systemImage: "plus.circle.fill")
            }
        }
    }
}

private struct ReceiptItemRow: View {
    @Binding var item: Item
    var canBeRemoved: Bool
    var onRemove: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField("Item Name", text: $item.name)
                if canBeRemoved {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle.fill").foregroundColor(.red)
                    }
                }
            }
            HStack {
                Stepper("Qty: \(item.quantity)", value: $item.quantity, in: 1...100)
                Spacer()
                TextField("Unit Price", value: $item.unitPrice, formatter: NumberFormatter.currencyOrDefault)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
            }
            Text("Total: \(String(format: "%.2f", item.unitPrice * Double(item.quantity)))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

private struct ReceiptPaymentSection: View {
    @Binding var selectedPaymentMethod: PaymentMethod?
    @Binding var totals: Totals
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment Method").font(.headline)
            HStack(spacing: 16) {
                PaymentMethodButton(method: .card, selected: selectedPaymentMethod == .card) {
                    selectedPaymentMethod = selectedPaymentMethod == .card ? nil : .card
                    if selectedPaymentMethod == .card {
                        totals.paidCard = totals.total
                        totals.paidCash = nil
                    } else {
                        totals.paidCard = nil
                    }
                }
                PaymentMethodButton(method: .cash, selected: selectedPaymentMethod == .cash) {
                    selectedPaymentMethod = selectedPaymentMethod == .cash ? nil : .cash
                    if selectedPaymentMethod == .cash {
                        totals.paidCash = totals.total
                        totals.paidCard = nil
                    } else {
                        totals.paidCash = nil
                    }
                }
            }
        }
    }
}

private struct PaymentMethodButton: View {
    let method: PaymentMethod
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: method == .card ? "creditcard.fill" : "banknote.fill")
                    .font(.system(size: 24))
                Text(method == .card ? "Card" : "Cash")
                    .font(.subheadline)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? (method == .card ? Color.blue.opacity(0.2) : Color.green.opacity(0.2)) : Color.gray.opacity(0.1))
            .foregroundColor(selected ? (method == .card ? .blue : .green) : .gray)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? (method == .card ? Color.blue : Color.green) : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

private struct ReceiptTaxesSection: View {
    @Binding var taxes: [String: Double]
    @State private var newTaxName: String = ""
    @State private var newTaxValue: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Taxes").font(.headline)
            ForEach(Array(taxes.keys), id: \.self) { key in
                HStack {
                    Text(key)
                    Spacer()
                    Text("\(String(format: "%.2f", taxes[key] ?? 0))")
                    Button(action: { taxes.removeValue(forKey: key) }) {
                        Image(systemName: "minus.circle.fill").foregroundColor(.red)
                    }
                }
            }
            HStack {
                TextField("Tax Name", text: $newTaxName)
                TextField("Value", text: $newTaxValue)
                    .keyboardType(.decimalPad)
                Button("Add") {
                    if let value = Double(newTaxValue), !newTaxName.isEmpty {
                        taxes[newTaxName] = value
                        newTaxName = ""
                        newTaxValue = ""
                    }
                }
            }
        }
    }
}

private struct CategoryPickerViewFixed: View {
    @Binding var selectedCategory: Category?
    @Environment(\.dismiss) private var dismiss
    // You should provide your categories here
    let categories: [Category] = [
        Category(id: UUID(), name: "food", icon: "fork.knife"),
        Category(id: UUID(), name: "groceries", icon: "cart"),
        Category(id: UUID(), name: "gas", icon: "fuelpump"),
        Category(id: UUID(), name: "house", icon: "house"),
        Category(id: UUID(), name: "entertainment", icon: "film"),
        Category(id: UUID(), name: "shopping", icon: "cart"),
        Category(id: UUID(), name: "tech", icon: "desktopcomputer"),
        Category(id: UUID(), name: "clothing", icon: "tshirt"),
        Category(id: UUID(), name: "coffee", icon: "cup.and.saucer"),
    ]
    var body: some View {
        NavigationView {
            List(categories, id: \.id) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    HStack {
                        Text(category.name.capitalized)
                        if selectedCategory?.id == category.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

extension NumberFormatter {
    static var currencyOrDefault: NumberFormatter {
        if let formatter = try? NumberFormatter.value(forKey: "currency") as? NumberFormatter {
            return formatter
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }
}

// ...existing code...
