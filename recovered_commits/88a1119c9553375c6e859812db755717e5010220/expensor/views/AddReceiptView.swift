import SwiftUI

// MARK: - Main View
struct AddReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Receipt image
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showSourcePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isProcessingImage = false

    // Receipt data
    @State private var company = Company(id: "", userId: "", name: "", cif: "")
    @State private var date = Date()
    @State private var selectedCategory: Category? = nil
    @State private var showCategoryPicker = false
    @State private var items: [Item] = [Item(id: UUID().uuidString, name: "", quantity: 1, unitPrice: 0, total: 0)]
    @State private var taxes: [String: Double] = ["TVA 9%": 0]
    @State private var paymentMethod: PaymentMethod = .card
    @State private var total: Double = 0
    @State private var paidCard: Double = 0
    @State private var paidCash: Double = 0

    // Sample categories
    let categories: [Category] = [
        Category(id: "1", userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "food", icon: "🍔"),
        Category(id: "2", userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "transport", icon: "🚕"),
        Category(id: "3", userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "entertainment", icon: "🎬"),
        Category(id: "4", userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "shopping", icon: "🛍️"),
        Category(id: "5", userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "utilities", icon: "💡"),
        Category(id: "6", userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "health", icon: "💊")
    ]

    enum PaymentMethod: String, CaseIterable {
        case card = "Card"
        case cash = "Cash"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Image section
                        imageSection

                        // Form sections
                        Group {
                            companySection
                            dateAndCategorySection
                            itemsSection
                            paymentSection
                            totalSection
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 100)
                }

                // Save button at the bottom
                VStack {
                    Spacer()
                    saveButton
                }
            }
            .navigationTitle("Add Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: imageSourceType)
            }
            .actionSheet(isPresented: $showSourcePicker) {
                ActionSheet(
                    title: Text("Select Photo Source"),
                    buttons: [
                        .default(Text("Camera")) {
                            imageSourceType = .camera
                            showImagePicker = true
                        },
                        .default(Text("Photo Library")) {
                            imageSourceType = .photoLibrary
                            showImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory, categories: categories)
            }
        }
    }

    // MARK: - UI Components

    private var imageSection: some View {
        VStack(spacing: 16) {
            if let image = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)

                    Button {
                        selectedImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.primary)
                            .background(Circle().fill(Color(UIColor.systemBackground)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 8)
                }

                if isProcessingImage {
                    ProgressView("Processing receipt...")
                        .padding()
                }
            } else {
                Button {
                    showSourcePicker = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "camera")
                            .font(.system(size: 30))
                        Text("Take or Upload Receipt Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.primary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }

    private var companySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Company Information")
                    .font(.headline)
                    .padding(.bottom, 4)

                TextField("Company Name", text: $company.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 8)

                TextField("CIF/Fiscal Code", text: $company.cif)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private var dateAndCategorySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Date & Category")
                    .font(.headline)
                    .padding(.bottom, 4)

                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .padding(.bottom, 8)

                Button {
                    showCategoryPicker = true
                } label: {
                    HStack {
                        if let category = selectedCategory {
                            Text("\(category.icon) \(category.name)")
                                .foregroundColor(.primary)
                        } else {
                            Text("Select Category")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private var itemsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Items")
                        .font(.headline)
                    Spacer()
                    Button {
                        withAnimation {
                            items.append(Item(id: UUID().uuidString, name: "", quantity: 1, unitPrice: 0, total: 0))
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }

                ForEach(Array(items.enumerated()), id: \.element.id) { index, _ in
                    ItemRow(
                        item: Binding(
                            get: { items[index] },
                            set: { items[index] = $0 }
                        ),
                        showDeleteButton: items.count > 1,
                        onDelete: {
                            if items.count > 1 {
                                items.remove(at: index)
                            }
                        },
                        updateTotal: { newUnitPrice, newQuantity in
                            items[index].total = newUnitPrice * Double(newQuantity)
                            calculateTotal()
                        }
                    )

                    if index < items.count - 1 {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private var taxesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Taxes")
                    .font(.headline)

                ForEach(Array(taxes.keys.sorted()), id: \.self) { key in
                    TaxRow(
                        taxName: key,
                        taxValue: Binding(
                            get: { taxes[key] ?? 0 },
                            set: { taxes[key] = $0 }
                        ),
                        onDelete: {
                            taxes.removeValue(forKey: key)
                        }
                    )
                }

                AddTaxView { name, value in
                    if !name.isEmpty && !taxes.keys.contains(name) {
                        taxes[name] = value
                        calculateTotal()
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private var paymentSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Payment Method")
                    .font(.headline)

                HStack(spacing: 12) {
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        PaymentMethodButton(
                            method: method,
                            isSelected: paymentMethod == method,
                            action: {
                                withAnimation {
                                    paymentMethod = method

                                    // Update payment values
                                    if method == .card {
                                        paidCard = total
                                        paidCash = 0
                                    } else {
                                        paidCard = 0
                                        paidCash = total
                                    }
                                }
                            }
                        )
                    }
                }

                if paymentMethod == .card {
                    TextField("Amount Paid", value: $paidCard, formatter: NumberFormatter.currency)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    TextField("Amount Paid", value: $paidCash, formatter: NumberFormatter.currency)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private var totalSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Receipt Total")
                    .font(.headline)

                HStack {
                    Text("Total Amount")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(currencyFormatter.string(from: NSNumber(value: total)) ?? "$0.00")
                        .font(.headline)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private var saveButton: some View {
        Button {
            saveReceipt()
        } label: {
            Text("Save Receipt")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(12)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .padding(.bottom)
        .background(
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .edgesIgnoringSafeArea(.bottom)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -5)
        )
    }

    // MARK: - Helper Functions

    private func calculateTotal() {
        let itemsTotal = items.reduce(0) { $0 + $1.total }
        // Tax calculation can be adjusted as needed
        total = itemsTotal

        // Update the payment method amount
        if paymentMethod == .card {
            paidCard = total
        } else {
            paidCash = total
        }
    }

    private func saveReceipt() {
        // Create totals object
        let totals = Totals(
            total: total,
            paidCard: paymentMethod == .card ? paidCard : nil,
            paidCash: paymentMethod == .cash ? paidCash : nil
        )

        // Create receipt entry
        let receipt = ReceiptEntry(
            id: UUID().uuidString,
            userId: "", // or the current user's ID if available
            company: company,
            items: items,
            totals: Totals(
                total: total,
                paidCard: paymentMethod == .card ? paidCard : nil,
                paidCash: paymentMethod == .cash ? paidCash : nil
            ),
            taxes: taxes,
            date: date,
            category: selectedCategory,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Here you would save the receipt to your data store
        print("Saving receipt: \(receipt)")

        // Dismiss the view
        dismiss()
    }

    // MARK: - Formatters

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$" // Adjust based on your needs
        return formatter
    }
}

// MARK: - Supporting Views

struct ItemRow: View {
    @Binding var item: Item
    var showDeleteButton: Bool
    var onDelete: () -> Void
    var updateTotal: (Double, Int) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Item name", text: $item.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if showDeleteButton {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }

            HStack {
                HStack {
                    Text("Qty:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("1", value: $item.quantity, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                        .onChange(of: item.quantity) { newValue in
                            // Ensure positive quantity
                            if newValue <= 0 {
                                item.quantity = 1
                            }
                            updateTotal(item.unitPrice, item.quantity)
                        }
                }

                HStack {
                    Text("Price:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("0.00", value: $item.unitPrice, formatter: NumberFormatter.currency)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .onChange(of: item.unitPrice) { newValue in
                            updateTotal(newValue, item.quantity)
                        }
                }
            }

            HStack {
                Text("Total:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(NumberFormatter.currency.string(from: NSNumber(value: item.total)) ?? "$0.00")
                    .font(.headline)
            }
        }
    }
}

struct TaxRow: View {
    let taxName: String
    @Binding var taxValue: Double
    var onDelete: () -> Void

    var body: some View {
        HStack {
            Text(taxName)
                .foregroundColor(.primary)
            Spacer()
            TextField("0.00", value: $taxValue, formatter: NumberFormatter.currency)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 100)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
}

struct AddTaxView: View {
    @State private var taxName: String = ""
    @State private var taxValue: Double = 0
    var onAdd: (String, Double) -> Void

    var body: some View {
        HStack {
            TextField("Tax name (e.g. TVA 9%)", text: $taxName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("0.00", value: $taxValue, formatter: NumberFormatter.currency)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 80)

            Button(action: {
                onAdd(taxName, taxValue)
                taxName = ""
                taxValue = 0
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
            .disabled(taxName.isEmpty)
        }
    }
}

struct PaymentMethodButton: View {
    let method: AddReceiptView.PaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: method == .card ? "creditcard" : "banknote")
                    .font(.system(size: 24))
                Text(method.rawValue)
                    .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .foregroundColor(isSelected ? .accentColor : .primary)
    }
}

struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: Category?
    let categories: [Category]

    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    Button {
                        selectedCategory = category
                        dismiss()
                    } label: {
                        HStack {
                            Text("\(category.icon) \(category.name)")
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
