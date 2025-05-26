import SwiftUI

struct ThemePickerView: View {
    @Binding var colorScheme: ColorScheme?

    var body: some View {
        Form {
            Picker("Theme", selection: $colorScheme) {
                Text("System").tag(nil as ColorScheme?)
                Text("Light").tag(ColorScheme.light as ColorScheme?)
                Text("Dark").tag(ColorScheme.dark as ColorScheme?)
            }
            .pickerStyle(.segmented)
        }
        .navigationTitle("Theme")
    }
}
