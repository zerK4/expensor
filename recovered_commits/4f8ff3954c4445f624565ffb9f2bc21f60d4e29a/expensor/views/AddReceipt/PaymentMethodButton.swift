//
//  PaymenMethodButton.swift
//  expensor
//
//  Created by Sebastian Pavel on 22.05.2025.
//

import Foundation
import SwiftUI

struct PaymentMethodButton: View {
    let method: AddReceiptView.PaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: method == .card ? "creditcard" : "banknote")
                    .font(.system(size: 24))
                Text(method.rawValue)
                    .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .foregroundColor(isSelected ? .accentColor : .primary)
    }
}
