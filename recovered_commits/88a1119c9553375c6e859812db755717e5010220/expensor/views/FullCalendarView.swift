// FullCalendarView.swift
import SwiftUI

struct FullCalendarView: View {
    let month: Date
    let datesWithExpenses: Set<Date>
    @Binding var selectedDate: Date?
    let expenseCountForDate: (Date) -> Int

    private var days: [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        var days: [Date] = []
        var date = monthInterval.start
        while date < monthInterval.end {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return days
    }

    private var firstWeekday: Int {
        Calendar.current.component(.weekday, from: days.first ?? Date())
    }

    private let weekdaySymbols = Calendar.current.shortStandaloneWeekdaySymbols

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            // Calendar grid
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<firstWeekday-1, id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }
                ForEach(days, id: \.self) { date in
                    let hasExpense = datesWithExpenses.contains(Calendar.current.startOfDay(for: date))
                    DateItemView(
                        date: date,
                        isSelected: selectedDate == date,
                        expenseCount: hasExpense ? expenseCountForDate(date) : 0
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
