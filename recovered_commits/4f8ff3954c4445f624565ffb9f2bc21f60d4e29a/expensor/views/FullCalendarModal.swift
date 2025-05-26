//// FullCalendarModal.swift
//import SwiftUI
//
//struct FullCalendarModal: View {
//    let dates: [Date]
//    @Binding var selectedDate: Date?
//    let expenseCountForDate: (Date) -> Int
//
//    @Environment(\.dismiss) private var dismiss
//
//    @State private var currentMonth: Date = Calendar.current.startOfDay(for: Date())
//
//    // Generate a range of months for swiping (e.g., 12 months before and after current)
//    private var months: [Date] {
//        let calendar = Calendar.current
//        let base = calendar.startOfMonth(for: currentMonth)
//        return (-12...12).compactMap { offset in
//            calendar.date(byAdding: .month, value: offset, to: base)
//        }
//    }
//
//    @State private var selectedMonthIndex: Int = 12 // Centered on current month
//
//    var body: some View {
//        NavigationStack {
//            VStack {
//                // Header with chevrons and month label
//                HStack {
//                    Button {
//                        if selectedMonthIndex > 0 {
//                            selectedMonthIndex -= 1
//                        }
//                    } label: {
//                        Image(systemName: "chevron.left")
//                            .padding()
//                    }
//                    Spacer()
//                    Text(monthTitle(for: months[selectedMonthIndex]))
//                        .font(.headline)
//                        .frame(maxWidth: .infinity)
//                    Spacer()
//                    Button {
//                        if selectedMonthIndex < months.count - 1 {
//                            selectedMonthIndex += 1
//                        }
//                    } label: {
//                        Image(systemName: "chevron.right")
//                            .padding()
//                    }
//                }
//                .padding(.horizontal)
//
//                // Swipeable months
//                TabView(selection: $selectedMonthIndex) {
//                    ForEach(months.indices, id: \.self) { idx in
//                        FullCalendarView(
//                            month: months[idx],
//                            datesWithExpenses: Set(dates),
//                            selectedDate: $selectedDate,
//                            expenseCountForDate: expenseCountForDate
//                        )
//                        .tag(idx)
//                        .padding(.horizontal, 4)
//                    }
//                }
//                .tabViewStyle(.page(indexDisplayMode: .never))
//                .animation(.easeInOut, value: selectedMonthIndex)
//            }
//            .navigationTitle("Calendar")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Close") { dismiss() }
//                }
//            }
//            .onAppear {
//                // Set initial month index to current
//                if let idx = months.firstIndex(where: { Calendar.current.isDate($0, equalTo: currentMonth, toGranularity: .month) }) {
//                    selectedMonthIndex = idx
//                }
//            }
//        }
//    }
//
//    private func monthTitle(for date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMMM yyyy"
//        return formatter.string(from: date)
//    }
//}
//
//// Helper extension
//extension Calendar {
//    func startOfMonth(for date: Date) -> Date {
//        dateInterval(of: .month, for: date)?.start ?? date
//    }
//}
