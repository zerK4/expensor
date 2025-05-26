import Foundation
import Supabase

class CategoryService {
    static let shared = CategoryService()
    private init() {}

    func fetchCategories() async throws -> [Category] {
        let response = try await supabase
            .from("categories")
            .select()
            .execute()
        let categories = try JSONDecoder().decode([Category].self, from: response.data)
        return categories
    }
}
