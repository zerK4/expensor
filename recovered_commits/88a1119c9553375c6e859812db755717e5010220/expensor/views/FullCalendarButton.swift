import SwiftUI

struct FullCalendarButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "calendar")
                .font(.system(size: 20, weight: .bold))
        }
        .accessibilityLabel("Show full calendar")
    }
}
