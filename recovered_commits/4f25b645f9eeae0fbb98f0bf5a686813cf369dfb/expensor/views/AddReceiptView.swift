import SwiftUI
import PhotosUI
import Foundation

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
                Section(header: Text("Company Information")) {
                    TextField("Company Name", text: $newReceipt.company.name)
                    TextField("CIF", text: $newReceipt.company.cif)
                }
                
                Section(header: Text("Items")) {
                    ForEach(0..<newReceipt.items.count, id: \.self) { index in
                        VStack(alignment: .leading) {
                            TextField("Item Name", text: $newReceipt.items[index].name)
                            Stepper("Quantity: \(newReceipt.items[index].quantity)",
                                   value: $newReceipt.items[index].quantity, in: 1...100)
                            HStack {
                                Text("Unit Price:")
                                TextField("0.00",
                                         value: $newReceipt.items[index].unitPrice,
                                         formatter: NumberFormatter.currency)
                                    .keyboardType(.decimalPad)
                            }
                            Text("Total: \(String(format: "%.2f lei", newReceipt.items[index].total))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .onChange(of: newReceipt.items[index].quantity) { _ in
                            calculateItemTotal(at: index)
                        }
                        .onChange(of: newReceipt.items[index].unitPrice) { _ in
                            calculateItemTotal(at: index)
                        }
                    }
                    
                    Button(action: {
                        newReceipt.items.append(Item(name: "", quantity: 1, unitPrice: 0, total: 0))
                    }) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                    }
                }
                
                Section(header: Text("Payment")) {
                    Toggle("Paid by Card", isOn: Binding(
                        get: { newReceipt.totals.paidCard != nil },
                        set: {
                            newReceipt.totals.paidCard = $0 ? newReceipt.totals.total : nil
                            if $0 && newReceipt.totals.paidCash != nil {
                                newReceipt.totals.paidCash = nil
                            }
                        }
                    ))
                    
                    Toggle("Paid by Cash", isOn: Binding(
                        get: { newReceipt.totals.paidCash != nil },
                        set: {
                            newReceipt.totals.paidCash = $0 ? newReceipt.totals.total : nil
                            if $0 && newReceipt.totals.paidCard != nil {
                                newReceipt.totals.paidCard = nil
                            }
                        }
                    ))
                }
                
                Section(header: Text("Receipt Photo")) {
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
                    .actionSheet(isPresented: $showImagePicker) {
                        ActionSheet(
                            title: Text("Select Photo"),
                            buttons: [
                                .default(Text("Take Photo")) {
                                    imageSourceType = .camera
                                },
                                .default(Text("Choose from Library")) {
                                    imageSourceType = .photoLibrary
                                },
                                .cancel()
                            ]
                        )
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(image: $selectedImage, sourceType: imageSourceType)
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
                presentationMode.wrappedValue.dismiss()
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
        if let paidCard = newReceipt.totals.paidCard {
            newReceipt.totals.paidCard = itemsTotal
        }
        if let paidCash = newReceipt.totals.paidCash {
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

#Preview {
    AddReceiptView()
        .previewLayout(.sizeThatFits)
        .environmentObject(NavigationStack())
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

