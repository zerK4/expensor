import Foundation
import Supabase

class CompanyService {
    static let shared = CompanyService()
    private init() {}

    func fetchCompanies() async throws -> [Company] {
        let response = try await supabase
            .from("companies")
            .select()
            .execute()
        let companies = try JSONDecoder().decode([Company].self, from: response.data)
        print(companies, "Fetched companies")
        return companies
    }
}
