import SwiftUI

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
                    Button("Log Out", role: .destructive, action: onLogout)
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
}
