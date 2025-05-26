import SwiftUI
import Supabase
import Vision

struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - Main View
struct AddReceiptView: View {
    @EnvironmentObject var receiptsViewModel: ExpenseViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Receipt images
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var showSourcePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isProcessingImage = false
    @State private var showItemsSection = false

    // Receipt data
    @State private var company = Company(id: "", userId: "", name: "", cif: "")
    @State private var companyName: String = ""
    @State private var date = Date()
    @State private var selectedCategory: Category? = nil
    @State private var showCategoryPicker = false
    @State private var items: [Item] = [Item(id: UUID().uuidString, name: "", quantity: 1, unitPrice: 0, total: 0)]
    @State private var taxes: [String: Double] = ["TVA 9%": 0]
    @State private var paymentMethod: PaymentMethod = .card
    @State private var total: Double = 0
    @State private var paidCard: Double = 0
    @State private var paidCash: Double = 0
    @State private var userId: String = ""
    
    @State private var isSaving = false
    @State private var alertMessage: AlertMessage?
    
    @State private var showFormSections = true
    @State private var isSaveButtonAnimating = false
    
    enum FocusedField {
        case companyName, companyCIF
    }

    @FocusState private var focusedField: FocusedField?
    
    @State private var companies: [Company] = []
    @State private var categories: [Category] = []
    
    @State private var showCompanySheet = false

    enum PaymentMethod: String, CaseIterable {
        case card = "Card"
        case cash = "Cash"
    }

    var body: some View {
        NavigationView {
              ZStack {
                  // Background
                                 Color(UIColor.systemGroupedBackground)
                                     .ignoresSafeArea()
                                 
                                 ScrollView {
                                     VStack(spacing: 16) {
                                         imageSection
                                         
                                         if selectedImages.isEmpty {
                                             formSections
                                         }
                                     }
                                     .padding(.bottom, 100)
                                 }
                  
                  VStack {
                      Spacer()
                      saveButton
                  }
              }
              .overlay(savingOverlay)
            .alert(item: $alertMessage) { alert in
                Alert(
                    title: Text("Receipt"),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK")) {
                        alertMessage = nil
                    }
                )
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
                PhotoPicker(images: $selectedImages, maxSelection: 3)
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
            .task {
                if let user = try? await supabase.auth.session.user {
                    userId = user.id.uuidString.lowercased()
                    print("User is authenticated", user)
                    
                    do {
                        categories = try await CategoryService.shared.fetchCategories()
                        companies = try await CompanyService.shared.fetchCompanies()
                    } catch {
                        print("Error fetching categories: \(error.localizedDescription)")
                    }
                }
            }
        }
        .animation(.default, value: selectedImages.isEmpty)
        .onChange(of: selectedImages) { images in
                    withAnimation(.spring()) {
                        showFormSections = images.isEmpty
                    }
                }
    }

