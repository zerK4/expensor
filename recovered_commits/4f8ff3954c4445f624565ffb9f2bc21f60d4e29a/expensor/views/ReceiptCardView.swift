import SwiftUI
import Foundation

struct ReceiptCardView: View {
    let receipt: ReceiptEntry
    let primaryCategory: Category
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Company, CreatedAt, Amount
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(receipt.company?.name ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(receipt.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Added: N/A")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text(String(format: "%.2f RON", receipt.total))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.10))
                    )
            }

            // Category + Payment type
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: primaryCategory.icon)
                        .font(.caption)
                    Text(primaryCategory.name)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.blue))

                if let paidCard = receipt.paidCard, paidCard > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard")
                            .font(.caption)
                        Text("Card")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                if let paidCash = receipt.paidCash, paidCash > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "banknote")
                            .font(.caption)
                        Text("Cash")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Items count and Store date at bottom
            HStack {
                if isExpanded {
                    Divider()
                    // Receipt details (optional)
                } else if let items = receipt.items, !items.isEmpty {
                    Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text(receipt.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .padding(.horizontal, 4)
    }
}
