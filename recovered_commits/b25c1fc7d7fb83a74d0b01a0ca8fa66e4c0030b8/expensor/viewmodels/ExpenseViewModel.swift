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
        receipts = loadReceipts()
    }
    
    private func setupCategories() {
        allCategories = [
            Category(name: "Food", icon: "fork.knife"),
            Category(name: "Groceries", icon: "cart"),
            Category(name: "Electronics", icon: "laptopcomputer"),
            Category(name: "Household", icon: "house"),
            Category(name: "Transport", icon: "car"),
            Category(name: "Entertainment", icon: "film")
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
               Category(name: "Miscellaneous", icon: "tag")
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
        var allDates = Set<Date>()
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -15, to: today)!
        let endDate = calendar.date(byAdding: .day, value: 15, to: today)!
        var currentDate = startDate
        while currentDate <= endDate {
            if let normalized = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: currentDate)) {
                allDates.insert(normalized)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        for receipt in receipts {
            if let date = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: receipt.date)) {
                allDates.insert(date)
            }
        }
        return Array(allDates).sorted()
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
