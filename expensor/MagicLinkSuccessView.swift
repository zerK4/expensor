// MagicLinkSuccessView.swift
// View shown after successful magic link authentication

import SwiftUI

struct MagicLinkSuccessView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)
            Text("You're logged in!")
                .font(.title.bold())
            Text("Welcome to Expensor.")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}
