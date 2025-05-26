import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showPlusDrawer = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)

            ReceiptsView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Receipts")
                }
                .tag(1)

            IncomesView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Incomes")
                }
                .tag(2)

            Color.clear
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Plus")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
                .tag(4)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 3 {
                showPlusDrawer = true
                selectedTab = 0 // Return to Dashboard after opening drawer
            }
        }
        .sheet(isPresented: $showPlusDrawer) {
            PlusDrawerView(isPresented: $showPlusDrawer)
        }
    }
}

// Mock views for each tab
struct DashboardView: View { var body: some View { Text("Dashboard Page") } }
struct IncomesView: View { var body: some View { Text("Incomes Page") } }
struct ProfileView: View { var body: some View { Text("Profile Page") } }

// Drawer with 4 mock buttons
struct PlusDrawerView: View {
    @Binding var isPresented: Bool
    var body: some View {
        VStack(spacing: 24) {
            Text("Quick Actions").font(.headline)
            ForEach(1...4, id: \.self) { i in
                Button("Action \(i)") { }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
            Button("Close") { isPresented = false }
                .padding(.top, 32)
        }
        .padding()
    }
}

#Preview  {
    MainTabView()
}
