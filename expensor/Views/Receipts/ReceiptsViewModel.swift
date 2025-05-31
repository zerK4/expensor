import Foundation

final class ReceiptsViewModel: ObservableObject {
    private let userSession: UserSession
    @Published var receipts: [ReceiptEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var selectedDateRange: (startDate: Date, endDate: Date)? = nil // Represents the selected date range or single date
    @Published var searchQuery: String = ""

    var filteredReceipts: [ReceiptEntry] {
        var results = receipts

        // Apply date range filter
        if let range = selectedDateRange {
            results = results.filter { receipt in
                let receiptDate = receipt.date.startOfDay
                // Check if the receipt date is within the selected range (inclusive)
                return receiptDate >= range.startDate && receiptDate <= range.endDate
            }
        }

        let query = searchQuery.lowercased()

        if !query.isEmpty {
            // Map to update transient match properties and then filter based on matches
            results = results.compactMap { receipt in
                var mutableReceipt = receipt // Create a mutable copy

                let nameMatches = mutableReceipt.companies.name.lowercased().contains(query)
                let itemMatches = mutableReceipt.items.contains { item in
                    item.name.lowercased().contains(query)
                }
                let categoryMatches = mutableReceipt.categories?.name.lowercased().contains(query) ?? false

                // Set transient properties on the mutable copy
                mutableReceipt.matchedName = nameMatches
                mutableReceipt.matchedItem = itemMatches
                mutableReceipt.matchedCategory = categoryMatches
                // Store the matched category name if a category match occurred
                if categoryMatches { mutableReceipt.matchedCategoryName = mutableReceipt.categories?.name }

                // Include the receipt if any of the fields matched the query
                if nameMatches || itemMatches || categoryMatches {
                    return mutableReceipt
                } else {
                    return nil // Exclude receipts that didn't match the search query
                }
            }
        } else {
            // If search query is empty, ensure transient properties are false and clear matched category name
            results = results.map { receipt in
                var mutableReceipt = receipt
                mutableReceipt.matchedName = false
                mutableReceipt.matchedItem = false
                mutableReceipt.matchedCategory = false
                mutableReceipt.matchedCategoryName = nil // Clear matched category name
                return mutableReceipt
            }
        }

        // Sort the results by receipt date ascending (older to newer)
        return results.sorted { $0.date < $1.date }
    }

    private var loadReceiptsTask: Task<Void, Never>? // Store the task


    init(userSession: UserSession) {
        self.userSession = userSession

        Task {
            await loadReceipts()
        }
    }

    // Handles date selection from CalendarView (single date or range)
    func applyDateSelection(dateSelection: (startDate: Date?, endDate: Date?)) {
        if let start = dateSelection.startDate, let end = dateSelection.endDate {
            // Range selected (ensure start is before or same as end)
            let normalizedStartDate = start.startOfDay
            let normalizedEndDate = end.startOfDay
            if normalizedStartDate <= normalizedEndDate {
                selectedDateRange = (startDate: normalizedStartDate, endDate: normalizedEndDate)
            } else {
                 // Handle case where end date is before start date (e.g., reset or treat as single)
                 // Treating as single selection of the later date (which is start in this case)
                 selectedDateRange = (startDate: normalizedStartDate, endDate: normalizedStartDate)
            }
        } else if let start = dateSelection.startDate {
            // Single date selected (startDate is not nil, endDate is nil from CalendarView)
            let normalizedDate = start.startOfDay
            
            // Check if the same single date is already selected - if so, clear the filter
            if let currentRange = selectedDateRange,
               currentRange.startDate == normalizedDate && currentRange.endDate == normalizedDate {
                selectedDateRange = nil // Clear the filter to show all receipts
            } else {
                selectedDateRange = (startDate: normalizedDate, endDate: normalizedDate) // Treat single date as a range of one day
            }
        } else {
            // Selection cleared (both startDate and endDate are nil from CalendarView)
            selectedDateRange = nil
        }
        // filteredReceipts computed property will handle the update
    }

    func markedDates() -> [Date] {
        let uniqueDates = Set(receipts.map { $0.date.startOfDay })
        return Array(uniqueDates).sorted()
    }

    @MainActor
    func loadReceipts() async {
        // Cancel any existing task before starting a new one
        loadReceiptsTask?.cancel()
        
        // Create a new task and store it
        loadReceiptsTask = Task {
            if Task.isCancelled { return }
            
            guard let userId = userSession.user?.id else {
                errorMessage = "User not authenticated"
                isLoading = false // Ensure isLoading is reset on early exit
                return
            }

            isLoading = true
            errorMessage = nil

            do {
                let response = try await SupabaseManager.shared
                    .from("receipt_entries")
                    .select("*, categories(*), items(*), companies(*)")
                    .eq("user_id", value: userId)
                    .execute()
                
                try Task.checkCancellation()
                
                print("Raw JSON Response:")
                print(String(data: response.data, encoding: .utf8) ?? "No data")

                let decoder = JSONDecoder.receiptDecoder
                let loadedReceipts = try decoder.decode([ReceiptEntry].self, from: response.data)
                
                try Task.checkCancellation()

                print("Successfully loaded \(loadedReceipts.count) receipts")

                self.receipts = loadedReceipts

            } catch is CancellationError {
                print("Receipts loading task was cancelled.")
                // Do nothing, as the task was intentionally cancelled
            } catch let decodingError as DecodingError {
                let errorMsg = handleDecodingError(decodingError)
                print("Decoding error: \(errorMsg)")
                errorMessage = errorMsg
            } catch {
                let errorMsg = "Error loading receipts: \(error.localizedDescription)"
                print(errorMsg)
                errorMessage = errorMsg
            }
            
            isLoading = false
            loadReceiptsTask = nil // Clear the task once it's complete
        }
        await loadReceiptsTask?.value // Wait for the task to complete
    }
    
    private func handleDecodingError(_ error: DecodingError) -> String {
        // ... (your existing handleDecodingError function)
        switch error {
        case .typeMismatch(let type, let context):
            return "Type mismatch for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            return "Value not found for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): \(context.debugDescription)"
        case .keyNotFound(let key, let context):
            return "Key '\(key.stringValue)' not found at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): \(context.debugDescription)"
        case .dataCorrupted(let context):
            return "Data corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): \(context.debugDescription)"
        @unknown default:
            return "Unknown decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Additional Helper Methods
extension ReceiptsViewModel {
    func refreshReceipts() async {
        await loadReceipts()
    }
    
    func addReceipt(_ receipt: ReceiptEntry) {
        receipts.append(receipt)
    }
    
    func removeReceipt(withId id: String) {
        receipts.removeAll { $0.id == id }
    }
}
