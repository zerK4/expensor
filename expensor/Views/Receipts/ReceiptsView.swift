// In `ReceiptsView.swift`
import Foundation
import SwiftUI

struct ReceiptsView: View {
    @EnvironmentObject var receiptsViewModel: ReceiptsViewModel
    @State private var selectedReceipt: ReceiptEntry?
    @State private var showReceiptDetail = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                            .ignoresSafeArea()
                VStack(spacing: 0) {
                    CalendarView(
                        markedDates: receiptsViewModel.markedDates(),
                        onDateSelected: { date in
                            let normalizedDate = date.startOfDay
                            print(normalizedDate, "the selected date")
                            receiptsViewModel.filterByDate(normalizedDate)
                        }
                    )
                    .padding(.top, 10)
                
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
                }  else {
                    List {
                        if receiptsViewModel.filteredReceipts.isEmpty {
                            EmptyReceiptsView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(receiptsViewModel.filteredReceipts.sorted { $0.createdAt > $1.createdAt }, id: \.id) { receipt in
                                ReceiptCard(receipt: receipt) {
                                    selectedReceipt = receipt
                                }
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                    .listStyle(.plain)
                   }
               }
               .refreshable {
                   await receiptsViewModel.refreshReceipts()
               }
               .sheet(item: $selectedReceipt) { receipt in
                   ReceiptDetailSheet(receipt: receipt)
                       .presentationDetents([.medium, .large])
                       .presentationCornerRadius(24)
                       .presentationDragIndicator(.visible)
               }
           }
        .onAppear {
            if receiptsViewModel.filteredReceipts.isEmpty && !receiptsViewModel.isLoading {
                Task {
                    await receiptsViewModel.loadReceipts()
                }
            }
        }
        .ignoresSafeArea(edges: .top)
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
        }
    }
}
