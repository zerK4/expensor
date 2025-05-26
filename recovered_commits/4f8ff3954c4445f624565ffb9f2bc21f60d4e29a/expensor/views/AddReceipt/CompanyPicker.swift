//
//  CompanyPicker.swift
//  expensor
//
//  Created by Sebastian Pavel on 22.05.2025.
//

import Foundation
import SwiftUI

struct CompanyPickerSheet: View {
    let companies: [Company]
    var onSelect: (Company) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filtered: [Company] {
        if searchText.isEmpty { return companies }
        return companies.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search company...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                List(filtered) { comp in
                    Button {
                        onSelect(comp)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(comp.name)
                            if let cif = comp.cif {
                                Text(cif)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Company")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
