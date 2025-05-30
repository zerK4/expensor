import SwiftUI
import UIKit

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var showingFullCalendar = false
    @State private var currentPage = 0
    @State private var currentMonth = Date()
    @State private var didAppear = false
    @State private var showingMonthPicker = false

    let onDateSelect: (Date) -> Void
    let markedDates: [Date]

    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    private let calendar = Calendar.current

    init(markedDates: [Date] = [], onDateSelected: @escaping (Date) -> Void) {
        self.markedDates = markedDates
        self.onDateSelect = onDateSelected
    }

    var body: some View {
        VStack(spacing: 0) {
            singleLineCalendarView
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
                selectedDate = Date()
                onDateSelect(selectedDate)
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
                Spacer()
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
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let hasMarkedEvent = markedDates.contains { calendar.isDate($0, inSameDayAs: date) }

        let fontSize: CGFloat = isSingleLine ? 16 : 18
        let rectSize: CGFloat = isSingleLine ? 36 : 40
        let dotSize: CGFloat = isSingleLine ? 5 : 7
        let vStackTotalHeight: CGFloat = isSingleLine ? 48 : 60
        let cornerRadius: CGFloat = 10

        return VStack(spacing: 2) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.blue)
                        .frame(width: rectSize, height: rectSize)
                } else if isToday {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: rectSize, height: rectSize)
                }
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: fontSize, weight: isSelected ? .bold : .regular))
                    .foregroundColor(
                        isOutsideMonth ? Color.secondary.opacity(0.5) :
                        isSelected ? .white :
                        isToday ? .blue : .primary
                    )
            }
            if hasMarkedEvent {
                Circle()
                    .fill(isSelected ? .white : .red)
                    .frame(width: dotSize, height: dotSize)
            } else {
                Spacer().frame(height: dotSize)
            }
        }
        .frame(height: vStackTotalHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = date
                onDateSelect(date)
                if !calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                    currentMonth = date.startOfMonth
                    let components = calendar.dateComponents([.month], from: Date().startOfMonth, to: currentMonth)
                    if let monthOffset = components.month {
                        currentPage = monthOffset
                    }
                }
                if showingFullCalendar && !isOutsideMonth {
                    showingFullCalendar = false
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
                print("Selected date: \(selectedDate.formatted())")
            })
            .ignoresSafeArea(edges: .top)
        }
    }
}
