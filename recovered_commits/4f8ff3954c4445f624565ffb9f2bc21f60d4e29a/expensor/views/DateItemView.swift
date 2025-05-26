//import SwiftUI
//
//struct DateItemView: View {
//    let date: Date
//    let isSelected: Bool
//    let expenseCount: Int
//
//    var body: some View {
//        VStack(spacing: 4) {
//            Text(dayString)
//                .fontWeight(isSelected ? .bold : .regular)
//                .foregroundColor(isSelected ? .white : .primary)
//                .frame(width: 36, height: 36)
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(isSelected ? Color.blue : Color.clear)
//                )
//                .overlay(
//                    RoundedRectangle(cornerRadius: 10)
//                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
//                )
//            ExpenseIndicator(count: expenseCount)
//                .frame(height: 8)
//        }
//        .frame(width: 40)
//        .contentShape(Rectangle())
//    }
//
//    private var dayString: String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "d"
//        return formatter.string(from: date)
//    }
//}
