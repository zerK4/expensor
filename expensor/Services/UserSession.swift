import Foundation
import Supabase

final class UserSession: ObservableObject {
    @Published var user: User?
    static let shared = UserSession()

    init() {
        self.user = SupabaseManager.shared.auth.currentUser
    }

    func updateUser(_ user: User?) {
        self.user = user
    }
}
