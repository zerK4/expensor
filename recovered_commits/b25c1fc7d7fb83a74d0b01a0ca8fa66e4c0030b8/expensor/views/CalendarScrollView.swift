import SwiftUI

struct CalendarScrollView: View {
    let dates: [Date]
    @Binding var selectedDate: Date?
    let expenseCountForDate: (Date) -> Int
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 6) {
                    ForEach(dates, id: \.self) { date in
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
                .padding(.horizontal)
                .scrollTargetLayout() // <-- Add this line to fix the error
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .frame(height: 60)
            .onAppear {
                if selectedDate == nil {
                    let today = Calendar.current.startOfDay(for: Date())
                    if dates.contains(today) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollProxy.scrollTo(today, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}
