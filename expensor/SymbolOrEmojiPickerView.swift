import SwiftUI

struct SymbolOrEmojiPickerView: View {
    @Binding var selected: String
    @State private var selectionType: PickerType = .sfSymbol
    @State private var sfSymbols: [String] = []

    enum PickerType: String, CaseIterable, Identifiable {
        case sfSymbol = "SF Symbols"
        case emoji = "Emoji"
        var id: String { rawValue }
    }

    // Generate a basic emoji list (expand as needed)
    let emojis: [String] = (0x1F600...0x1F64F).compactMap { UnicodeScalar($0).map { String($0) } }

    var body: some View {
        VStack {
            Picker("Type", selection: $selectionType) {
                ForEach(PickerType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            ScrollView {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6)) {
                    ForEach(selectionType == .sfSymbol ? sfSymbols : emojis, id: \.self) { symbol in
                        Group {
                            if selectionType == .sfSymbol {
                                Image(systemName: symbol)
                                    .font(.largeTitle)
                            } else {
                                Text(symbol)
                                    .font(.largeTitle)
                            }
                        }
                        .padding()
                        .background(selected == symbol ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                        .onTapGesture {
                            selected = symbol
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            if sfSymbols.isEmpty {
                loadSFSymbols()
            }
        }
    }

    // Load SF Symbol names from a bundled text file (one per line)
    func loadSFSymbols() {
        if let url = Bundle.main.url(forResource: "sfsymbols", withExtension: "txt"),
           let content = try? String(contentsOf: url) {
            sfSymbols = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        }
    }
}
