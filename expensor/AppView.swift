import Foundation
import SwiftUI

struct AppView: View {
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
                TabView(selection: $selectedTab) {
                    // Expenses Tab
                    EntriesView()
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("Expenses")
                        }
                        .tag(0)

                    Color.clear
                        .tabItem {
                            Image(systemName: "square.grid.2x2")
                            Text("Categories")
                        }
                        .tag(1)
                    
                    Color.clear
                        .tabItem {
                            Image(systemName: "plus")
                            Text("Add")
                        }
                        .tag(2)

                    // Profile Tab
                    Color.clear
                        .tabItem {
                            Image(systemName: "person.crop.circle")
                            Text("Profile")
                        }
                        .tag(3)
                }
                .onChange(of: selectedTab) { _, newValue in
                    if newValue == 2 {
                        showAddReceipt = true
                        selectedTab = 0
                    } else if newValue == 3 {
                        showUserMenu = true
                        selectedTab = 0
                    } else if newValue == 1 {
                        showCategories = true
                        selectedTab = 0
                    }
                }
                .sheet(isPresented: $showAddReceipt) {
                    AddReceiptView()
                }
                .sheet(isPresented: $showUserMenu) {
                    UserMenuView(isPresented: $showUserMenu,
                                 showAccount: $showAccount,
                                 showBilling: $showBilling,
                                 onLogout: {
                                     // Add your logout logic here
                                 })
                }
                .sheet(isPresented: $showCategories) {
                    CategoriesView()
                }
            } else {
                AuthView()
            }
        }
        .task {
            for await state in SupabaseManager.shared.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    isAuthenticated = state.session != nil
                }
            }
        }
    }
}

#Preview {
    AppView()
}
