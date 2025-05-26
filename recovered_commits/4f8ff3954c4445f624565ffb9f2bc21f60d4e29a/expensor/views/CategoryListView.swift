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
        Category(id: "askdjn", userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "All", icon: "list"),
        Category(id: "1i2u2h", userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "Food", icon: "fork.knife"),
        Category(id: "asdasd", userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "Transport", icon: "car"),
        Category(id: "asdsD", userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "Entertainment", icon: "movieclapper"),
        Category(id: "asdas22D", userId: "6cb602a5-cc17-4bf2-80af-8c4a7d9e7dac", name: "Shopping", icon: "cart"),
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
