import SwiftUI

struct ReceiptCardView: View {
    let receipt: ReceiptEntry
    let primaryCategory: Category
    let isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(receipt.company.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(receipt.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(String(format: "%.2f RON", receipt.totals.total))
                    .font(.headline)
                    .foregroundColor(.primary)
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
            if isExpanded {
                Divider()
                // Receipt details (omitted for brevity)
            } else {
                if !receipt.items.isEmpty {
                    Text("\(receipt.items.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
