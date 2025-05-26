import SwiftUI

let currencies: [Currency] = [
    Currency(id: "EUR", name: "Euro", symbol: "€", sfSymbol: "eurosign.circle"),
    Currency(id: "USD", name: "US Dollar", symbol: "$", sfSymbol: "dollarsign.circle"),
    Currency(id: "GBP", name: "British Pound", symbol: "£", sfSymbol: "sterlingsign.circle"),
    Currency(id: "RON", name: "Romanian Leu", symbol: "lei", sfSymbol: "l.circle")
]

struct ProfileSetupView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var selectedCurrencyId: String
    @Binding var isSaving: Bool
    @Binding var error: String?
    var onSave: () -> Void
    var onRefresh: (() async -> Void)? = nil

    @State private var animateGradient = false
    @FocusState private var focusedField: Field?
    @State private var showCurrencySheet = false
    @State private var currencySearch = ""

    enum Field { case firstName, lastName }

    var selectedCurrency: Currency? {
        currencies.first { $0.id == selectedCurrencyId }
    }

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

                GeometryReader { geometry in
                    ScrollView {
                        VStack {
                            profileCard
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        .frame(minHeight: geometry.size.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSaving)
                    }
                    .refreshable {
                        await onRefresh?()
                    }
                }
            }
        }

    var profileCard: some View {
        VStack(spacing: 28) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.white)
                .shadow(radius: 8)
                .padding(.bottom, 8)

            Text("Set up your profile")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            VStack(spacing: 14) {
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(focusedField == .firstName ? .indigo : .gray)
                    TextField("First Name", text: $firstName)
                        .autocapitalization(.words)
                        .focused($focusedField, equals: .firstName)
                        .disabled(isSaving)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground).opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .firstName ? Color.indigo : Color.gray.opacity(0.2), lineWidth: 2)
                        )
                )

                HStack {
                    Image(systemName: "person")
                        .foregroundColor(focusedField == .lastName ? .indigo : .gray)
                    TextField("Last Name", text: $lastName)
                        .autocapitalization(.words)
                        .focused($focusedField, equals: .lastName)
                        .disabled(isSaving)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground).opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .lastName ? Color.indigo : Color.gray.opacity(0.2), lineWidth: 2)
                        )
                )
            }

            Button {
                showCurrencySheet = true
            } label: {
                HStack {
                    if let currency = selectedCurrency {
                        Image(systemName: currency.sfSymbol)
                        Text("\(currency.symbol) - \(currency.name)")
                            .foregroundColor(.primary)
                    } else {
                        Text("Select Currency")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground).opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                        )
                )
            }
            .sheet(isPresented: $showCurrencySheet) {
                NavigationView {
                    VStack {
                        TextField("Search currency", text: $currencySearch)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        List {
                            ForEach(
                                currencies.filter {
                                    currencySearch.isEmpty ||
                                    $0.name.localizedCaseInsensitiveContains(currencySearch) ||
                                    $0.symbol.localizedCaseInsensitiveContains(currencySearch)
                                }
                            ) { currency in
                                Button {
                                    selectedCurrencyId = currency.id
                                    showCurrencySheet = false
                                    currencySearch = ""
                                } label: {
                                    HStack {
                                        Image(systemName: currency.sfSymbol)
                                        Text("\(currency.symbol) - \(currency.name)")
                                        if selectedCurrencyId == currency.id {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.indigo)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                    .navigationTitle("Select Currency")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showCurrencySheet = false
                                currencySearch = ""
                            }
                        }
                    }
                }
            }

            Button(action: onSave) {
                ZStack {
                    LinearGradient(
                        colors: [Color.indigo, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .cornerRadius(14)
                    .frame(height: 50)
                    .opacity(isSaving ? 0.7 : 1)

                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isSaving ? "Saving..." : "Save Profile")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .cornerRadius(14)
            .shadow(color: .indigo.opacity(0.15), radius: 8, x: 0, y: 4)
            .disabled(isSaving || firstName.trimmingCharacters(in: .whitespaces).isEmpty || lastName.trimmingCharacters(in: .whitespaces).isEmpty || selectedCurrencyId.isEmpty)

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
    ProfileSetupView(
        firstName: .constant("Sebastian"),
        lastName: .constant("Pavel"),
        selectedCurrencyId: .constant("RON"),
        isSaving: .constant(false),
        error: .constant(nil),
        onSave: { print("Save action triggered") },
        onRefresh: { await Task.sleep(1_000_000_000) }
    )
}
