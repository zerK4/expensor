import Foundation
import SwiftUI


struct ReceiptItemView: View {
    let item: Item
    
    var body: some View {
        HStack {
            Text("\(item.quantity) x \(item.name)")
            Spacer()
            Text(String(format: "%.2f lei", item.total))
                .bold()
        }
    }
}

struct ReceiptTotalView: View {
    let totals: Totals
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Total:")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.2f lei", totals.total))
                    .font(.headline)
            }
            
            if let paidCard = totals.paidCard {
                HStack {
                    Text("Card:")
                    Spacer()
                    Text(String(format: "%.2f lei", paidCard))
                }
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            
            if let paidCash = totals.paidCash {
                HStack {
                    Text("Cash:")
                    Spacer()
                    Text(String(format: "%.2f lei", paidCash))
                }
                .font(.footnote)
                .foregroundColor(.secondary)
            }
        }
    }
}

struct ReceiptRowView: View {
    let receipt: ReceiptEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(receipt.company.name)
                .font(.headline)
            Text("CIF: \(receipt.company.cif)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Divider()
            
            ForEach(receipt.items, id: \.name) { item in
                ReceiptItemView(item: item)
            }
            
            Divider()
            
            ReceiptTotalView(totals: receipt.totals)
            
            HStack {
                Text("TVA:")
                Spacer()
                Text(receipt.taxes.map { "\($0.key) \($0.value, specifier: "%.2f") lei" }
                    .joined(separator: ", "))
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct EntriesView: View {
    @State private var receipts: [ReceiptEntry] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(receipts) { receipt in
                    ReceiptRowView(receipt: receipt)
                }
            }
            .navigationTitle("Bonuri fiscale")
        }
        .onAppear {
            receipts = loadReceipts()
        }
    }
}
