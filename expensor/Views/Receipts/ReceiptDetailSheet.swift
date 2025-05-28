import SwiftUI

struct ReceiptDetailSheet: View {
    let receipt: ReceiptEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Colors adapt to light/dark mode
    private var cardBackground: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    private var formattedDate: String {
        receipt.date.formatted(date: .abbreviated, time: .shortened)
    }
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "RON"
        return formatter.string(from: NSNumber(value: receipt.total)) ?? String(format: "%.2f RON", receipt.total)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    
                    if !receipt.items.isEmpty {
                        itemsSection
                    }
                    
                    if hasPaymentMethods {
                        paymentMethodsSection
                    }
                    
                    metadataSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
//            .background(sheetBackground)
            .navigationTitle("Receipt Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
            }
        }
        .presentationDetents([.medium, .large])
//        .presentationBackground(sheetBackground)
        .presentationCornerRadius(24) // Rounded corners for the sheet
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Computed Properties
    
    private var hasPaymentMethods: Bool {
        (receipt.paidCard ?? 0) > 0 || (receipt.paidCash ?? 0) > 0
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        CardView(backgroundColor: cardBackground) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(receipt.companies.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        if let cif = receipt.companies.cif {
                            Text("CIF: \(cif)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    if let category = receipt.categories {
                        categoryBadge(category: category)
                    }
                }
                
                Divider()
                    .overlay(Color.gray.opacity(0.2))
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(formattedTotal)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .blue)
                    }
                }
            }
            .padding(20)
        }
    }
    
    private func categoryBadge(category: Category) -> some View {
        HStack(spacing: 6) {
            Text(category.icon)
            Text(category.name.capitalized)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
        )
        .foregroundColor(colorScheme == .dark ? .white : .blue)
    }
    
    private var itemsSection: some View {
        CardView(title: "Items", backgroundColor: cardBackground) {
            LazyVStack(spacing: 0) {
                ForEach(Array(receipt.items.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 0) {
                        itemRow(item: item)
                        
                        if index < receipt.items.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func itemRow(item: Item) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(colorScheme == .dark ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(item.name.prefix(1))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text("\(item.quantity) × \(String(format: "%.2f RON", item.unitPrice))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(String(format: "%.2f RON", item.total))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
        .padding(12)
        .padding(.horizontal, 4)
    }
    
    private var paymentMethodsSection: some View {
        CardView(title: "Payment Methods", backgroundColor: cardBackground) {
            VStack(spacing: 12) {
                if let paidCard = receipt.paidCard, paidCard > 0 {
                    paymentMethodRow(
                        icon: "creditcard.fill",
                        color: .blue,
                        method: "Card",
                        amount: paidCard
                    )
                }
                
                if let paidCash = receipt.paidCash, paidCash > 0 {
                    paymentMethodRow(
                        icon: "banknote.fill",
                        color: .green,
                        method: "Cash",
                        amount: paidCash
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func paymentMethodRow(icon: String, color: Color, method: String, amount: Double) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                .clipShape(Circle())
            
            Text(method)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Spacer()
            
            Text(String(format: "%.2f RON", amount))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var metadataSection: some View {
        CardView(title: "Receipt Information", backgroundColor: cardBackground) {
            VStack(spacing: 12) {
                infoRow(
                    icon: "number",
                    label: "Receipt ID",
                    value: String(receipt.id.prefix(8)) + "..."
                )
                
                infoRow(
                    icon: "calendar",
                    label: "Created",
                    value: receipt.createdAt.formatted(date: .abbreviated, time: .shortened)
                )
            }
            .padding(.vertical, 8)
        }
    }
    
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 36, height: 36)
                .background(Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                .clipShape(Circle())
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Card Component

struct CardView<Content: View>: View {
    let title: String?
    let backgroundColor: Color
    let content: Content
    
    init(title: String? = nil, backgroundColor: Color = Color(.systemBackground), @ViewBuilder content: () -> Content) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
