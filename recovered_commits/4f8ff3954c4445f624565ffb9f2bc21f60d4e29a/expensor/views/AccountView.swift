import SwiftUI

struct AccountView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""

    var body: some View {
        Form {
            Section(header: Text("Account Details")) {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                TextField("Phone", text: $phone)
            }
            Section {
                Button("Update Details") {
                    // Save logic here
                }
            }
        }
        .navigationTitle("Account")
    }
}
