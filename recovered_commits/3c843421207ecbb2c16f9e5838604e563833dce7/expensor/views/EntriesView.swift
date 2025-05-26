// Import the model and functions
import Foundation
import SwiftUI

struct EntriesView: View {
    @State private var receipts: [ReceiptEntry] = []

    var body: some View {
        NavigationView {
            List {
                ForEach(receipts, id: \.id) { receipt in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(receipt.company.name)
                            .font(.headline)
                        Text("CIF: \(receipt.company.cif)")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Divider()

                        ForEach(receipt.items, id: \.name) { item in
                            HStack {
                                Text(String("\(item.quantity) x \(item.name)"))
                                Spacer()
                                Text(String(format: "%.2f lei", item.total))
                                    .bold()
                            }
                        }

                        Divider()

                        HStack {
                            Text("Total:")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.2f lei", receipt.totals.total))
                                .font(.headline)
                        }

                        if let paidCard = receipt.totals.paidCard {
                            HStack {
                                Text("Card:")
                                Spacer()
                                Text(String(format: "%.2f lei", paidCard))
                            }
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        }

                        if let paidCash = receipt.totals.paidCash {
                            HStack {
                                Text("Cash:")
                                Spacer()
                                Text(String(format: "%.2f lei", paidCash))
                            }
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("TVA:")
                            Spacer()
                            Text(receipt.taxes.map { String("\($0.key) \($0.value, specifier: "%.2f") lei") }
                                .joined(separator: ", "))
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Bonuri fiscale")
        }
        .onAppear {
            receipts = loadReceipts()
        }
    }
}
