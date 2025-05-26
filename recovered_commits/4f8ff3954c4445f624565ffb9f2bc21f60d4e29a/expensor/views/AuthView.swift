import Foundation
import SwiftUI
import Supabase

struct AuthView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var result: AuthResultState = .none
    @Namespace private var animation
    @FocusState private var emailFocused: Bool
    @State private var shake = false
    @State private var animateGradient = false
    @State private var showSuccessCard = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple, .indigo, .cyan]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animateGradient)
            .onAppear { animateGradient = true }

            VStack {
                Spacer()
                if showSuccessCard {
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
        }
        .onOpenURL(perform: { url in
            Task {
                do {
                    try await supabase.auth.session(from: url)
                    withAnimation { showSuccessCard = false }
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
                    .foregroundColor(emailFocused ? .indigo : .gray)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($emailFocused)
                    .disabled(isLoading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(emailFocused ? Color.indigo : Color.gray.opacity(0.2), lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.07), radius: 2, x: 0, y: 1)
            .offset(x: shake ? -10 : 0)
            .animation(shake ? .default.repeatCount(3, autoreverses: true) : .default, value: shake)

            Button(action: signInButtonTapped) {
                ZStack {
                    LinearGradient(
                        colors: [Color.indigo, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .cornerRadius(14)
                    .frame(height: 50)
                    .opacity(isLoading ? 0.7 : 1)

                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isLoading ? "Sending..." : "Send Magic Link")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .cornerRadius(14)
            .shadow(color: .indigo.opacity(0.15), radius: 8, x: 0, y: 4)
            .disabled(isLoading || !isValidEmail(email))
            .scaleEffect(isLoading ? 0.98 : 1.0)
            .animation(.easeInOut, value: isLoading)

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
                .fill(.ultraThickMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                )
        )
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 8)
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
                try await supabase.auth.signInWithOTP(
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
                .fill(.ultraThickMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                )
        )
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 8)
    }
}

#Preview {
    AuthView()
}
