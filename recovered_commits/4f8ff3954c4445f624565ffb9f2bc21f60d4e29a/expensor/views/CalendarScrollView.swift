import SwiftUI
import Foundation

// --- Previous helper structs remain the same ---
private struct MonthYearKey: Hashable {
    let month: Int
    let year: Int
}

struct CalendarScrollView: View {
    // MARK: - Properties
    let dates: [Date]
    @Binding var selectedDate: Date?
    let expenseCountForDate: (Date) -> Int

    @State private var showFullCalendar = false
    @State private var didScroll = false
    private let today = Calendar.current.startOfDay(for: Date())
    private let currentYear = Calendar.current.component(.year, from: Date())

    // MARK: - Static Formatters (Unchanged)
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    
    private static let monthAndYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    // MARK: - Computed Properties
    private var groupedDates: [(label: String, days: [Date])] {
        return groupDates(dates)
    }
    
    private var selectedOrTodayMonth: String {
        let dateToShow = selectedDate ?? today
        let year = Calendar.current.component(.year, from: dateToShow)
        
        if year == currentYear {
            return Self.monthFormatter.string(from: dateToShow)
        } else {
            return Self.monthAndYearFormatter.string(from: dateToShow)
        }
    }

    // Get the most recent date for scrolling
    private var mostRecentDate: Date? {
        return dates.sorted().last
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 24) {
                        ForEach(groupedDates, id: \.label) { group in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.label)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)

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
                                                selectedDate = (selectedDate == date) ? nil : date
                                                if selectedDate != nil {
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
                    if let recentDate = mostRecentDate {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                scrollProxy.scrollTo(recentDate, anchor: .trailing)
                            }
                        }
                    }
                }
                .onChange(of: dates) { _, _ in
                    if let recentDate = mostRecentDate {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                scrollProxy.scrollTo(recentDate, anchor: .trailing)
                            }
                        }
                    }
                }
            }
            .alignmentGuide(.top) { d in d[.top] }

            // --- The right-side button VStack remains unchanged ---
            VStack(alignment: .trailing, spacing: 12) {
                Text(selectedOrTodayMonth)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                FullCalendarButton { showFullCalendar = true }
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor))
                    .foregroundColor(.white)
            }
            .frame(height: 80, alignment: .top)
            .padding(.trailing, 8)
            .alignmentGuide(.top) { d in d[.top] }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showFullCalendar) {
            FullCalendarModal(
                dates: dates,
                selectedDate: $selectedDate,
                expenseCountForDate: expenseCountForDate
            )
        }
    }

    // --- Helper function remains the same ---
    private func groupDates(_ dates: [Date]) -> [(label: String, days: [Date])] {
        guard !dates.isEmpty else { return [] }
        
        let groupedByMonthYear = Dictionary(grouping: dates) { date -> MonthYearKey in
            let month = Calendar.current.component(.month, from: date)
            let year = Calendar.current.component(.year, from: date)
            return MonthYearKey(month: month, year: year)
        }

        let mapped = groupedByMonthYear.map { (key, days) -> (Date, String, [Date]) in
            let monthName = DateFormatter().monthSymbols[key.month - 1]
            let label = key.year == currentYear ? monthName : "\(monthName) \(key.year)"
            return (days.sorted().first!, label, days.sorted())
        }
        
        return mapped.sorted { $0.0 < $1.0 }.map { (_, label, days) in
            (label: label, days: days)
        }
    }
}

// MARK: - Supporting Views

struct DateItemView: View {
    let date: Date
    let isSelected: Bool
    let expenseCount: Int

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    var body: some View {
        VStack {
            Text(Self.weekdayFormatter.string(from: date))
                .font(.caption2)
                .foregroundColor(isSelected ? .white : .secondary)
            Text(Self.dayFormatter.string(from: date))
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white : .primary)
            
            ExpenseIndicator(count: expenseCount)
                .frame(height: 10)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .frame(width: 44)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
    }
}

struct FullCalendarButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "calendar")
        }
    }
}

struct FullCalendarModal: View {
    let dates: [Date]
    @Binding var selectedDate: Date?
    let expenseCountForDate: (Date) -> Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRangeStart: Date?
    @State private var selectedRangeEnd: Date?
    @State private var isSelectingRange = false
    
    private let calendar = Calendar.current
    private let today = Date()
    
