import Foundation

final class ReceiptsViewModel: ObservableObject {
    private let userSession: UserSession
    @Published var receipts: [ReceiptEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(userSession: UserSession) {
        self.userSession = userSession

        Task {
            await loadReceipts()
        }
    }

    @MainActor
    func loadReceipts() async {
        guard let userId = userSession.user?.id else {
            errorMessage = "User not authenticated"
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
            
            print("Raw JSON Response:")
            print(String(data: response.data, encoding: .utf8) ?? "No data")

            // Use the custom decoder instead of default JSONDecoder
            let decoder = JSONDecoder.receiptDecoder
            let loadedReceipts = try decoder.decode([ReceiptEntry].self, from: response.data)

            print("Successfully loaded \(loadedReceipts.count) receipts")
            
            // Update the published property on main thread
            self.receipts = loadedReceipts
            
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
    }
    
    // Helper function to provide more detailed decoding error messages
    private func handleDecodingError(_ error: DecodingError) -> String {
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
