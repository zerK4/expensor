import Foundation
import SwiftUI

class ExpenseViewModel: ObservableObject {
    @Published var receipts: [ReceiptEntry] = []
    @Published var selectedDate: Date = Date()
    @Published var selectedCategory: String?
    @Published var searchText: String = ""
    
    var uniqueDates: [Date] {
        let dates = receipts.map { $0.date }
        return Array(Set(dates)).sorted(by: >)
    }
    
    var allCategories: [String] {
        let categories = receipts.flatMap { $0.categories }
        return Array(Set(categories)).sorted()
    }
    
    var filteredReceipts: [ReceiptEntry] {
        var filtered = receipts
        
        // Filter by selected date
        filtered = filtered.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        
        // Filter by category if selected
        if let category = selectedCategory {
            filtered = filtered.filter { $0.categories.contains(category) }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.merchant.localizedCaseInsensitiveContains(searchText) ||
                $0.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    
    var totalExpenses: Double {
        filteredReceipts.reduce(0) { $0 + $1.amount }
    }
    
    func expenseCount(for date: Date) -> Int {
        receipts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.count
    }
    
    func primaryCategory(for receipt: ReceiptEntry) -> String? {
        receipt.categories.first
    }
    
    // MARK: - Mock Data for Preview
    static func mockData() -> ExpenseViewModel {
        let viewModel = ExpenseViewModel()
        
        let mockReceipts: [ReceiptEntry] = [
            ReceiptEntry(
                identifier: UUID(),
                date: Date(),
                merchant: "Grocery Store",
                amount: 125.50,
                categories: ["Groceries", "Food"],
                imageURL: nil,
                notes: "Weekly groceries"
            ),
            ReceiptEntry(
                identifier: UUID(),
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                merchant: "Gas Station",
                amount: 200.00,
                categories: ["Transportation", "Car"],
                imageURL: nil,
                notes: "Full tank"
            ),
            ReceiptEntry(
                identifier: UUID(),
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                merchant: "Restaurant",
                amount: 85.00,
                categories: ["Food", "Entertainment"],
                imageURL: nil,
                notes: "Dinner with friends"
            )
        ]
        
        viewModel.receipts = mockReceipts
        return viewModel
    }
}