    // Group dates by month and year for the grid view
    private var monthsAndYears: [(monthYear: Date, dates: [Date])] {
        let sortedDates = dates.sorted()
        guard !sortedDates.isEmpty else { return [] }
        
        let grouped = Dictionary(grouping: sortedDates) { date in
            calendar.dateInterval(of: .month, for: date)!.start
        }
        
        return grouped.map { (monthStart, monthDates) in
            (monthYear: monthStart, dates: monthDates.sorted())
        }.sorted { $0.monthYear < $1.monthYear }
    }
    
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(monthsAndYears, id: \.monthYear) { monthData in
                        MonthGridView(
                            monthYear: monthData.monthYear,
                            dates: monthData.dates,
                            selectedDate: $selectedDate,
                            selectedRangeStart: $selectedRangeStart,
                            selectedRangeEnd: $selectedRangeEnd,
                            isSelectingRange: $isSelectingRange,
                            expenseCountForDate: expenseCountForDate
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isSelectingRange ? "Single Select" : "Range Select") {
                        isSelectingRange.toggle()
                        // Clear range selection when switching modes
                        if !isSelectingRange {
                            selectedRangeStart = nil
                            selectedRangeEnd = nil
                        } else {
                            selectedDate = nil
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Scroll to the most recent month when modal appears
            // This could be implemented with ScrollViewReader if needed
        }
    }
}

struct MonthGridView: View {
    let monthYear: Date
    let dates: [Date]
    @Binding var selectedDate: Date?
    @Binding var selectedRangeStart: Date?
    @Binding var selectedRangeEnd: Date?
    @Binding var isSelectingRange: Bool
    let expenseCountForDate: (Date) -> Int
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    // Get all days in the month grid (including leading/trailing days from other months)
    private var monthDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthYear) else { return [] }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // Add leading empty days
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // Check if a date is in the selected range
    private func isInSelectedRange(_ date: Date) -> Bool {
        guard let start = selectedRangeStart, let end = selectedRangeEnd else { return false }
        let startDate = min(start, end)
        let endDate = max(start, end)
        return date >= startDate && date <= endDate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Self.monthYearFormatter.string(from: monthYear))
                .font(.headline)
                .padding(.horizontal)
            
            // Weekday headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<monthDays.count, id: \.self) { index in
                    if let date = monthDays[index] {
                        let hasExpenses = dates.contains(date)
                        let isSelected = selectedDate == date
                        let isRangeSelected = isInSelectedRange(date)
                        let isRangeStart = selectedRangeStart == date
                        let isRangeEnd = selectedRangeEnd == date
                        
                        VStack(spacing: 4) {
                            Text(Self.dayFormatter.string(from: date))
                                .font(.system(size: 16, weight: isSelected || isRangeStart || isRangeEnd ? .bold : .regular))
                                .foregroundColor({
                                    if isSelected || isRangeStart || isRangeEnd {
                                        return .white
                                    } else if isRangeSelected {
                                        return .primary
                                    } else if hasExpenses {
                                        return .primary
                                    } else {
                                        return .secondary
                                    }
                                }())
                            
                            if hasExpenses {
                                ExpenseIndicator(count: expenseCountForDate(date))
                                    .frame(height: 6)
                            } else {
                                Spacer()
                                    .frame(height: 6)
                            }
                        }
                        .frame(width: 40, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill({
                                    if isSelected || isRangeStart || isRangeEnd {
                                        return Color.accentColor
                                    } else if isRangeSelected {
                                        return Color.accentColor.opacity(0.3)
                                    } else {
                                        return Color.clear
                                    }
                                }())
                        )
                        .onTapGesture {
                            if hasExpenses {
                                handleDateTap(date)
                            }
                        }
                        .disabled(!hasExpenses)
                    } else {
                        // Empty space for leading/trailing days
                        Color.clear
                            .frame(width: 40, height: 50)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func handleDateTap(_ date: Date) {
        withAnimation(.spring()) {
            if isSelectingRange {
                if selectedRangeStart == nil {
                    selectedRangeStart = date
                    selectedRangeEnd = nil
                } else if selectedRangeEnd == nil {
                    selectedRangeEnd = date
                } else {
                    // Reset and start new range
                    selectedRangeStart = date
                    selectedRangeEnd = nil
                }
            } else {
                selectedDate = (selectedDate == date) ? nil : date
            }
        }
    }
}

struct ExpenseIndicator: View {
    let count: Int

    var color: Color {
        switch count {
        case 0: return .clear
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }

    var body: some View {
        GeometryReader { geo in
            if count == 1 {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            } else if count > 1 {
                let maxWidth = geo.size.width - 8
                let minWidth: CGFloat = 12
                let width = min(maxWidth, minWidth + CGFloat(count - 1) * 8)
                Capsule()
                    .fill(color)
                    .frame(width: width, height: 6)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }
}
