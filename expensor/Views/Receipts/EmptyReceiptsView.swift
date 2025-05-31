import SwiftUI

struct EmptyReceiptsView: View {
    @EnvironmentObject var receiptsViewModel: ReceiptsViewModel
    @State private var showPlusDrawer = false
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Animated background circle
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 0.6 : 0.3)

                // Receipt icon
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            }
            .animation(
                .spring(response: 1.5, dampingFraction: 0.5)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )

            VStack(spacing: 12) {
                Text("No Receipts Yet")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .opacity(isAnimating ? 1 : 0.7)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)

                Text("Start tracking your expenses by adding your first receipt. You can scan, upload, or enter details manually.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
            }

            // Action buttons
            actionButtons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showPlusDrawer) {
            PlusDrawerView(receiptsViewModel: _receiptsViewModel, isPresented: $showPlusDrawer)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            isAnimating = true
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
                        .font(.system(size: 20))
                    Text("Add Receipt")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.blue)
                .cornerRadius(28)
                .shadow(color: Color.blue.opacity(0.3), radius: 15, x: 0, y: 8)
                .scaleEffect(isAnimating ? 1.02 : 0.98)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.6)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            }
        }
        .padding(.top, 16)
    }
}

#Preview {
    EmptyReceiptsView()
        .environmentObject(ReceiptsViewModel(userSession: UserSession())) // Provide mock ViewModel for preview
}
