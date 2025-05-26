import SwiftUI

struct TabBar: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
//            EntriesView()
//                .tabItem {
//                    Image(systemName: "list.bullet")
//                }
//                .tag(0)
//
//            CategoriesView()
//                .tabItem {
//                    Image(systemName: "square.grid.2x2")
//                }
//                .tag(1)
//
//            AddReceiptView()
//                .tabItem {
//                    Image(systemName: "plus.circle")
//                }
//                .tag(2)

//            UserMenuView(isPresented: .constant(false), showAccount: .constant(false), showBilling: .constant(false), onLogout: {})
//                .tabItem {
//                    Image(systemName: "person.crop.circle")
//                }
//                .tag(3)
        }
        .accentColor(.primary) // Use system color for a minimalist look
    }
}

#Preview {
    TabBar()
}
