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

                // Search Bar and Filter
                VStack {
                    TextField("Search receipts...", text: $receiptsViewModel.searchQuery)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)

                }
                .padding(.bottom, 8) // Add some space below search controls
                
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
                    // Search Results Count
                    if !receiptsViewModel.searchQuery.isEmpty {
                        Text("\(receiptsViewModel.filteredReceipts.count) Receipts Found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 4)
                            .animation(.easeInOut, value: receiptsViewModel.filteredReceipts.count)
                    }

                    List {
                        if receiptsViewModel.filteredReceipts.isEmpty && receiptsViewModel.searchQuery.isEmpty && receiptsViewModel.selectedDate == nil {
                             // Only show EmptyReceiptsView if no filters are applied and list is empty
                            EmptyReceiptsView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                        } else if receiptsViewModel.filteredReceipts.isEmpty && (!receiptsViewModel.searchQuery.isEmpty || receiptsViewModel.selectedDate != nil) {
                            // Show a message when filters are applied but no results found
                            VStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("No Matching Receipts")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)

                        }
                        else {
                            ForEach(receiptsViewModel.filteredReceipts, id: \.id) { receipt in
                                VStack(alignment: .leading) { // Stack indicators above ReceiptCard
                                    // Indicators VStack
                                    VStack(alignment: .leading, spacing: 4) {
                                        if receipt.matchedName {
                                            Text("Name Match")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 4)
                                                .background(Color.blue.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                        if receipt.matchedItem {
                                            Text("Item Match")
                                                 .font(.system(size: 10, weight: .semibold))
                                                 .foregroundColor(.green)
                                                 .padding(.horizontal, 4)
                                                 .background(Color.green.opacity(0.2))
                                                 .cornerRadius(4)
                                        }
                                        if receipt.matchedCategory {
                                            // Display category name if available
                                            Text("Category Match" + (receipt.matchedCategoryName != nil ? ": \(receipt.matchedCategoryName!)" : ""))
                                                 .font(.system(size: 10, weight: .semibold))
                                                 .foregroundColor(.orange)
                                                 .padding(.horizontal, 4)
                                                 .background(Color.orange.opacity(0.2))
                                                 .cornerRadius(4)
                                        }
                                    }
                                    // Animation for indicators stack and space below if indicators are visible
                                    .animation(.easeInOut, value: receipt.matchedName || receipt.matchedItem || receipt.matchedCategory)
                                    .padding(.bottom, receipt.matchedName || receipt.matchedItem || receipt.matchedCategory ? 4 : 0)


                                    ReceiptCard(receipt: receipt) {
                                        selectedReceipt = receipt
                                    }
                                }
                                .listRowSeparator(.hidden) // Keep the row separator hidden
                                .listRowBackground(Color.clear) // Ensure no background interferes
                                .animation(.easeInOut, value: receipt.id) // Animate row changes
                            }
                         }
                     }
                    .listStyle(.plain)
                    .animation(.easeInOut, value: receiptsViewModel.filteredReceipts.isEmpty) // Animate list changes
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
            paidCash: 25.50,
            paidCard: 74.50,
            categories: sampleCategory,
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
