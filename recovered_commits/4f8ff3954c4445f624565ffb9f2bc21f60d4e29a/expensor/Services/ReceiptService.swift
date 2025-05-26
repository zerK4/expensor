import Foundation
import Supabase

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
    
    static func getReceipts() async -> [ReceiptEntry] {
            do {
                let response: PostgrestResponse<[ReceiptEntry]> = try await supabase
                    .from("receipt_entries")
                    .select("*, companies(*), items(*), categories(*)")
                    .execute()
                print("Supabase HTTP status:", response.status)
                print("Supabase raw data:", String(data: response.data, encoding: .utf8) ?? "nil")
                print("Decoded value:", response.value)
                print("Loaded receipts from supabase")
                return response.value
            } catch {
                print("Error fetching receipts from Supabase: \(error)")
                return []
            }
        }
}
