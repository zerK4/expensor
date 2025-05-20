import SwiftUI

struct BillingView: View {
    @State private var showUpgrade = false

    var body: some View {
        Form {
            Section(header: Text("Current Plan")) {
                VStack(alignment: .leading) {
                    Text("Pro Plan")
                        .font(.headline)
                    Text("Unlimited receipts, priority support")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Section {
                Button("Upgrade Plan") {
                    showUpgrade = true
                }
            }
        }
        .navigationTitle("Billing")
        .sheet(isPresented: $showUpgrade) {
            // Add your upgrade view here
            Text("Upgrade Options Coming Soon")
                .font(.title)
        }
    }
}
