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
    let onDelete: () -> Void

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
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct EntriesView: View {
    @State private var receipts: [ReceiptEntry] = []
    @State private var searchText = ""
    @State private var showAlert = false
    @State private var receiptToDelete: ReceiptEntry?
    @State private var showSearch = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollDirection: ScrollDirection = .up

    private enum ScrollDirection {
        case up, down
    }

    var filteredReceipts: [ReceiptEntry] {
        guard !searchText.isEmpty else { return receipts }

        return receipts.filter { receipt in
            // Search by company name
            let matchesCompany = receipt.company.name
                .lowercased()
                .contains(searchText.lowercased())

            // Search by items
            let matchesItems = receipt.items.contains { item in
                item.name.lowercased().contains(searchText.lowercased())
            }

            // Search by amount (if search text is a number)
            let matchesAmount: Bool = {
                if let searchAmount = Double(searchText) {
                    return abs(receipt.totals.total - searchAmount) < 0.01
                }
                return false
            }()

            return matchesCompany || matchesItems || matchesAmount
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                List {
                    // Spacer to account for search bar
                    Color.clear
                        .frame(height: showSearch ? 56 : 0)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())

                    GeometryReader { geometry in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    if filteredReceipts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "receipt")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text(searchText.isEmpty ? "No receipts found" : "No matches found")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 100)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }

                    ForEach(filteredReceipts) { receipt in
                        ReceiptRowView(receipt: receipt) {
                            receiptToDelete = receipt
                            showAlert = true
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                receiptToDelete = receipt
                                showAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    let delta = value - lastScrollOffset

                    // Determine scroll direction
                    if abs(delta) > 1 { // Threshold to avoid minor fluctuations
                        scrollDirection = delta > 0 ? .down : .up
                    }

                    // Show/hide search based on scroll direction and position
                    withAnimation {
                        if scrollDirection == .down && value > -200 {
                            showSearch = true
                        } else if scrollDirection == .up && value < -10 {
                            showSearch = false
                        }
                    }

                    lastScrollOffset = value
                }
                .refreshable {
                    receipts = loadReceipts()
                }

                // Search Bar overlay
                if showSearch {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search by name, items, or amount...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground).opacity(0.95))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Bonuri fiscale")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("Total: \(String(format: "%.2f lei", filteredReceipts.reduce(0) { $0 + $1.totals.total }))")
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
}

#Preview {
    EntriesView()
}
