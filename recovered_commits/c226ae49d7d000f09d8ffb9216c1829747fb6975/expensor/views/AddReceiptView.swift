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
            Stepper("Quantity: \(item.quantity)",
                   value: $item.quantity, in: 1...100)
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
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    
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
                        showImagePicker = true
                    }) {
                        Label(selectedImage == nil ? "Add Photo" : "Change Photo", systemImage: "camera")
                    }
                    .confirmationDialog("Select Photo", isPresented: $showImagePicker) {
                        Button("Take Photo") {
                            imageSourceType = .camera
                            showImagePicker = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showImagePicker = true
                            }
                        }
                        Button("Choose from Library") {
                            imageSourceType = .photoLibrary
                            showImagePicker = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showImagePicker = true
                            }
                        }
                        Button("Cancel", role: .cancel) {
                            showImagePicker = false
                        }
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
                    ForEach(0..<newReceipt.items.count, id: \.self) { index in
                        ItemRowView(item: $newReceipt.items[index], onValueChange: {
                            calculateItemTotal(at: index)
                        })
                    }
                    
                    Button(action: {
                        newReceipt.items.append(Item(name: "", quantity: 1, unitPrice: 0, total: 0))
                    }) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                    }
                }
                
                Section(header: Text("Payment")) {
                    PaymentToggleView(
                        total: newReceipt.totals.total,
                        paidCard: Binding(
                            get: { newReceipt.totals.paidCard },
                            set: { newReceipt.totals.paidCard = $0 }
                        ),
                        paidCash: Binding(
                            get: { newReceipt.totals.paidCash },
                            set: { newReceipt.totals.paidCash = $0 }
                        )
                    )
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
        newReceipt.items.allSatisfy { !$0.name.isEmpty && $0.unitPrice > 0 }
    }
    
    private func calculateItemTotal(at index: Int) {
        newReceipt.items[index].total = newReceipt.items[index].unitPrice * Double(newReceipt.items[index].quantity)
        calculateTotals()
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

// MARK: - Payment Toggle View
private struct PaymentToggleView: View {
    let total: Double
    @Binding var paidCard: Double?
    @Binding var paidCash: Double?
    
    var body: some View {
        Toggle("Paid by Card", isOn: Binding(
            get: { paidCard != nil },
            set: {
                paidCard = $0 ? total : nil
                if $0 { paidCash = nil }
            }
        ))
        
        Toggle("Paid by Cash", isOn: Binding(
            get: { paidCash != nil },
            set: {
                paidCash = $0 ? total : nil
                if $0 { paidCard = nil }
            }
        ))
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

