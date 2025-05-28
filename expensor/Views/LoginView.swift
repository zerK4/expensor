import Foundation
import SwiftUI
import Supabase

enum AuthResultState: Equatable {
    case none
    case success
    case failure(String)
}

struct Currency: Identifiable, Equatable {
    let id: String
    let name: String
    let symbol: String
    let sfSymbol: String
}

let currencies: [Currency] = [
    Currency(id: "RON", name: "Romanian Leu", symbol: "RON", sfSymbol: "lirasign.circle"),
    Currency(id: "EUR", name: "Euro", symbol: "EUR", sfSymbol: "eurosign.circle"),
    Currency(id: "USD", name: "US Dollar", symbol: "USD", sfSymbol: "dollarsign.circle"),
    Currency(id: "GBP", name: "British Pound", symbol: "GBP", sfSymbol: "sterlingsign.circle"),
    Currency(id: "JPY", name: "Japanese Yen", symbol: "JPY", sfSymbol: "yensign.circle")
]

// Global style for the background grid and radial gradient
extension View {
    func minimalistBackground() -> some View {
        ZStack {
            Color.black.ignoresSafeArea() // Base black background
            
            // Grid lines
            GridBackground()
            
            // Radial gradient blur
            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.1), Color.black]),
                center: .top,
                startRadius: 0,
                endRadius: 700 // Adjust to control blur spread
            )
            .offset(y: -UIScreen.main.bounds.height * 0.3) // Position higher
            .ignoresSafeArea()
            .opacity(0.8) // Control visibility of the radial gradient
        }
    }
}

// Custom GridBackground View
struct GridBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let columns = Int(geometry.size.width / 14) // 14px grid size
                let rows = Int(geometry.size.height / 24)  // 24px grid size

                // Vertical lines
                for i in 0..<columns {
                    let x = CGFloat(i) * 14
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }

                // Horizontal lines
                for i in 0..<rows {
                    let y = CGFloat(i) * 24
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            // CORRECTED LINE HERE:
            .stroke(Color(red: 0.3098039329, green: 0.3098039329, blue: 0.3098039329, opacity: 0.18), lineWidth: 1)
            .drawingGroup() // Improves performance for complex paths
        }
    }
}


struct LoginView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var result: AuthResultState = .none
    @Namespace private var animation
    @FocusState private var emailFocused: Bool
    @State private var shake = false
    @State private var showSuccessCard = false
    @State private var showProfileSetup = false

    // Profile setup states
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedCurrencyId = currencies[0].id
    @State private var isSavingProfile = false
    @State private var profileError: String?

    var body: some View {
        ZStack {
            // New minimalist background
            minimalistBackground()

            VStack {
                Spacer()
                if showProfileSetup {
                    ProfileSetupCard(
                        firstName: $firstName,
                        lastName: $lastName,
                        selectedCurrencyId: $selectedCurrencyId,
                        isSaving: $isSavingProfile,
                        error: $profileError,
                        onSave: saveProfile
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(3)
                } else if showSuccessCard {
                    SuccessCard(animation: animation)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(2)
                } else {
                    loginCard
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
                Spacer()
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccessCard)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showProfileSetup)
        }
        .onOpenURL(perform: { url in
            Task {
                do {
                    try await SupabaseManager.shared.auth.session(from: url)
                    await checkProfile()
                } catch {
                    withAnimation { self.result = .failure(error.localizedDescription) }
                }
            }
        })
    }

    var loginCard: some View {
        VStack(spacing: 28) {
            Image(systemName: "creditcard.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.white)
                .shadow(radius: 8)
                .padding(.bottom, 8)
                .scaleEffect(isLoading ? 0.95 : 1.0)
                .animation(.spring(), value: isLoading)

            Text("Welcome to Expensor")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .matchedGeometryEffect(id: "title", in: animation)
            Text("Track your expenses effortlessly.\nSign in to continue.")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(emailFocused ? .blue : .gray) // Changed to blue
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($emailFocused)
                    .disabled(isLoading)
                    .preferredColorScheme(.dark) // Ensure dark keyboard appearance
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05)) // Minimalist fill
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(emailFocused ? Color.blue : Color.white.opacity(0.1), lineWidth: 1) // Blue border
                    )
            )
            .offset(x: shake ? -10 : 0)
            .animation(shake ? .default.repeatCount(3, autoreverses: true) : .default, value: shake)

            Button(action: signInButtonTapped) {
                Text(isLoading ? "Sending..." : "Send Magic Link")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue) // Solid blue button
                            .opacity(isLoading ? 0.7 : 1)
                    )
            }
            .disabled(isLoading || !isValidEmail(email))
            .scaleEffect(isLoading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLoading) // Smoother animation for button press

            if case .failure(let error) = result {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.4)) // Black with opacity
                .background(.ultraThinMaterial) // Background blur
                .cornerRadius(28) // Apply corner radius after blur
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1) // Subtle white stroke
                )
        )
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8) // Darker shadow
    }

    func signInButtonTapped() {
        guard isValidEmail(email) else {
            withAnimation {
                result = .failure("Please enter a valid email address.")
                shake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shake = false
            }
            return
        }
        Task {
            withAnimation { isLoading = true }
            defer { withAnimation { isLoading = false } }

            do {
                try await SupabaseManager.shared.auth.signInWithOTP(
                    email: email,
                    redirectTo: URL(string: "ro.expensor.tracker://login-callback")
                )
                withAnimation {
                    result = .success
                    showSuccessCard = true
                }
            } catch {
                withAnimation {
                    result = .failure(error.localizedDescription)
                    shake = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shake = false
                }
            }
        }
    }

    func checkProfile() async {
        guard let user = try? await SupabaseManager.shared.auth.session.user else { return }
        let response = try? await SupabaseManager.shared
            .from("profiles")
            .select()
            .eq("id", value: user.id.uuidString)
            .single()
            .execute()
        if response?.data == nil {
            withAnimation {
                showSuccessCard = false
                showProfileSetup = true
            }
        }
    }

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
            guard let user = try? await SupabaseManager.shared.auth.session.user else {
                profileError = "User not found."
                return
            }
            isSavingProfile = true
            do {
                try await SupabaseManager.shared
                    .from("profiles")
                    .insert([
                        "id": user.id.uuidString,
                        "first_name": firstName,
                        "last_name": lastName,
                        "currency": currency.id
                    ])
                    .execute()
                withAnimation { showProfileSetup = false }
            } catch {
                profileError = error.localizedDescription
            }
            isSavingProfile = false
        }
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
}

