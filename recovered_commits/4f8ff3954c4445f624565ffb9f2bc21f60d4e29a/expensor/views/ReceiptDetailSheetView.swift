import SwiftUI
import Foundation

struct ReceiptDetailSheetView: View {
    let receipt: ReceiptEntry
    let primaryCategory: Category

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(receipt.company?.name ?? "Unknown")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(receipt.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "No date")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
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
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(receipt.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack {
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
                }

                // Items Card
                VStack(alignment: .leading, spacing: 1) {
                    HStack {
                        Text("Items")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let items = receipt.items {
                            Text("\(items.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.15))
                                )
                        }
                    }
                    .padding(.bottom, 6)
                    if let items = receipt.items, !items.isEmpty {
                        ForEach(items.indices, id: \.self) { index in
                            let item = items[index]
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.body)
                                    Text("\(item.quantity) x \(String(format: "%.2f", item.unitPrice)) RON")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(String(format: "%.2f RON", item.total))
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        Text("No items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                )

                // Total
                HStack {
                    Text("Total")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f RON", receipt.total))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
        }
        .presentationDetents([.medium, .large])
    }
}
