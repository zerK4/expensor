import Foundation
import SwiftUI
import Supabase

// Example Currency model and list
struct Currency: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let sfSymbol: String
}

struct AppView: View {
    @State private var isAuthenticated = false
    @State private var isProfileComplete = false
    @State private var isLoadingProfile = false
    @State private var selectedTab = 0
    @State private var showAddReceipt = false
    @State private var showCategories = false
    @State private var showUserMenu = false
    @State private var showAccount = false
    @State private var showBilling = false

    // Profile setup states
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedCurrencyId = currencies[0].id
    @State private var isSavingProfile = false
    @State private var profileError: String?

    @Namespace private var animation
    @State private var animateGradient = false
    
    @StateObject private var expenseViewModel = ExpenseViewModel()

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple, .indigo, .cyan]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animateGradient)
            .onAppear { animateGradient = true }

            Group {
                if isLoadingProfile {
                    LoadingCard()
                } else if !isAuthenticated {
                    AuthView()
                } else if isAuthenticated && !isProfileComplete {
                    ProfileSetupView(
                        firstName: $firstName,
                        lastName: $lastName,
                        selectedCurrencyId: $selectedCurrencyId,
                        isSaving: $isSavingProfile,
                        error: $profileError,
                        onSave: saveProfile,
                        onRefresh: refreshProfile
                    )
                } else {
                    TabView(selection: $selectedTab) {
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
                        Color.clear
                            .tabItem {
                                Image(systemName: "person.crop.circle")
                                Text("Profile")
                            }
                            .tag(3)
                    }
                    .environmentObject(expenseViewModel)
                    .onChange(of: selectedTab) { newValue in
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
                            .environmentObject(expenseViewModel)
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
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isLoadingProfile)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isProfileComplete)
        }
        .task {
            for await state in supabase.auth.authStateChanges {
                isAuthenticated = state.session != nil
                if isAuthenticated {
                    await fetchProfile()
                } else {
                    isProfileComplete = false
                }
            }
        }
        .onAppear {
            Task {
                isAuthenticated = (try? await supabase.auth.session.user) != nil
                if isAuthenticated {
                    await fetchProfile()
                }
            }
        }
    }

    
    func fetchProfile() async {
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        guard let user = try? await supabase.auth.session.user else {
            isProfileComplete = false
            print("No user session found.")
            return
        }
        let userId = user.id.uuidString.lowercased()
        print("Fetching profile for user id: \(userId)")
        do {
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            print("Fetched profile: \(profile)")
            firstName = profile.first_name
            lastName = profile.last_name
            selectedCurrencyId = profile.currency
            isProfileComplete = !firstName.isEmpty && !lastName.isEmpty && !selectedCurrencyId.isEmpty
            print("isProfileComplete: \(isProfileComplete)")
        } catch {
            isProfileComplete = false
            print("Failed to decode profile: \(error)")
        }
    }
    
    func refreshProfile() async {
        await fetchProfile()
    }
    // Save profile data
    func saveProfile() {
        profileError = nil
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else {
            profileError = "First name is required."
            return
        }
        guard !lastName.trimmingCharacters(in: .whitespaces).isEmpty else {
            profileError = "Last name is required."
            return
        }
        guard let currency = currencies.first(where: { $0.id == selectedCurrencyId }) else {
            profileError = "Please select a currency."
            return
        }
        Task {
            guard let user = try? await supabase.auth.session.user else {
                profileError = "User not found."
                return
            }
            let userId = user.id.uuidString.lowercased()
            isSavingProfile = true
            do {
                try await supabase
                    .from("profiles")
                    .insert([
                        "id": userId,
                        "first_name": firstName,
                        "last_name": lastName,
                        "currency": currency.id
                    ])
                    .execute()
                await fetchProfile()
            } catch {
                profileError = error.localizedDescription
            }
            isSavingProfile = false
        }
    }}


struct LoadingCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 8)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2)
        }
        .frame(width: 120, height: 120)
        .padding()
    }
}

#Preview {
    AppView()
}
