import Foundation

func loadReceipts() -> [ReceiptEntry] {
    // First try to load from the main bundle
    if let url = Bundle.main.url(forResource: "mock", withExtension: "json") {
        do {
            let data = try Data(contentsOf: url)
            let receipts = try JSONDecoder().decode([ReceiptEntry].self, from: data)
            return receipts
        } catch {
            print("Error loading or decoding JSON: \(error)")
        }
    }

    // If not found in main bundle, try the data subdirectory
    if let url = Bundle.main.url(forResource: "mock", withExtension: "json", subdirectory: "data") {
        do {
            let data = try Data(contentsOf: url)
            let receipts = try JSONDecoder().decode([ReceiptEntry].self, from: data)
            return receipts
        } catch {
            print("Error loading or decoding JSON: \(error)")
        }
    }

    print("JSON file not found in main bundle or data subdirectory")
    return []
}
