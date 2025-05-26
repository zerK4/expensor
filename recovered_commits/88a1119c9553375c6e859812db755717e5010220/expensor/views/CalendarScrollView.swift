import SwiftUI

struct CalendarScrollView: View {
    let dates: [Date]
    @Binding var selectedDate: Date?
    let expenseCountForDate: (Date) -> Int

    @State private var showFullCalendar = false
    private let today = Calendar.current.startOfDay(for: Date())

    private var groupedDates: [(month: String, days: [Date])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let grouped = Dictionary(grouping: dates) { date in
            formatter.string(from: date)
        }
        return grouped
            .map { (month: $0.key, days: $0.value.sorted()) }
            .sorted { $0.days.first! < $1.days.first! }
    }

    private var initialMonth: String? {
        let pastOrToday = dates.filter { $0 <= today }
        let closest = pastOrToday.max() ?? dates.min()
        guard let closest else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: closest)
    }

    private var selectedOrTodayMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        if let selected = selectedDate {
            return formatter.string(from: selected)
        }
        return formatter.string(from: today)
    }

    private var todayDayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Calendar scroll view
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 24) {
                        ForEach(groupedDates, id: \.month) { group in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.month)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                    .id(group.month)
                                LazyHStack(spacing: 6) {
                                    ForEach(group.days, id: \.self) { date in
                                        DateItemView(
                                            date: date,
                                            isSelected: selectedDate == date,
                                            expenseCount: expenseCountForDate(date)
                                        )
                                        .id(date)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                if selectedDate == date {
                                                    selectedDate = nil
                                                } else {
                                                    selectedDate = date
                                                    scrollProxy.scrollTo(date, anchor: .center)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 80)
                .onAppear {
                    if let month = initialMonth {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollProxy.scrollTo(month, anchor: .center)
                        }
                    }
                }
            }
            .frame(height: 80)
            .alignmentGuide(.top) { d in d[.top] }

            VStack(alignment: .trailing, spacing: 12) {
                // Show only the month of selected date or today
                Text(selectedOrTodayMonth)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                HStack(spacing: 8) {
//                    Button {
//                        withAnimation(.spring()) {
//                            if selectedDate == today {
//                                selectedDate = nil
//                            } else {
//                                selectedDate = today
//                            }
//                        }
//                    } label: {
//                        Text(todayDayNumber)
//                            .font(.system(size: 16, weight: .semibold))
//                            .frame(width: 36, height: 36)
//                    }
//                    .background(
//                        RoundedRectangle(cornerRadius: 10)
//                            .fill(Color(UIColor.systemBackground))
//                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
//                    )
//                    .foregroundColor(.primary)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 10)
//                            .stroke(Color.accentColor, lineWidth: 1)
//                    )

                    FullCalendarButton {
                        showFullCalendar = true
                    }
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor)
                    )
                    .foregroundColor(.white)
                }
            }
            .frame(height: 80, alignment: .top)
            .alignmentGuide(.top) { d in d[.top] }
            .padding(.trailing, 8)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .center)
        .sheet(isPresented: $showFullCalendar) {
            FullCalendarModal(
                dates: dates,
                selectedDate: $selectedDate,
                expenseCountForDate: expenseCountForDate
            )
        }
    }
}

struct ExpenseIndicator: View {
    let count: Int

    var body: some View {
        GeometryReader { geo in
            if count == 1 {
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            } else if count > 1 {
                let maxWidth = geo.size.width - 8
                let minWidth: CGFloat = 12
                let width = min(maxWidth, minWidth + CGFloat(count - 1) * 8)
                Capsule()
                    .fill(Color.red)
                    .frame(width: width, height: 6)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }
}

#Preview {
    CalendarScrollView(
        dates: [
            Date(),
            Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        ],
        selectedDate: .constant(nil),
        expenseCountForDate: { _ in Int.random(in: 0...3) }
    )
}
