//
//  CategoryPicker.swift
//  expensor
//
//  Created by Sebastian Pavel on 22.05.2025.
//

import Foundation
import SwiftUI

struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: Category?
    let categories: [Category]

    func iconView(for icon: String) -> some View {
        // Try to create an SF Symbol image; fallback to text if not available
        if UIImage(systemName: icon) != nil {
            return AnyView(Image(systemName: icon))
        } else {
            return AnyView(Text(icon))
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    Button {
                        selectedCategory = category
                        dismiss()
                    } label: {
                        HStack {
                            iconView(for: category.icon)
                                .font(.title2)
                            Text(category.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
