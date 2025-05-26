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
        Category(name: "Food", icon: "fork.knife"),
        Category(name: "Transport", icon: "car"),
        Category(name: "Entertainment", icon: "movie"),
        Category(name: "Shopping", icon: "cart"),
        Category(name: "Bills", icon: "doc.text")
    ]
    
    @State var selectedCategory: String? = ""

    var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories, id: \.id) { item in
                        Button {
                            selectedCategory = item.name
                        } label: {
                            HStack {
                                if (item.name !== "All") {
                                    Image(item.icon)
                                        .foregroundColor(selectedCategory == item.name ? .yellow : .black)
                                }
                                Text(item.name)
                            }
                            .padding(20)
                            .background(selectedCategory == item.name ? .black : .gray.opacity(0.1))
                            .foregroundColor(selectedCategory !== item.name ? .black : .white)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
}
