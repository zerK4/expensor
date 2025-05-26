import SwiftUI
import Foundation

class ExpenseViewModel: ObservableObject {
    @Published var receipts: [ReceiptEntry] = []
    @Published var selectedDate: Date? = nil
    @Published var selectedCategory: Category? = nil
    @Published var searchText: String = ""
    @Published var expandedReceiptID: String? = nil
    @Published var allCategories: [Category] = []
    
    private var fetchTask: Task<Void, Never>?

    init() {
//        loadData()
        setupCategories()
    }

    private func loadData() async {
        receipts = ReceiptService.loadReceipts()
        print(receipts, "loaded receipts")
    }
    
    @MainActor
    func loadReceiptsFromSupabase() async {
        fetchTask?.cancel()
        
        fetchTask = Task {
                let loaded = await ReceiptService.getReceipts()
                self.receipts = loaded
                setupCategories()
        }
        
        await fetchTask?.value
    }

    private func setupCategories() {
        allCategories = [
            Category(userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "Food", icon: "fork.knife"),
            Category(userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "Groceries", icon: "cart"),
            Category(userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "Electronics", icon: "laptopcomputer"),
            Category(userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "Household", icon: "house"),
            Category(userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "Transport", icon: "car"),
            Category(userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "Entertainment", icon: "film")
        ]
        for receiptIndex in receipts.indices {
            guard var items = receipts[receiptIndex].items else { continue }

            for itemIndex in items.indices {
                if items[itemIndex].category == nil {
                    let itemName = items[itemIndex].name.lowercased()

                    if itemName.contains("menu") || itemName.contains("food") ||
                       itemName.contains("meal") || itemName.contains("sushi") {
                        items[itemIndex].category = allCategories[0]
                    } else if itemName.contains("water") || itemName.contains("milk") ||
                              itemName.contains("bread") || itemName.contains("apa") {
                        items[itemIndex].category = allCategories[1]
                    } else {
                        items[itemIndex].category = allCategories[0]
                    }
                }
            }

            receipts[receiptIndex].items = items
        }

    }

    func primaryCategory(for receipt: ReceiptEntry) -> Category {
        guard var items = receipt.items else { return allCategories[0] }
        let categories = items.compactMap { $0.category }
        var categoryCounts: [Category: Int] = [:]
        for category in categories {
            categoryCounts[category, default: 0] += 1
        }
        return categoryCounts.max(by: { $0.value < $1.value })?.key ??
               categories.first ??
        Category(userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac",  name: "Miscellaneous", icon: "tag")
    }

    var totalExpenses: Double {
        receipts.reduce(into: 0.0) { partialResult, receipt in
            if receipt.total != 0 {
                partialResult += receipt.total
            }
        }
    }

    var filteredReceipts: [ReceiptEntry] {
        var filtered = receipts

        if let selectedDate = selectedDate {
            let calendar = Calendar.current
            filtered = filtered.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        }
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { receipt in
                receipt.items?.contains { item in
                    item.category?.id == selectedCategory.id
                } ?? false
            }
        }
        if !searchText.isEmpty {
            filtered = filtered.filter { receipt in
                // Safe unwrap company name contains
                let companyMatches = receipt.company?.name.localizedCaseInsensitiveContains(searchText) ?? false
                
                // Safe unwrap items array and check any item name contains searchText
                let itemsMatch = receipt.items?.contains { item in
                    item.name.localizedCaseInsensitiveContains(searchText)
                } ?? false
                
                return companyMatches || itemsMatch
            }
        }

        return filtered
    }

    var uniqueDates: [Date] {
        let calendar = Calendar.current
        let dates = receipts.map { calendar.startOfDay(for: $0.date) }
        let unique = Set(dates)
        return unique.sorted()
    }

    func toggleReceiptExpanded(id: String) {
        if expandedReceiptID == id {
            expandedReceiptID = nil
        } else {
            expandedReceiptID = id
        }
    }

    func expenseCount(for date: Date) -> Int {
        let calendar = Calendar.current
        return receipts.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
    }
}
