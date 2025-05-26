import SwiftUI
import PhotosUI
import Foundation

// MARK: - Item Row View
private struct ItemRowView: View {
    @Binding var item: Item
    var onValueChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Item Name", text: $item.name)
            HStack(spacing: 8) {
                Text("Quantity: \(item.quantity)")
                Spacer()
                if item.quantity > 1 {
                    Button(action: {
                        onValueChange()
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    }
                }
                Stepper("", value: $item.quantity, in: 1...100)
                    .fixedSize()
            }
            HStack {
                Text("Unit Price:")
                TextField("0.00",
                         value: $item.unitPrice,
                         formatter: NumberFormatter.currency)
                    .keyboardType(.decimalPad)
            }
            Text("Total: \(String(format: "%.2f lei", item.total))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .onChange(of: item.quantity) { _ in onValueChange() }
        .onChange(of: item.unitPrice) { _ in onValueChange() }
    }
}

private enum PaymentMethod {
    case card, cash, none
}

struct AddReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var receiptStore: ReceiptStore
    @State private var newReceipt = ReceiptEntry(
        id: UUID().uuidString,
        company: Company(name: "", cif: ""),
        items: [Item(name: "", quantity: 1, unitPrice: 0, total: 0)],
        totals: Totals(total: 0),
        taxes: [:]
    )
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showSourcePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedPaymentMethod: PaymentMethod = .none
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Receipt Photo")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Take a photo of your receipt using the camera for automatic data extraction, or choose an existing photo from your library.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                        
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(8)
                        }
                    
                    Button(action: {
                        showSourcePicker = true
                    }) {
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
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(image: $selectedImage, sourceType: imageSourceType)
                    }
                    }
                }
                
                Section(header: Text("Company Information")) {
                    TextField("Company Name", text: $newReceipt.company.name)
                    TextField("CIF", text: $newReceipt.company.cif)
                }
                
                Section(header: Text("Items")) {
                    ForEach(newReceipt.items.indices, id: \.self) { index in
                        ItemRowView(item: $newReceipt.items[index], onValueChange: {
                            withAnimation {
                                newReceipt.items.remove(at: index)
                                calculateTotals()
                            }
                        })
                    }
                    
                    Button(action: {
                        newReceipt.items.append(Item(name: "", quantity: 1, unitPrice: 0, total: 0))
                    }) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                    }
                }
                
                Section(header: Text("Payment")) {
                    VStack(spacing: 15) {
                        Text("Select Payment Method")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 15) {
                            // Card Payment Button
                            Button(action: {
                                withAnimation {
                                    selectedPaymentMethod = selectedPaymentMethod == .card ? .none : .card
                                    if selectedPaymentMethod == .card {
                                        newReceipt.totals.paidCard = newReceipt.totals.total
                                        newReceipt.totals.paidCash = nil
                                    } else {
                                        newReceipt.totals.paidCard = nil
                                    }
                                }
                            }) {
                                VStack {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 24))
                                    Text("Card")
                                        .font(.subheadline)
                                        .bold()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedPaymentMethod == .card ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .foregroundColor(selectedPaymentMethod == .card ? .blue : .gray)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedPaymentMethod == .card ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Cash Payment Button
                            Button(action: {
                                withAnimation {
                                    selectedPaymentMethod = selectedPaymentMethod == .cash ? .none : .cash
                                    if selectedPaymentMethod == .cash {
                                        newReceipt.totals.paidCash = newReceipt.totals.total
                                        newReceipt.totals.paidCard = nil
                                    } else {
                                        newReceipt.totals.paidCash = nil
                                    }
                                }
                            }) {
                                VStack {
                                    Image(systemName: "banknote.fill")
                                        .font(.system(size: 24))
                                    Text("Cash")
                                        .font(.subheadline)
                                        .bold()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedPaymentMethod == .cash ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                                .foregroundColor(selectedPaymentMethod == .cash ? .green : .gray)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedPaymentMethod == .cash ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                
                Section {
                    Button("Save Receipt") {
                        calculateTotals()
                        saveReceipt()
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add New Receipt")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .onAppear {
                calculateTotals()
            }
        }
    }
    
    private var isFormValid: Bool {
        !newReceipt.company.name.isEmpty &&
        !newReceipt.company.cif.isEmpty &&
        !newReceipt.items.isEmpty &&
        newReceipt.items.allSatisfy { !$0.name.isEmpty }
    }
    
    private func calculateItemTotal(at index: Int) {
        if index < newReceipt.items.count {
            newReceipt.items[index].total = newReceipt.items[index].unitPrice * Double(newReceipt.items[index].quantity)
            calculateTotals()
        }
    }
    
    private func calculateTotals() {
        let itemsTotal = newReceipt.items.reduce(0) { $0 + $1.total }
        newReceipt.totals.total = itemsTotal
        
        // Update payment amounts if they exist
        if newReceipt.totals.paidCard != nil {
            newReceipt.totals.paidCard = itemsTotal
        }
        if newReceipt.totals.paidCash != nil {
            newReceipt.totals.paidCash = itemsTotal
        }
        
        // Update taxes (simplified example)
        newReceipt.taxes = ["TVA_9%": itemsTotal * 0.09]
    }
    
    private func saveReceipt() {
        // Remove any empty items before saving
        newReceipt.items.removeAll { $0.name.isEmpty }
        
        // Save receipt to store
        receiptStore.addReceipt(newReceipt)
        
        if let image = selectedImage {
            uploadImage(image)
        }
    }
    
    private func uploadImage(_ image: UIImage) {
        print("Uploading image...")
    }
}



#Preview {
    AddReceiptView()
        .environmentObject(ReceiptStore())
}

extension ReceiptEntry {
    static var previewData: ReceiptEntry {
        ReceiptEntry(
            id: UUID().uuidString,
            company: Company(name: "Test Company", cif: "RO123456"),
            items: [
                Item(name: "Item 1", quantity: 2, unitPrice: 10.0, total: 20.0),
                Item(name: "Item 2", quantity: 1, unitPrice: 15.0, total: 15.0)
            ],
            totals: Totals(total: 35.0, paidCard: 35.0, paidCash: nil),
            taxes: ["TVA_9%": 3.15]
        )
    }
}

