import Foundation
import SwiftUI

struct ReceiptDetailSheet: View {
    let receipt: ReceiptEntry
    @Environment(\.dismiss) private var dismiss
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: receipt.date)
    }
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "RON"
        return formatter.string(from: NSNumber(value: receipt.total)) ?? String(format: "%.2f RON", receipt.total)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    
                    if !receipt.items.isEmpty {
                        itemsCard
                    }
                    
                    paymentMethodsCard
                    
                    metadataCard
                }
                .padding()
            }
            .navigationTitle("Receipt Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .fontWeight(.medium)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Card Components
    
    private var headerCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    companyInfo
                    Spacer()
                    categoryBadge
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DATE")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(formattedDate)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("TOTAL")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(formattedTotal)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding()
        }
    }
    
    private var companyInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(receipt.companies.name)
                .font(.title3)
                .fontWeight(.semibold)
            
            if let cif = receipt.companies.cif {
                Text("CIF: \(cif)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var categoryBadge: some View {
        if let category = receipt.categories {
            HStack(spacing: 6) {
                Text(category.icon)
                Text(category.name.capitalized)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var paymentMethodsCard: some View {
        if (receipt.paidCard ?? 0) > 0 || (receipt.paidCash ?? 0) > 0 {
            CardView(title: "PAYMENT METHODS") {
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
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    private func paymentMethodRow(icon: String, color: Color, method: String, amount: Double) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(method)
                .font(.subheadline)
            
            Spacer()
            
            Text(String(format: "%.2f RON", amount))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private var itemsCard: some View {
        CardView(title: "ITEMS (\(receipt.items.count))") {
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
            .padding(.bottom)
        }
    }
    
    private func itemRow(item: Item) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(item.quantity) × \(String(format: "%.2f RON", item.unitPrice))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.2f RON", item.total))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding()
        .padding(.horizontal, 4)
    }
    
    private var metadataCard: some View {
        CardView(title: "RECEIPT INFO") {
            VStack(spacing: 10) {
                infoRow(label: "Receipt ID", value: String(receipt.id.prefix(8)) + "...")
                
                if let createdAt = receipt.createdAt {
                    infoRow(
                        label: "Created",
                        value: DateFormatter.shortDateTime.string(from: createdAt)
                    )
                }
            }
            .padding(.bottom)
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
        }
        .padding(.horizontal)
    }
}

// MARK: - Reusable Components

struct CardView<Content: View>: View {
    let title: String?
    let content: Content
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 12)
            }
            
            content
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
