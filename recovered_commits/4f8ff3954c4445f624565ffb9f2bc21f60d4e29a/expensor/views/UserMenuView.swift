import SwiftUI
import Supabase

struct UserMenuView: View {
    @Binding var isPresented: Bool
    @Binding var showAccount: Bool
    @Binding var showBilling: Bool
    let onLogout: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Account") { showAccount = true }
                    Button("Billing") { showBilling = true }
                }
                Section {
                    Button("Log Out", role: .destructive) {
                        Task {
                            await logout()
                        }
                    }
                }
            }
            .navigationTitle("User Menu")
            .navigationDestination(isPresented: $showAccount) {
                AccountView()
            }
            .navigationDestination(isPresented: $showBilling) {
                BillingView()
            }
        }
    }

    private func logout() async {
        do {
            try await supabase.auth.signOut()
            onLogout()
        } catch {
            // Optionally handle error (e.g., show an alert)
            print("Logout failed: \(error)")
        }
    }
}
