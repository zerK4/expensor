import Foundation

final class ReceiptsViewModel: ObservableObject {
    private let userSession: UserSession
    @Published var receipts: [ReceiptEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var filteredReceipts: [ReceiptEntry] = []
    
    var selectedDate: Date? = nil

    private var loadReceiptsTask: Task<Void, Never>? // Store the task

    init(userSession: UserSession) {
        self.userSession = userSession

        Task {
            await loadReceipts()
        }
    }
    
    func filterByDate(_ date: Date) {
        let normalizedDate = date.startOfDay
        if let selected = selectedDate, Calendar.current.isDate(selected, inSameDayAs: normalizedDate) {
            filteredReceipts = receipts
            selectedDate = nil
            return
        }

        filteredReceipts = receipts.filter { receipt in
            Calendar.current.isDate(receipt.date, inSameDayAs: normalizedDate)
        }
        selectedDate = normalizedDate
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
                self.filteredReceipts = loadedReceipts
                
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
        filteredReceipts.append(receipt)
    }
    
    func removeReceipt(withId id: String) {
        receipts.removeAll { $0.id == id }
        filteredReceipts.removeAll { $0.id == id }
    }
}
