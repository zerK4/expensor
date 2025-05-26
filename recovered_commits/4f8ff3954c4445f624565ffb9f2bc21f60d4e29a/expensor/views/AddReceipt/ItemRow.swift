import Foundation
import SwiftUI

struct ItemRow: View {
    @Binding var item: Item
    var showDeleteButton: Bool
    var onDelete: () -> Void
    var updateTotal: (Double, Int) -> Void

    @State private var animateTotal = false
    @Namespace private var animation

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                StyledTextField(
                    icon: "pencil",
                    placeholder: "Item Name",
                    text: $item.name
                )
                if showDeleteButton {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                            .scaleEffect(showDeleteButton ? 1.0 : 0.8)
                            .animation(.spring(), value: showDeleteButton)
                    }
                    .transition(.scale)
                }
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Qty:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    StyledIntTextField(
                        icon: "number",
                        placeholder: "1",
                        value: $item.quantity
                    )
                    .onChange(of: item.quantity) { newValue in
                        if newValue <= 0 {
                            item.quantity = 1
                        }
                        updateTotal(item.unitPrice, item.quantity)
                        animateTotalChange()
                    }
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Price:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    StyledDoubleTextField(
                        icon: "number",
                        placeholder: "0.00",
                        value: $item.unitPrice
                    )
                    .onChange(of: item.unitPrice) { newValue in
                        updateTotal(newValue, item.quantity)
                        animateTotalChange()
                    }
                }
            }

            HStack {
                Text("Total:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(NumberFormatter.currencyFormatter.string(from: NSNumber(value: item.total)) ?? "$0.00")
                    .font(.headline)
                    .foregroundColor(animateTotal ? .accentColor : .primary)
                    .scaleEffect(animateTotal ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: animateTotal)
                    .id(item.total)
                Spacer()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                .matchedGeometryEffect(id: "itemRowCard\(item.id)", in: animation)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: item)
    }

    private func animateTotalChange() {
        animateTotal = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateTotal = false
        }
    }
}

#Preview {
    AddReceiptView()
}
