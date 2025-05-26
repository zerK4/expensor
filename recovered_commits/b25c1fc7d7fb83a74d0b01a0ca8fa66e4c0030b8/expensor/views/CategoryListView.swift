//
//  CategoryListView.swift
//  expensor
//
//  Created by Sebastian Pavel on 18.05.2025.
//

import Foundation
import SwiftUI

struct CategoryListView: View {
    @State private var categories = [
        Category(id: UUID(), name: "All", icon: "list"),
        Category(id: UUID(), name: "Food", icon: "fork.knife"),
        Category(id: UUID(), name: "Transport", icon: "car"),
        Category(id: UUID(), name: "Entertainment", icon: "movieclapper"),
        Category(id: UUID(), name: "Shopping", icon: "cart"),
    ]

    @State var selectedCategory: String? = ""

    var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories) { item in
                        Button {
                            selectedCategory = item.name
                        } label: {
                            HStack {
                                if (item.name != "All") {
                                    Image(systemName: item.icon)
                                }
                                Text(item.name)
                            }
                            .padding(10)
                            .background(selectedCategory == item.name ? Color(UIColor.darkGray) : Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(10)                        }
                    }
                }
            }
        }
    }
}

