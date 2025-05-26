import Foundation
import SwiftUI

struct ReceiptsView: View {
    @EnvironmentObject var receiptsViewModel: ReceiptsViewModel
    @State private var selectedReceipt: ReceiptEntry?
    @State private var showReceiptDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if receiptsViewModel.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading receipts...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else if let errorMessage = receiptsViewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Something went wrong")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Try Again") {
                            Task {
                                await receiptsViewModel.refreshReceipts()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if receiptsViewModel.receipts.isEmpty {
                    EmptyReceiptsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(receiptsViewModel.receipts) { receipt in
                                ReceiptCard(receipt: receipt) {
                                    selectedReceipt = receipt
                                    showReceiptDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Receipts")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await receiptsViewModel.refreshReceipts()
            }
            .sheet(isPresented: $showReceiptDetail) {
                if let receipt = selectedReceipt {
                    ReceiptDetailSheet(receipt: receipt)
                }
            }
        }
        .onAppear {
            if receiptsViewModel.receipts.isEmpty && !receiptsViewModel.isLoading {
                Task {
                    await receiptsViewModel.loadReceipts()
                }
            }
        }
    }
}

struct EmptyReceiptsView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Animated receipt icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "receipt")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("No receipts yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start tracking your expenses by adding your first receipt")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    // Add receipt action
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Receipt")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
                
                Button(action: {
                    // Scan receipt action
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Scan Receipt")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }
}

struct ReceiptCard: View {
    let receipt: ReceiptEntry
    let onTap: () -> Void
    
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
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            categoryAndPaymentSection
            itemsCountSection
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private var headerSection: some View {
        HStack {
            companyInfo
            Spacer()
            totalAndDateInfo
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private var companyInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(receipt.companies.name)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            if let cif = receipt.companies.cif {
                Text("CIF: \(cif)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var totalAndDateInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(formattedTotal)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var categoryAndPaymentSection: some View {
        HStack {
            categoryBadge
            Spacer()
            paymentMethodIndicators
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var categoryBadge: some View {
        if let category = receipt.categories {
            HStack(spacing: 6) {
                Text(category.icon)
                    .font(.system(size: 16))
                Text(category.name.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var paymentMethodIndicators: some View {
        HStack(spacing: 8) {
            cardPaymentBadge
            cashPaymentBadge
        }
    }
    
    @ViewBuilder
    private var cardPaymentBadge: some View {
        if let paidCard = receipt.paidCard, paidCard > 0 {
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.caption)
                Text("Card")
                    .font(.caption)
            }
            .foregroundColor(.blue)
        }
    }
    
    @ViewBuilder
    private var cashPaymentBadge: some View {
        if let paidCash = receipt.paidCash, paidCash > 0 {
            HStack(spacing: 4) {
                Image(systemName: "banknote.fill")
                    .font(.caption)
                Text("Cash")
                    .font(.caption)
            }
            .foregroundColor(.green)
        }
    }
    
    @ViewBuilder
    private var itemsCountSection: some View {
        if !receipt.items.isEmpty {
            Divider()
            
            HStack {
                Image(systemName: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(receipt.items.count) item\(receipt.items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview
#Preview {
    PreviewContent()
}

private struct PreviewContent: View {
    var body: some View {
        let sampleCompany = Company(
            id: UUID().uuidString,
            userId: "user123",
            name: "SUSHI WOK SRL",
            cif: "RO12345678"
        )
        
        let sampleCategory = Category(
            id: UUID().uuidString,
            userId: "user123",
            name: "food",
            icon: "🍔"
        )
        
        let sampleReceipt = ReceiptEntry(
            id: UUID().uuidString,
            userId: "user123",
            companies: sampleCompany,
            items: [],
            taxes: nil,
            date: Date(),
            categories: sampleCategory,
            categoryId: sampleCategory.id,
            companyId: sampleCompany.id,
            paidCash: 25.50,
            paidCard: 74.50,
            total: 100.0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ReceiptCard(receipt: sampleReceipt) { }
                }
                .padding(.horizontal, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Receipts")
        }
    }
}
