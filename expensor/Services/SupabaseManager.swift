import Foundation
import Supabase

class SupabaseManager {
    static let shared: SupabaseClient = {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            let url = URL(string: urlString)
        else {
            fatalError("❌ Missing or invalid Supabase configuration in Info.plist")
        }

        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }()
}
