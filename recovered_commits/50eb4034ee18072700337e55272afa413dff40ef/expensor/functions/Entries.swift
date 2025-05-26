import Foundation

func loadReceipts() -> [ReceiptEntry] {
    guard let url = Bundle.main.url(forResource: "mock", withExtension: "json", subdirectory: "data") else {
        print("JSON file not found")
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