    // MARK: - UI Components
    private var savingOverlay: some View {
        Group {
            if isSaving {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView("Saving receipt...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.systemBackground)))
                    }
                }
            }
        }
    }
    
    private var scanWithAIButton: some View {
            Button {
                Task {
                    await saveReceipt()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .symbolEffect(.bounce, options: .repeating, value: isSaveButtonAnimating)
                        .font(.title3)
                    
                    Text(isSaving ? "Processing..." : "Scan with AI")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            .disabled(isSaving)
            .padding(.bottom)
            .background(
                Rectangle()
                    .fill(Color(UIColor.systemBackground))
                    .edgesIgnoringSafeArea(.bottom)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                    isSaveButtonAnimating = true
                }
            }
        }
    
    private var imageFullScreenDisplay: some View {
           ZStack {
               Color(.systemBackground)
                   .ignoresSafeArea()
               
               VStack {
                   Spacer()
                   
                   ZStack {
                       ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                           Image(uiImage: image)
                               .resizable()
                               .scaledToFit()
                               .frame(width: 300, height: 400)
                               .cornerRadius(20)
                               .shadow(radius: 10)
                               .rotationEffect(.degrees(Double(index) * 3 - 3))
                               .offset(
                                   x: CGFloat(index) * 10 - 20,
                                   y: CGFloat(index) * -15 + 15
                               )
                               .zIndex(Double(index))
                       }
                   }
                   .padding(.top, 50)
                   
                   Spacer()
                   
                   if selectedImages.count < 3 {
                       Button {
                           showSourcePicker = true
                       } label: {
                           Label("Add Another Photo", systemImage: "plus")
                               .font(.subheadline)
                               .foregroundColor(.accentColor)
                               .padding(10)
                               .background(Color.accentColor.opacity(0.1))
                               .cornerRadius(8)
                       }
                       .padding(.bottom, 20)
                   }
               }
           }
       }
    
    private var formSections: some View {
            Group {
                companySection
                dateAndCategorySection
                itemsOrButtonSection
                paymentSection
                totalSection
            }
            .padding(.horizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    
    private var imageSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                if selectedImages.isEmpty {
                    // Full width add button when no images
                    addPhotoButton
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                } else {
                    // Images display with add button if needed
                    imageScrollView
                }
                
                aiHintSection
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground).opacity(0.9))
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .frame(maxWidth: .infinity)
        }
    
    private var imageScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    imageCell(for: image, at: index)
                }
                
                if selectedImages.count < 3 {
                    addPhotoButton
                        .frame(width: 120, height: 120)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func imageCell(for image: UIImage, at index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 2)
                )
                .shadow(radius: 5)
                .padding(.vertical, 4)
                .transition(.scale.animation(.spring(response: 0.5, dampingFraction: 0.8)))

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    .clipShape(Circle())
            }
            .padding(6)
            .offset(x: 8, y: -8)
        }
    }

    private var addPhotoButton: some View {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showSourcePicker = true
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: selectedImages.isEmpty ? 50 : 40))
                        .foregroundColor(.accentColor)
                    Text("Add Photo")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: selectedImages.isEmpty ? 150 : 120)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundColor(.gray.opacity(0.5))
                )
                .shadow(radius: 3)
            }
        }

    private var aiHintSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundColor(.yellow)
                .font(.title2)
                .accessibilityLabel("AI")
                .scaleEffect(isProcessingImage ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isProcessingImage)

            Text("Snap a picture of your receipt and let our **smart AI** handle the rest. We'll automatically fill in the details for you!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var companySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Where did you make the expense?")
                    .font(.headline)
                    .padding(.bottom, 4)
                HStack {
                    StyledTextField(
                        icon: "building.2",
                        placeholder: "Name",
                        text: $companyName
                    )
                    .onChange(of: companyName) { newValue in
                        company.name = newValue
                    }
                    Button {
                        showCompanySheet = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .padding(8)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Select Company")
                }
                // Info text
                Text("If you can't find your company in the list, just type its name and we'll create it for you.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(25)
        }
        .sheet(isPresented: $showCompanySheet) {
            CompanyPickerSheet(
                companies: companies,
                onSelect: { selected in
                    company = selected
                    companyName = selected.name
                    showCompanySheet = false
                }
            )
        }
    }
    
    private var isFormValid: Bool {
        if !selectedImages.isEmpty {
            return true
        }
        let hasItems = showItemsSection && !items.isEmpty
        let totalValid = hasItems || total > 0
        return !company.name.trimmingCharacters(in: .whitespaces).isEmpty
            && selectedCategory != nil
            && (paymentMethod == .card || paymentMethod == .cash)
            && totalValid
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
            .cornerRadius(25)
        }
    }

    private var itemsOrButtonSection: some View {
        Section {
            if showItemsSection {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Items")
                            .font(.headline)
                        Spacer()
                    }

                    ForEach(Array(items.enumerated()), id: \.element.id) { index, _ in
                        ItemRow(
                            item: Binding(
                                get: { items[index] },
                                set: { items[index] = $0 }
                            ),
                            showDeleteButton: true,
                            onDelete: {
                                withAnimation {
                                    items.remove(at: index)
                                    items.count == 0 ? showItemsSection = false : calculateTotal()
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
                    Button {
                        withAnimation {
                            items.append(Item(id: UUID().uuidString, name: "", quantity: 1, unitPrice: 0, total: 0))
                        }
                    } label: {
                        HStack {
                            Text("Add Item")
                                .fontWeight(.semibold)
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 28))
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(25)
            } else {
                Button(action: {
                    withAnimation {
                        showItemsSection = true
                        items.count == 0 ? items.append(Item(id: UUID().uuidString, name: "", quantity: 1, unitPrice: 0, total: 0)) : nil
                    }
                }) {
                    Text("Add items")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
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
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(25)
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
                    if showItemsSection && !items.isEmpty {
                        Text(NumberFormatter.currencyFormatter.string(from: NSNumber(value: total)) ?? "$0.00")
                            .font(.headline)
                    } else {
                        HStack(spacing: 4) {
                            Text(NumberFormatter.currencyFormatter.currencySymbol ?? "$")
                                .foregroundColor(.secondary)
                            TextField("", value: $total, format: .number)
                                .keyboardType(.decimalPad)
                                .font(.headline)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80, height: 44)
                                .padding(.trailing, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(UIColor.tertiarySystemBackground))
                                )
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(25)
        }
    }

    private var saveButton: some View {
          Button {
              Task {
                  await saveReceipt()
              }
          } label: {
              HStack(spacing: 12) {
                  if !selectedImages.isEmpty {
                      Image(systemName: "sparkles")
                          .symbolEffect(.bounce, options: .repeating, value: isSaveButtonAnimating)
                          .font(.title3)
                  }
                  
                  Text(buttonText)
                      .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(buttonBackground)
              .cornerRadius(12)
              .padding(.horizontal)
              .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
          }
          .disabled(isSaving || !isFormValid)
          .padding(.bottom)
          .background(
              Rectangle()
                  .fill(Color(UIColor.systemBackground))
                  .edgesIgnoringSafeArea(.bottom)
                  .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -5)
          )
          .onAppear {
              if !selectedImages.isEmpty {
                  withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                      isSaveButtonAnimating = true
                  }
              }
          }
      }
    
    private var buttonBackground: some View {
          Group {
              if isSaving {
                  Color.gray
              } else if selectedImages.isEmpty {
                  Color.accentColor
              } else {
                  LinearGradient(
                      gradient: Gradient(colors: [Color.blue, Color.purple]),
                      startPoint: .leading,
                      endPoint: .trailing
                  )
              }
          }
      }
    
    private var buttonText: String {
        if isSaving {
            return "Processing..."
        }
        return selectedImages.isEmpty ? "Save Receipt" : "Scan with AI"
    }

    // MARK: - Helper Functions

    private func calculateTotal() {
        let itemsTotal = items.reduce(0) { $0 + $1.total }
        total = itemsTotal

        if paymentMethod == .card {
            paidCard = total
        } else {
            paidCash = total
        }
    }
    
    private func saveReceipt() async {
        if !isFormValid {
             alertMessage = AlertMessage(message: "Please complete all required fields.")
             return
         }

         withAnimation {
             isSaving = true
         }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        // 1. Recognize text from all selected images
        var imageTexts: [String] = []
        let group = DispatchGroup()
        for image in selectedImages {
            group.enter()
            recognizeText(from: image) { lines in
                imageTexts.append(lines.joined(separator: "\n"))
                group.leave()
            }
        }

        // 2. Encode items
        let itemsJSON: String
        do {
            let data = try encoder.encode(items)
            itemsJSON = String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            isSaving = false
            alertMessage = AlertMessage(message: "Failed to encode items: \(error.localizedDescription)")
            return
        }

        // 3. Encode imageTexts as JSON
        let imageTextsJSON: String
        do {
            let data = try JSONSerialization.data(withJSONObject: imageTexts, options: [])
            imageTextsJSON = String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            isSaving = false
            alertMessage = AlertMessage(message: "Failed to encode image texts: \(error.localizedDescription)")
            return
        }

        let companyIdToSend = company.id.isEmpty ? "" : company.id
        let companyNameToSend = company.id.isEmpty ? companyName : company.name

        let fields: [String: String] = [
            "user_id": userId,
            "company_id": companyIdToSend,
            "company_name": companyNameToSend,
            "date": ISO8601DateFormatter().string(from: date),
            "category_id": selectedCategory?.id ?? "",
            "total": "\(total)",
            "items": itemsJSON,
            "paid_card": "\(paidCard)",
            "paid_cash": "\(paidCash)",
            "imageTexts": imageTextsJSON
        ]

        do {
            let _ = try await ApiService.shared.uploadReceipt(
                         urlString: "http://192.168.1.205:3000/receipts",
                         fields: fields,
                         images: selectedImages
                     )
                     
                     // Wait a bit to show success state
                     try await Task.sleep(nanoseconds: 500_000_000)
                     
                     await receiptsViewModel.loadReceiptsFromSupabase()
                     
                     // Hide loading overlay and show success
                     withAnimation {
                         isSaving = false
                     }
                     
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                     alertMessage = AlertMessage(message: "Receipt saved successfully!")
                     dismiss()
        } catch {
            withAnimation {
                           isSaving = false
                       }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
                       alertMessage = AlertMessage(message: "Failed to save receipt: \(error.localizedDescription)")
        }
    }
    
    private func recognizeText(from image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }
            let texts = observations.compactMap { $0.topCandidates(1).first?.string }
            completion(texts)
        }
        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion([])
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
            TextField("0.00", value: $taxValue, formatter: NumberFormatter.currencyFormatter)
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

            TextField("0.00", value: $taxValue, formatter: NumberFormatter.currencyFormatter)
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

struct AdvancedAnimationsView_Previews: PreviewProvider {
    static var previews: some View {
        AddReceiptView()
    }
}
