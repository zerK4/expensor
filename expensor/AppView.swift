import Foundation
import SwiftUI

struct AppView: View {
    @EnvironmentObject var userSession: UserSession

    @State var isAuthenticated = false
    @State private var selectedTab = 0
    @State private var showAddReceipt = false
    @State private var showCategories = false
    @State private var showUserMenu = false
    @State private var showAccount = false
    @State private var showBilling = false

    var body: some View {
        Group {
            if (isAuthenticated) {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            for await state in SupabaseManager.shared.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    isAuthenticated = state.session != nil
                    userSession.updateUser(state.session?.user)
                }
            }
        }
    }
}
