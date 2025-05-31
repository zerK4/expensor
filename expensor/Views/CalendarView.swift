import SwiftUI
import UIKit

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var showingFullCalendar = false
    @State private var currentPage = 0
    @State private var currentMonth = Date()
    @State private var didAppear = false
    @State private var showingMonthPicker = false

    // State for date range selection
    @State private var isRangeSelectionEnabled = false
    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil

    let onDateSelect: ((startDate: Date?, endDate: Date?)) -> Void
    let markedDates: [Date]

    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    private let calendar = Calendar.current

    init(markedDates: [Date] = [], onDateSelected: @escaping ((startDate: Date?, endDate: Date?)) -> Void) {
        self.markedDates = markedDates
        self.onDateSelect = onDateSelected
    }

    var body: some View {
        VStack(spacing: 0) {
            singleLineCalendarView
                .onChange(of: selectedDate) { _ in
                    // This will trigger UI updates when selectedDate changes
                }
            if showingFullCalendar {
                fullCalendarContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .clipped()
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2), value: showingFullCalendar)
        .contentShape(Rectangle())
        .onAppear {
            if !didAppear {
                currentPage = 0
                currentMonth = calendar.date(byAdding: .month, value: currentPage, to: Date())!
                didAppear = true
                selectedDate = Date().startOfDay // Ensure start of day
                // Notify parent with the initial single date
                onDateSelect((startDate: selectedDate, endDate: nil))
            }
        }
    }

    private var singleLineCalendarView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer().frame(height: 40)
            HStack {
                monthHeaderView
                    .onTapGesture {
                        showingMonthPicker.toggle()
                        if !showingFullCalendar {
                            withAnimation { showingFullCalendar = true }
                        }
                    }
                // Spacer() // Keep spacer here for alignment
                Button(action: {
                    withAnimation {
                        isRangeSelectionEnabled.toggle()
                        // Clear current selection when switching modes
                        startDate = nil
                        endDate = nil
                        // Notify parent that selection is cleared
                        onDateSelect((startDate: nil, endDate: nil))
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isRangeSelectionEnabled ? "calendar.badge.filled.time" : "calendar")
                            .font(.caption)
                        Text(isRangeSelectionEnabled ? "Range" : "Single")
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(isRangeSelectionEnabled ? Color.blue.opacity(0.2) : Color(.systemGray5))
                    .foregroundColor(isRangeSelectionEnabled ? .blue : .primary)
                    .cornerRadius(8)
                }

                Spacer() // Put spacer here

                Button(action: {
                    withAnimation {
                        showingFullCalendar.toggle()
                    }
                }) {
                    Image(systemName: showingFullCalendar ? "chevron.up" : "chevron.down")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
            .padding(.horizontal)

            GeometryReader { geometry in
                TabView(selection: $currentPage) {
                    ForEach(-12..<12, id: \.self) { monthOffset in
                        let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: Date())!
                        singleMonthView(monthDate: monthDate)
                            .frame(width: geometry.size.width)
                            .tag(monthOffset)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentPage) { newValue in
                    let newMonth = calendar.date(byAdding: .month, value: newValue, to: Date())!
                    if !calendar.isDate(newMonth, equalTo: currentMonth, toGranularity: .month) {
                        currentMonth = newMonth
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
                }
            }
            .frame(height: 60)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.height > 50 && !showingFullCalendar {
                            withAnimation { showingFullCalendar = true }
                        } else if value.translation.height < -50 && showingFullCalendar {
                            withAnimation { showingFullCalendar = false }
                        }
                    },
                including: .all
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { _ in }
            )
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingMonthPicker) {
            MonthYearPicker(selectedDate: $currentMonth) { newSelectedMonth in
                self.currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newSelectedMonth))!
                let components = calendar.dateComponents([.month], from: Date().startOfMonth, to: self.currentMonth)
                if let monthOffset = components.month {
                    currentPage = monthOffset
                }
                showingMonthPicker = false
            }
        }
    }

    private func singleMonthView(monthDate: Date) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(daysInMonth(monthDate), id: \.self) { date in
                        dayView(for: date, isSingleLine: true)
                            .id(date.startOfDay)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                if calendar.isDate(selectedDate, equalTo: monthDate, toGranularity: .month) {
                    proxy.scrollTo(selectedDate.startOfDay, anchor: .center)
                } else if calendar.isDateInToday(monthDate) {
                    proxy.scrollTo(Date().startOfDay, anchor: .center)
                }
            }
            .onChange(of: selectedDate) { newSelectedDate in
                if calendar.isDate(newSelectedDate, equalTo: monthDate, toGranularity: .month) {
                    proxy.scrollTo(newSelectedDate.startOfDay, anchor: .center)
                }
            }
        }
    }

    private var fullCalendarContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonthForFullCalendar(currentMonth), id: \.self) { date in
                    dayView(
                        for: date,
                        isSingleLine: false,
                        isOutsideMonth: !calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }

    private var monthHeaderView: some View {
        HStack(spacing: 4) {
            Text(currentMonth.formatted(.dateTime.year().month(.wide)))
                .font(.headline)
                .fontWeight(.semibold)
            Image(systemName: "chevron.right.circle.fill")
                .font(.caption)
                .foregroundColor(.blue)
        }
    }

    private func dayView(for date: Date, isSingleLine: Bool, isOutsideMonth: Bool = false) -> some View {
        // Determine selection state
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate) && !isRangeSelectionEnabled
        let isToday = calendar.isDateInToday(date)

        let isStartDate = startDate != nil && calendar.isDate(date, inSameDayAs: startDate!)
        let isEndDate = endDate != nil && calendar.isDate(date, inSameDayAs: endDate!)
        let isWithinRange = startDate != nil && endDate != nil && date.startOfDay >= startDate!.startOfDay && date.startOfDay <= endDate!.startOfDay

        let hasMarkedEvent = markedDates.contains { calendar.isDate($0, inSameDayAs: date) }

        let fontSize: CGFloat = isSingleLine ? 16 : 18
        let rectSize: CGFloat = isSingleLine ? 36 : 40
        let dotSize: CGFloat = isSingleLine ? 5 : 7
        let vStackTotalHeight: CGFloat = isSingleLine ? 48 : 60
        let cornerRadius: CGFloat = 10

        return VStack(spacing: 2) {
            ZStack {
                // Background rectangle based on selection mode and state
                if isRangeSelectionEnabled {
                    if isStartDate || isEndDate { // Highlight start or end date with solid blue
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.blue)
                            .frame(width: rectSize, height: rectSize)
                    } else if isWithinRange { // Highlight dates within the range with lighter blue
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: rectSize, height: rectSize)
                    } else if isToday { // Show today marker if it\'s today but not selected
                         RoundedRectangle(cornerRadius: cornerRadius)
                             .stroke(Color.blue, lineWidth: 2)
                             .frame(width: rectSize, height: rectSize)
                    }
                } else { // Single selection mode
                    if isSelected { // Highlight the single selected date
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.blue)
                            .frame(width: rectSize, height: rectSize)
                    } else if isToday { // Show today marker if it\'s today but not selected
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: rectSize, height: rectSize)
                    }
                }

                // Text for the day number
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: fontSize, weight: (isSelected || isStartDate || isEndDate) ? .bold : .regular)) // Bold for selected single date or range ends
                    .foregroundColor(
                        isOutsideMonth ? Color.secondary.opacity(0.5) : // Grey out dates outside the current month
                        (isRangeSelectionEnabled && isWithinRange) ? .white : // White text for dates within the range
                        isSelected ? .white : // White text for the single selected date
                        isToday ? .blue : .primary // Blue text for today, default primary otherwise
                    )
            }
            // Dot indicator for marked dates
            if hasMarkedEvent {
                Circle()
                    // White dot if the date is selected (single or range), red otherwise
                    .fill((isRangeSelectionEnabled && isWithinRange) || (!isRangeSelectionEnabled && isSelected) ? .white : .red)
                    .frame(width: dotSize, height: dotSize)
            } else {
                // Placeholder to maintain spacing when no dot is present
                Spacer().frame(height: dotSize)
            }
        }
        .frame(height: vStackTotalHeight) // Ensure consistent cell height
        .contentShape(Rectangle()) // Make the whole area tappable
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred() // Provide haptic feedback on tap

            let tappedDateStartOfDay = date.startOfDay // Normalize tapped date

            withAnimation(.easeInOut(duration: 0.2)) {
                if isRangeSelectionEnabled {
                    if startDate == nil {
                        // First tap: Set start date
                        startDate = tappedDateStartOfDay
                        endDate = nil // Ensure endDate is nil when setting start
                        showingFullCalendar = true // Keep full calendar open to select end date
                        // Optionally notify parent that range selection has started with just the start date
                        // onDateSelect((startDate: startDate, endDate: nil)) // Decide if partial range selection should trigger filter updates
                    } else if endDate == nil {
                        // Second tap: Set end date
                        if tappedDateStartOfDay >= startDate! {
                            // Valid range: end date is after or same as start date
                            endDate = tappedDateStartOfDay
                            // Notify parent with the complete range
                            onDateSelect((startDate: startDate, endDate: endDate))
                            // Collapse calendar after selecting the range
                             if showingFullCalendar && !isOutsideMonth {
                                 showingFullCalendar = false
                             }
                        } else {
                            // Invalid range: tapped date is before start date
                            // Reset selection and set the tapped date as the new start date
                            startDate = tappedDateStartOfDay
                            endDate = nil
                            // Notify parent that the selection is reset (no range selected yet)
                            onDateSelect((startDate: nil, endDate: nil))
                            showingFullCalendar = true // Keep calendar open for new range selection
                        }
                    } else {
                        // Third tap (or more) while a range is already selected: Start a new range
                        startDate = tappedDateStartOfDay
                        endDate = nil
                        // Notify parent that the previous range is cleared and a new selection is starting
                        onDateSelect((startDate: nil, endDate: nil))
                        showingFullCalendar = true // Keep calendar open for new range selection
                    }
                } else {
                    // Single date selection mode
                    if calendar.isDate(selectedDate, inSameDayAs: tappedDateStartOfDay) {
                        // Same date tapped again - clear selection
                        selectedDate = Date().addingTimeInterval(86400) // Set to tomorrow to avoid highlighting
                        onDateSelect((startDate: nil, endDate: nil))
                    } else {
                        // Different date selected
                        selectedDate = tappedDateStartOfDay
                        // Notify parent with the single selected date
                        onDateSelect((startDate: selectedDate, endDate: nil))
                    }
                    // Collapse calendar after single date selection
                     if showingFullCalendar && !isOutsideMonth {
                         showingFullCalendar = false
                     }
                 }
             }
         }
     }

    private func daysInMonth(_ date: Date) -> [Date] {
        let range = calendar.range(of: .day, in: .month, for: date)!
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    private func daysInMonthForFullCalendar(_ date: Date) -> [Date] {
        let range = calendar.range(of: .day, in: .month, for: date)!
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let firstWeekday = calendar.component(.weekday, from: monthStart) - 1
        var days: [Date] = []
        if firstWeekday > 0 {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: date)!
            let prevMonthRange = calendar.range(of: .day, in: .month, for: previousMonth)!
            let prevMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: previousMonth))!
            for i in (prevMonthRange.count - firstWeekday + 1)...prevMonthRange.count {
                if let prevDate = calendar.date(byAdding: .day, value: i - 1, to: prevMonthStart) {
                    days.append(prevDate)
                }
            }
        }
        for day in range {
            if let currentDate = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(currentDate)
            }
        }
        let remainingDays = 42 - days.count
        if remainingDays > 0 {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: date)!
            let nextMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth))!
            for day in 1...remainingDays {
                if let nextDate = calendar.date(byAdding: .day, value: day - 1, to: nextMonthStart) {
                    days.append(nextDate)
                }
            }
        }
        return days
    }
}

