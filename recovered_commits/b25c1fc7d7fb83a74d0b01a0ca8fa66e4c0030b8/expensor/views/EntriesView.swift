import SwiftUI
import Foundation

// MARK: - Views
struct EntriesView: View {
    @StateObject private var viewModel = ExpenseViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var showCategoriesAndSearch: Bool = true
    @State private var selectedReceiptForSheet: ReceiptEntry? = nil // New state for sheet
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main content
                VStack(spacing: 0) {
                    // Calendar days
                    CalendarScrollView(
                        dates: viewModel.uniqueDates,
                        selectedDate: $viewModel.selectedDate,
                        expenseCountForDate: viewModel.expenseCount
                    )
                    .background(Color(UIColor.tertiarySystemBackground))
                    
                    // Receipts list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredReceipts, id: \.identifier) { receipt in
                                ReceiptCardView(
                                    receipt: receipt,
                                    primaryCategory: viewModel.primaryCategory(for: receipt),
                                    isExpanded: false // No longer expanded
                                )
                                .onTapGesture {
                                    selectedReceiptForSheet = receipt // Open sheet
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        // Track scroll position to hide/show bottom controls only if results > 3
                        .background(GeometryReader { geo -> Color in
                            let offset = geo.frame(in: .named("scroll")).minY
                            DispatchQueue.main.async {
                                // Only hide search bar if we have more than 3 results
                                if viewModel.filteredReceipts.count > 3 {
                                    if abs(offset - scrollOffset) > 30 {
                                        withAnimation(.easeInOut) {
                                            showCategoriesAndSearch = offset > scrollOffset
                                        }
                                        scrollOffset = offset
                                    }
                                } else {
                                    // Always show search bar for fewer than 3 results
                                    withAnimation(.easeInOut) {
                                        showCategoriesAndSearch = true
                                    }
                                }
                            }
                            return Color.clear
                        })
                    }
                    .coordinateSpace(name: "scroll")
                }
                
                // Bottom fixed categories and search bar
                if showCategoriesAndSearch {
                    VStack(spacing: 12) {
                        // Search bar
                        SearchBarView(searchText: $viewModel.searchText)
                            .padding(.horizontal)
                        
                        // Categories scroll view
                        CategoryScrollView(
                            categories: viewModel.allCategories,
                            selectedCategory: $viewModel.selectedCategory
                        )
                        .padding(.bottom, 0) // Removed bottom padding to align with bottom
                    }
                    .padding(.top, 8)
                    .background(
                        Rectangle()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -3)
                            .edgesIgnoringSafeArea(.bottom) // Extend to bottom of screen
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading) {
                        Text(String(format: "%.2f RON", viewModel.totalExpenses))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            // Camera action to be implemented
                        } label: {
                            Image(systemName: "camera")
                                .font(.system(size: 18, weight: .medium))
                        }
                        
                        Button {
                            // Add action to be implemented
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                        }
                    }
                }
            }
        }
        .accentColor(.blue)
        .sheet(item: $selectedReceiptForSheet) { receipt in
            ReceiptDetailSheetView(receipt: receipt, primaryCategory: viewModel.primaryCategory(for: receipt))
        }
    }
}

struct EntriesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EntriesView()
                .previewDisplayName("Light Mode")
            
            EntriesView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
