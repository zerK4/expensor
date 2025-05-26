import SwiftUI

struct ReceiptDetailSheetView: View {
    let receipt: ReceiptEntry
    let primaryCategory: Category
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(receipt.company.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(receipt.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.2f RON", receipt.totals.total))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: primaryCategory.icon)
                            .font(.caption2)
                        Text(primaryCategory.name)
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.blue))
                    Spacer()
                    if let paidCard = receipt.totals.paidCard, paidCard > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "creditcard")
                                .font(.caption)
                            Text("Card")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    if let paidCash = receipt.totals.paidCash, paidCash > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "banknote")
                                .font(.caption)
                            Text("Cash")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                Divider()
                // Mock receipt image
                ZStack {
                    Rectangle()
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: 180)
                        .cornerRadius(8)
                    Image(systemName: "doc.text.image")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                }
                // Company details
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vendor")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(receipt.company.name)
                        .font(.body)
                    Text("CIF: \(receipt.company.cif)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                // Items
                VStack(alignment: .leading, spacing: 8) {
                    Text("Items")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    VStack(spacing: 8) {
                        ForEach(receipt.items.indices, id: \.self) { index in
                            let item = receipt.items[index]
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.body)
                                    HStack {
                                        Text("\(item.quantity) x \(String(format: "%.2f", item.unitPrice)) RON")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        if let category = item.category {
                                            HStack(spacing: 2) {
                                                Image(systemName: category.icon)
                                                    .font(.system(size: 10))
                                                Text(category.name)
                                                    .font(.caption2)
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(Color.blue.opacity(0.2))
                                            )
                                            .foregroundColor(.blue)
                                        }
                                    }
                                }
                                Spacer()
                                Text(String(format: "%.2f RON", item.total))
                                    .font(.body)
                            }
                        }
                    }
                }
                // Taxes
                if !receipt.taxes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Taxes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        ForEach(Array(receipt.taxes.keys), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .font(.caption)
                                Spacer()
                                if let value = receipt.taxes[key] {
                                    Text(String(format: "%.2f RON", value))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                // Total
                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "%.2f RON", receipt.totals.total))
                        .font(.headline)
                }
            }
            .padding()
        }
        .presentationDetents([.medium, .large])
    }
}
