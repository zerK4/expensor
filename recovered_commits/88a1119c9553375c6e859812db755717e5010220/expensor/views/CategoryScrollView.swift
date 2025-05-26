import SwiftUI

struct CategoryScrollView: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    Button {
                        withAnimation(.spring()) {
                            selectedCategory = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "tag")
                                .font(.system(size: 12))
                            Text("All")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == nil ? Color.blue : Color(UIColor.systemBackground))
                        )
                        .foregroundColor(selectedCategory == nil ? .white : .primary)
                    }
                    ForEach(categories) { category in
                        Button {
                            withAnimation(.spring()) {
                                if selectedCategory?.id == category.id {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                    scrollProxy.scrollTo(category.id, anchor: .leading)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 12))
                                Text(category.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory?.id == category.id ? Color.blue : Color(UIColor.systemBackground))
                            )
                            .foregroundColor(selectedCategory?.id == category.id ? .white : .primary)
                        }
                        .id(category.id)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        }
        .frame(height: 40)
    }
}
