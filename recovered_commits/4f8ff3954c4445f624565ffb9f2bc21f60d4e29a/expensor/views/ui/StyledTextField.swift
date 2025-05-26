import SwiftUI

struct StyledTextField: View {
    let icon: String?
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isDisabled: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(isFocused ? .indigo : .gray)
            }

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .disabled(isDisabled)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.indigo : Color.gray.opacity(0.2), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.07), radius: 2, x: 0, y: 1)
    }
}

// Int version
struct StyledIntTextField: View {
    let icon: String?
    let placeholder: String
    @Binding var value: Int
    var isDisabled: Bool = false
    
    // For internal use to handle the text conversion
    @State private var textValue: String
    
    @FocusState private var isFocused: Bool
    
    init(icon: String? = nil, placeholder: String, value: Binding<Int>, isDisabled: Bool = false) {
        self.icon = icon
        self.placeholder = placeholder
        self._value = value
        self.isDisabled = isDisabled
        // Initialize the text representation of the Int
        self._textValue = State(initialValue: "\(value.wrappedValue)")
    }
    
    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(isFocused ? .indigo : .gray)
            }
            
            TextField(placeholder, text: $textValue)
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .disabled(isDisabled)
                .onChange(of: textValue) { newValue in
                    // Convert textValue to Int when it changes
                    if let intValue = Int(newValue) {
                        value = intValue
                    }
                }
                .onChange(of: value) { newValue in
                    // Update textValue if the bound value changes externally
                    if textValue != "\(newValue)" {
                        textValue = "\(newValue)"
                    }
                }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.indigo : Color.gray.opacity(0.2), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.07), radius: 2, x: 0, y: 1)
    }
}

// Double version
struct StyledDoubleTextField: View {
    let icon: String?
    let placeholder: String
    @Binding var value: Double
    var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    var isDisabled: Bool = false
    
    // For internal use to handle the text conversion
    @State private var textValue: String
    
    @FocusState private var isFocused: Bool
    
    init(icon: String? = nil, placeholder: String, value: Binding<Double>,
         formatter: NumberFormatter? = nil, isDisabled: Bool = false) {
        self.icon = icon
        self.placeholder = placeholder
        self._value = value
        if let formatter = formatter {
            self.formatter = formatter
        }
        self.isDisabled = isDisabled
        // Initialize with formatted value
        self._textValue = State(initialValue: formatter?.string(from: NSNumber(value: value.wrappedValue)) ?? "\(value.wrappedValue)")
    }
    
    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(isFocused ? .indigo : .gray)
            }
            
            TextField(placeholder, text: $textValue)
                .keyboardType(.decimalPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .disabled(isDisabled)
                .onChange(of: textValue) { newValue in
                    // Handle locale-specific decimal separators
                    let filteredValue = newValue.replacingOccurrences(of: ",", with: ".")
                    if let doubleValue = Double(filteredValue) {
                        value = doubleValue
                    }
                }
                .onChange(of: value) { newValue in
                    // Format the value using the formatter when it changes externally
                    let formattedValue = formatter.string(from: NSNumber(value: newValue)) ?? "\(newValue)"
                    if textValue != formattedValue {
                        textValue = formattedValue
                    }
                }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.indigo : Color.gray.opacity(0.2), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.07), radius: 2, x: 0, y: 1)
    }
}