// MARK: - MonthYearPicker
struct MonthYearPicker: View {
    @Binding var selectedDate: Date
    var onSelect: (Date) -> Void

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Month",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()

                Spacer()
            }
            .padding()
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSelect(selectedDate)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Extension for Date
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
    }

    var utcStartOfDay: Date {
       Calendar(identifier: .gregorian).date(from: Calendar(identifier: .gregorian).dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: self))!
   }
}

//// MARK: - Preview
//struct CalendarView_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleMarkedDates = [
//            Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
//            Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
//            Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
//            Calendar.current.date(byAdding: .day, value: 15, to: Date())!
//        ]
//
//        VStack {
//            Text("App Content Above")
//                .padding()
//
//            CalendarView(markedDates: sampleMarkedDates, onDateSelected: { selectedDate in
//                print("Selected date: \(selectedDate.formatted())")
//            })
//
//            Text("App Content Below")
//                .padding()
//
//            Spacer()
//        }
//        .background(Color(.systemGroupedBackground))
//    }
//}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMarkedDates = [
            Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            Calendar.current.date(byAdding: .day, value: 15, to: Date())!
        ]

        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            CalendarView(markedDates: sampleMarkedDates, onDateSelected: { selectedDate in
                // selectedDate is now a tuple (startDate: Date?, endDate: Date?)
                print("Selected date range: \(selectedDate.startDate?.formatted() ?? "nil") - \(selectedDate.endDate?.formatted() ?? "nil"))")
            })
            .ignoresSafeArea(edges: .top)
        }
    }
}
