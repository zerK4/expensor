import SwiftUI

struct EmptyReceiptsView: View {
    @EnvironmentObject var receiptsViewModel: ReceiptsViewModel
    @State private var showAddReceipt = false
    @State private var showPlusDrawer = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("No Receipts Yet")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("Start tracking your expenses by adding your first receipt. You can scan, upload, or enter details manually.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }
            
            // Action buttons
            actionButtons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showPlusDrawer) {
            PlusDrawerView(isPresented: $showPlusDrawer)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Primary action button
            Button(action: {
                showPlusDrawer = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Receipt")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.2), radius: 10, y: 5)
            }
        }
        .padding(.top, 16)
    }
}

#Preview {
    EmptyReceiptsView()
        .environmentObject(ReceiptsViewModel(userSession: UserSession()))
}
