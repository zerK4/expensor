import SwiftUI

struct DateItemView: View {
    let date: Date
    let isSelected: Bool
    let expenseCount: Int
    
    var body: some View {
        VStack(spacing: 1) {
            if !Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year) {
                Text(yearString)
                    .font(.system(size: 8))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            Text(dayOfWeek)
                .font(.caption2)
                .foregroundColor(isSelected ? .white : .secondary)
            Text(dayOfMonth)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white : .primary)
            if expenseCount > 0 {
                ZStack {
                    let size = min(expenseCount, 3) * 2 + 4
                    Circle()
                        .fill(Color.red)
                        .frame(width: CGFloat(size), height: CGFloat(size))
                }
                .padding(.top, 1)
            } else {
                Spacer().frame(height: 6)
            }
        }
        .frame(width: 40, height: 52)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    private var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    private var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
}
