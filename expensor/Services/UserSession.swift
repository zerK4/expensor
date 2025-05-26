import Foundation
import Supabase

final class UserSession: ObservableObject {
    @Published var user: User?

    init() {
        self.user = SupabaseManager.shared.auth.currentUser
    }

    func updateUser(_ user: User?) {
        self.user = user
    }
}
