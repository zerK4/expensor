import Foundation

func loadReceipts() -> [ReceiptEntry] {
    // Look for the JSON file in the bundle
    guard let url = Bundle.main.url(forResource: "data", withExtension: "json") else {
        print("Error: mock.json not found in bundle")
        return []
    }

    do {
        let data = try Data(contentsOf: url)
        let receipts = try JSONDecoder().decode([ReceiptEntry].self, from: data)
        return receipts
    } catch {
        print("Error loading or decoding JSON: \(error)")
        return []
    }
}