struct SuccessCard: View {
    var animation: Namespace.ID

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
                .scaleEffect(1.2)
                .shadow(radius: 8)
                .padding(.bottom, 8)
                .transition(.scale.combined(with: .opacity))

            Text("Magic Link Sent!")
                .font(.title.bold())
                .foregroundColor(.white)
                .matchedGeometryEffect(id: "title", in: animation)
            Text("Check your inbox for the magic link to sign in.")
                .font(.headline)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.4)) // Black with opacity
                .background(.ultraThinMaterial) // Background blur
                .cornerRadius(28)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
}

struct ProfileSetupCard: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var selectedCurrencyId: String
    @Binding var isSaving: Bool
    @Binding var error: String?
    var onSave: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Set up your profile")
                .font(.title.bold())
                .foregroundColor(.white)
            VStack(spacing: 12) {
                TextField("First Name", text: $firstName)
                    .textFieldStyle(.plain) // Use plain style for custom background
                    .padding()
                    .background(Color.white.opacity(0.05).cornerRadius(12)) // Minimalist fill
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1) // Subtle border
                    )
                    .foregroundColor(.white) // Text color
                    .autocapitalization(.words)
                    .preferredColorScheme(.dark)

                TextField("Last Name", text: $lastName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.05).cornerRadius(12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .foregroundColor(.white)
                    .autocapitalization(.words)
                    .preferredColorScheme(.dark)
            }
            
            // Customizing the Picker
            Picker("Currency", selection: $selectedCurrencyId) {
                ForEach(currencies) { currency in
                    HStack {
                        Image(systemName: currency.sfSymbol)
                        Text("\(currency.symbol) - \(currency.name)")
                    }
                    .foregroundColor(.white) // Ensure text color is white
                    .tag(currency.id)
                }
            }
            .pickerStyle(.menu) // Keeps it as a dropdown menu
            .padding(.horizontal)
            .background(Color.white.opacity(0.05).cornerRadius(12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .accentColor(.white) // Changes the chevron color on iOS 15+
            
            Button(action: onSave) {
                ZStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save Profile")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue) // Solid blue button
                        .opacity(isSaving ? 0.7 : 1)
                )
            }
            .disabled(isSaving || firstName.trimmingCharacters(in: .whitespaces).isEmpty || lastName.trimmingCharacters(in: .whitespaces).isEmpty)
            .scaleEffect(isSaving ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSaving)

            if let error = error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(.ultraThinMaterial)
                .cornerRadius(28)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
}

#Preview {
    LoginView()
}
