import SwiftUI
import Foundation

class ExpenseViewModel: ObservableObject {
    @Published var receipts: [ReceiptEntry] = []
    @Published var selectedDate: Date? = nil
    @Published var selectedCategory: Category? = nil
    @Published var searchText: String = ""
    @Published var expandedReceiptID: String? = nil
    @Published var allCategories: [Category] = []

    init() {
        loadData()
        setupCategories()
    }

    private func loadData() {
        receipts = ReceiptService.loadReceipts()
        print(receipts, "loaded receipts")
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
        for (receiptIndex, receipt) in receipts.enumerated() {
            var updatedItems = receipt.items
            for (itemIndex, item) in receipt.items.enumerated() {
                if item.category == nil {
                    let itemName = item.name.lowercased()
                    if itemName.contains("menu") || itemName.contains("food") ||
                       itemName.contains("meal") || itemName.contains("sushi") {
                        updatedItems[itemIndex].category = allCategories[0]
                    } else if itemName.contains("water") || itemName.contains("milk") ||
                              itemName.contains("bread") || itemName.contains("apa") {
                        updatedItems[itemIndex].category = allCategories[1]
                    } else {
                        updatedItems[itemIndex].category = allCategories[0]
                    }
                }
            }
            receipts[receiptIndex].items = updatedItems
        }
    }

    func primaryCategory(for receipt: ReceiptEntry) -> Category {
        let categories = receipt.items.compactMap { $0.category }
        var categoryCounts: [Category: Int] = [:]
        for category in categories {
            categoryCounts[category, default: 0] += 1
        }
        return categoryCounts.max(by: { $0.value < $1.value })?.key ??
               categories.first ??
        Category(userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac",  name: "Miscellaneous", icon: "tag")
    }

    var totalExpenses: Double {
        receipts.reduce(0) { $0 + $1.totals.total }
    }

    var filteredReceipts: [ReceiptEntry] {
        var filtered = receipts

        if let selectedDate = selectedDate {
            let calendar = Calendar.current
            filtered = filtered.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        }
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { receipt in
                receipt.items.contains { item in
                    item.category?.id == selectedCategory.id
                }
            }
        }
        if !searchText.isEmpty {
            filtered = filtered.filter { receipt in
                receipt.company.name.localizedCaseInsensitiveContains(searchText) ||
                receipt.items.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
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
