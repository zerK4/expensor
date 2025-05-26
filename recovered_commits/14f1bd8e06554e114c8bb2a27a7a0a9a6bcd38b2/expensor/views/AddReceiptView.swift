import SwiftUI
import PhotosUI

struct Company {
    var name: String
    var cif: String
}

struct Item {
    var name: String
    var quantity: Double
    var unitPrice: Double
    var total: Double {
        return quantity * unitPrice
    }
}

struct Totals {
    var total: Double
    var paidCard: Double?
    var paidCash: Double?
}

struct AddReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var company = Company(name: "", cif: "")
    @State private var items: [Item] = [Item(name: "", quantity: 1, unitPrice: 0)]
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showCamera = false
    @State private var showImagePicker = false
    @State private var paymentType = "card"
    
    private var total: Double {
        items.reduce(0) { $0 + $1.total }
    }
    
    var body: some View {
        Form {
            Section("Company Information") {
                TextField("Company Name", text: $company.name)
                TextField("CIF", text: $company.cif)
            }
            
            Section("Items") {
                ForEach($items) { $item in
                    VStack {
                        TextField("Item Name", text: $item.name)
                        HStack {
                            TextField("Quantity", value: $item.quantity, format: .number)
                                .keyboardType(.decimalPad)
                            Text("×")
                            TextField("Price", value: $item.unitPrice, format: .currency(code: "RON"))
                                .keyboardType(.decimalPad)
                            Text("=")
                            Text(item.total.formatted(.currency(code: "RON")))
                        }
                    }
                }
                Button("Add Item") {
                    items.append(Item(name: "", quantity: 1, unitPrice: 0))
                }
            }
            
            Section("Payment") {
                Picker("Payment Type", selection: $paymentType) {
                    Text("Card").tag("card")
                    Text("Cash").tag("cash")
                    Text("Mixed").tag("mixed")
                }
                .pickerStyle(.segmented)
                
                if paymentType == "mixed" {
                    TextField("Paid by Card", value: $totals.paidCard, format: .currency(code: "RON"))
                        .keyboardType(.decimalPad)
                    TextField("Paid in Cash", value: $totals.paidCash, format: .currency(code: "RON"))
                        .keyboardType(.decimalPad)
                }
            }
            
            Section("Receipt Image") {
                HStack {
                    Button {
                        showImagePicker = true
                    } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                    
                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                }
                
                if let selectedImageData,
                   let image = UIImage(data: selectedImageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                }
            }
            
            Section {
                Button("Save Receipt") {
                    saveReceipt()
                }
                .disabled(!isValid)
            }
        }
        .navigationTitle("Add Receipt")
        .sheet(isPresented: $showCamera) {
            ImagePicker(selectedImage: $selectedImageData, sourceType: .camera)
        }
        .photosPicker(isPresented: $showImagePicker,
                     selection: $selectedItem,
                     matching: .images)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }
    
    private var isValid: Bool {
        !company.name.isEmpty &&
        !company.cif.isEmpty &&
        !items.isEmpty &&
        items.allSatisfy { !$0.name.isEmpty && $0.total > 0 }
    }
    
    private func saveReceipt() {
        // Here you would typically save the receipt to your backend
        // For now, we'll just dismiss the view
        dismiss()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: Data?
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                parent.selectedImage = data
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationView {
        AddReceiptView()
    }
}