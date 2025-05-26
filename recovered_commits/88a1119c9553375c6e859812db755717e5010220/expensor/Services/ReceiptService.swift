import Foundation

struct ReceiptService {
    static func loadReceipts() -> [ReceiptEntry] {
        guard let url = Bundle.main.url(forResource: "data", withExtension: "json") else {
            print("Error: data.json not found in bundle")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            decoder.dateDecodingStrategy = .formatted(formatter)
            let receipts = try decoder.decode([ReceiptEntry].self, from: data)
            
            return receipts
        } catch {
            print("Error loading or decoding JSON: \(error)")
            return []
        }
    }
}
