import Foundation
import SwiftUI

struct ReceiptItemView: View {
    let item: Item
    
    var body: some View {
        HStack {
            Text("\(item.quantity) x \(item.name)")
                .foregroundColor(.primary)
            Spacer()
            Text(String(format: "%.2f lei", item.total))
                .foregroundColor(.primary)
                .bold()
        }
        .padding(.vertical, 2)
    }
}

struct ReceiptTotalView: View {
    let totals: Totals
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Total:")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.2f lei", totals.total))
                    .font(.headline)
            }
            
            if let paidCard = totals.paidCard {
                HStack {
                    Image(systemName: "creditcard")
                        .foregroundColor(.blue)
                    Text("Card:")
                    Spacer()
                    Text(String(format: "%.2f lei", paidCard))
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            if let paidCash = totals.paidCash {
                HStack {
                    Image(systemName: "banknote")
                        .foregroundColor(.green)
                    Text("Cash:")
                    Spacer()
                    Text(String(format: "%.2f lei", paidCash))
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
    }
}

struct ReceiptRowView: View {
    let receipt: ReceiptEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(receipt.company.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("CIF: \(receipt.company.cif)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Total amount circle
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                    Text(String(format: "%.0f", receipt.totals.total))
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .frame(width: 50, height: 50)
            }
            
            Divider()
            
            // Items
            VStack(spacing: 6) {
                ForEach(receipt.items, id: \.name) { item in
                    ReceiptItemView(item: item)
                }
            }
            .padding(.vertical, 4)
            
            Divider()
            
            // Totals
            ReceiptTotalView(totals: receipt.totals)
            
            // Tax information
            HStack {
                Image(systemName: "percent")
                    .foregroundColor(.orange)
                Text("TVA:")
                Spacer()
                Text(receipt.taxes.map { "\($0.key) \(String(format: "%.2f", $0.value)) lei" }
                    .joined(separator: ", "))
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct EntriesView: View {
    @State private var receipts: [ReceiptEntry] = []
    @State private var showAlert = false
    @State private var receiptToDelete: ReceiptEntry?
    
    var body: some View {
        NavigationView {
            ZStack {
                if receipts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "receipt")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No receipts found")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(receipts) { receipt in
                            ReceiptRowView(receipt: receipt)
                                .listRowInsets(EdgeInsets())
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteReceipts)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Bonuri fiscale")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("Total: \(String(format: "%.2f lei", receipts.reduce(0) { $0 + $1.totals.total }))")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            receipts = loadReceipts()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Delete Receipt"),
                message: Text("Are you sure you want to delete this receipt from \(receiptToDelete?.company.name ?? "")?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let receipt = receiptToDelete,
                       let index = receipts.firstIndex(where: { $0.id == receipt.id }) {
                        receipts.remove(at: index)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func deleteReceipts(at offsets: IndexSet) {
        if let first = offsets.first {
            receiptToDelete = receipts[first]
            showAlert = true
        }
    }
}

#Preview {
    EntriesView()
}
