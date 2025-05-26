import SwiftUI
import Foundation

struct EntriesView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel
    @State private var scrollOffset: CGFloat = 0
    @State private var showCategoriesAndSearch: Bool = true
    @State private var selectedReceiptForSheet: ReceiptEntry? = nil
    @State private var showAddReceipt = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    CalendarScrollView(
                        dates: viewModel.uniqueDates,
                        selectedDate: $viewModel.selectedDate,
                        expenseCountForDate: viewModel.expenseCount
                    )
                    .background(Color(UIColor.tertiarySystemBackground))
                    HStack {
                        Text("Total")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(String(format: "%.2f RON", viewModel.totalExpenses))
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .padding(.horizontal)
                    receiptsList
                }
                if showCategoriesAndSearch {
                    bottomBar
                }
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Loading Receipts...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                        .shadow(radius: 10)
                }
            }
            .task {
                isLoading = true
                await viewModel.loadReceiptsFromSupabase()
                isLoading = false
            }
        }
        .accentColor(.blue)
        .sheet(item: $selectedReceiptForSheet) { receipt in
            ReceiptDetailSheetView(receipt: receipt, primaryCategory: viewModel.primaryCategory(for: receipt))
        }
        .sheet(isPresented: $showAddReceipt) {
            AddReceiptView()
        }
    }

    private var receiptsList: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(
                        viewModel.filteredReceipts.sorted {
                            ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
                        }, id: \.id
                    ) { receipt in
                        ReceiptCardView(
                            receipt: receipt,
                            primaryCategory: viewModel.primaryCategory(for: receipt),
                            isExpanded: false
                        )
                        .onTapGesture {
                            selectedReceiptForSheet = receipt
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
                .background(receiptsGeometryReader)
            }
            .coordinateSpace(name: "scroll")
            .refreshable {
                isLoading = true
                await viewModel.loadReceiptsFromSupabase()
                isLoading = false
            }

            if isLoading {
                ProgressView("Loading Receipts...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    private var receiptsGeometryReader: some View {
        GeometryReader { geo in
            let offset = geo.frame(in: .named("scroll")).minY
            Color.clear
                .onAppear { updateScrollOffset(offset) }
                .onChange(of: offset) { newOffset in updateScrollOffset(newOffset) }
        }
    }

    private func updateScrollOffset(_ offset: CGFloat) {
        if viewModel.filteredReceipts.count > 3 {
            if abs(offset - scrollOffset) > 30 {
                withAnimation(.easeInOut) {
                    showCategoriesAndSearch = offset > scrollOffset
                }
                scrollOffset = offset
            }
        } else {
            withAnimation(.easeInOut) {
                showCategoriesAndSearch = true
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            SearchBarView(searchText: $viewModel.searchText)
                .padding(.horizontal)
            CategoryScrollView(
                categories: viewModel.allCategories,
                selectedCategory: $viewModel.selectedCategory
            )
            .padding(.bottom, 0)
        }
        .padding(.top, 8)
        .background(
            Rectangle()
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -3)
                .edgesIgnoringSafeArea(.bottom)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct EntriesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EntriesView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
