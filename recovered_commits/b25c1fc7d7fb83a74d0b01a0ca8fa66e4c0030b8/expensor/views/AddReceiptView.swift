//import SwiftUI
//import PhotosUI
//import Foundation
//
//// 1. Define PaymentMethod enum
//enum PaymentMethod: String, CaseIterable, Identifiable {
//    case card, cash
//    var id: String { rawValue }
//}
//
//struct AddReceiptViewFixed: View {
//    @Environment(\.dismiss) private var dismiss
//    @State private var newReceipt = ReceiptEntry(
//        id: UUID().uuidString,
//        company: Company(name: "", cif: ""),
//        items: [Item(name: "", quantity: 1, unitPrice: 0, total: 0)],
//        totals: Totals(total: 0),
//        taxes: [:],
//        date: Date(),
//        category: nil
//    )
//    @State private var selectedImage: UIImage?
//    @State private var showImagePicker = false
//    @State private var showSourcePicker = false
//    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
//    // 2. Use PaymentMethod? type
//    @State private var selectedPaymentMethod: PaymentMethod? = nil
//    @State private var selectedCategory: Category? = nil
//    @State private var date = Date()
//    @State private var showCategoryPicker = false
//
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(spacing: 24) {
//                    ReceiptImageSection(selectedImage: $selectedImage, showImagePicker: $showImagePicker, showSourcePicker: $showSourcePicker, imageSourceType: $imageSourceType)
//                        .padding(.top)
//                    ReceiptCompanySection(company: $newReceipt.company)
//                    ReceiptDateCategorySection(date: $date, selectedCategory: $selectedCategory, showCategoryPicker: $showCategoryPicker)
//                    ReceiptItemsSection(items: $newReceipt.items)
//                    // 3. Pass PaymentMethod? to subview
//                    ReceiptPaymentSection(selectedPaymentMethod: $selectedPaymentMethod, totals: $newReceipt.totals)
//                    ReceiptTaxesSection(taxes: $newReceipt.taxes)
//                    Button(action: saveReceipt) {
//                        Text("Save Receipt")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(12)
//                    }
//                    .padding(.vertical)
//                }
//                .padding(.horizontal)
//            }
//            .navigationTitle("Add Receipt")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel") { dismiss() }
//                }
//            }
//            .sheet(isPresented: $showImagePicker) {
//                ImagePicker(image: $selectedImage, sourceType: imageSourceType)
//            }
//            .sheet(isPresented: $showCategoryPicker) {
//                CategoryPickerViewFixed(selectedCategory: $selectedCategory)
//            }
//        }
//    }
//
//    private func saveReceipt() {
//        let updatedReceipt = ReceiptEntry(
//            id: newReceipt.id,
//            company: newReceipt.company,
//            items: newReceipt.items,
//            totals: newReceipt.totals,
//            taxes: newReceipt.taxes,
//            date: date,
//            category: selectedCategory
//        )
//        newReceipt = updatedReceipt
//        print("--- Saved Receipt ---")
//        print("ID: \(updatedReceipt.id)")
//        print("Date: \(updatedReceipt.date)")
//        print("Company: \(updatedReceipt.company.name), CIF: \(updatedReceipt.company.cif)")
//        print("Category: \(updatedReceipt.category?.name ?? "-")")
//        print("Items: \(updatedReceipt.items)")
//        print("Totals: \(updatedReceipt.totals)")
//        print("Taxes: \(updatedReceipt.taxes)")
//        // 4. Use PaymentMethod? correctly
//        print("Payment Method: \(selectedPaymentMethod?.rawValue ?? "-")")
//        if let _ = selectedImage {
//            print("Image: selected")
//        } else {
//            print("Image: none")
//        }
//        dismiss()
//    }
//}
//
//// --- The rest of your subviews remain unchanged except for PaymentMethod usage ---
//
//private struct ReceiptPaymentSection: View {
//    @Binding var selectedPaymentMethod: PaymentMethod?
//    @Binding var totals: Totals
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Payment Method").font(.headline)
//            HStack(spacing: 16) {
//                PaymentMethodButton(method: .card, selected: selectedPaymentMethod == .card) {
//                    selectedPaymentMethod = selectedPaymentMethod == .card ? nil : .card
//                    if selectedPaymentMethod == .card {
//                        totals.paidCard = totals.total
//                        totals.paidCash = nil
//                    } else {
//                        totals.paidCard = nil
//                    }
//                }
//                PaymentMethodButton(method: .cash, selected: selectedPaymentMethod == .cash) {
//                    selectedPaymentMethod = selectedPaymentMethod == .cash ? nil : .cash
//                    if selectedPaymentMethod == .cash {
//                        totals.paidCash = totals.total
//                        totals.paidCard = nil
//                    } else {
//                        totals.paidCash = nil
//                    }
//                }
//            }
//        }
//    }
//}
//
//private struct PaymentMethodButton: View {
//    let method: PaymentMethod
//    let selected: Bool
//    let action: () -> Void
//    var body: some View {
//        Button(action: action) {
//            VStack {
//                Image(systemName: method == .card ? "creditcard.fill" : "banknote.fill")
//                    .font(.system(size: 24))
//                Text(method == .card ? "Card" : "Cash")
//                    .font(.subheadline)
//                    .bold()
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 12)
//            .background(selected ? (method == .card ? Color.blue.opacity(0.2) : Color.green.opacity(0.2)) : Color.gray.opacity(0.1))
//            .foregroundColor(selected ? (method == .card ? .blue : .green) : .gray)
//            .cornerRadius(12)
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(selected ? (method == .card ? Color.blue : Color.green) : Color.gray.opacity(0.3), lineWidth: 1)
//            )
//        }
//    }
//}
