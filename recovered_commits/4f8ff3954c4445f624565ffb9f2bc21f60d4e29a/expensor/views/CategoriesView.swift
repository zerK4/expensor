import SwiftUI

struct CategoriesView: View {
    @State private var categories: [Category] = [
        Category(name: "Food", icon: "🍔"),
        Category(name: "Groceries", icon: "🛒"),
        Category(name: "Gas", icon: "⛽")
    ]
    @State private var showAddCategory = false

    var body: some View {
        NavigationView {
            List(categories) { category in
                HStack {
                    if isEmoji(category.icon) {
                        Text(category.icon).font(.title2)
                    } else {
                        Image(systemName: category.icon).font(.title2)
                    }
                    Text(category.name)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddCategory = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet { newCategory in
                    categories.append(newCategory)
                }
            }
        }
    }

    func isEmoji(_ text: String) -> Bool {
        return text.unicodeScalars.first?.properties.isEmojiPresentation == true
    }
}

struct AddCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var selectedIcon: String = ""
    var onAdd: (Category) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Category name", text: $name)
                }
                Section(header: Text("Icon")) {
                    SymbolOrEmojiPicker(selected: $selectedIcon)
                }
            }
            .navigationTitle("Add Category")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !name.isEmpty && !selectedIcon.isEmpty {
                            onAdd(Category(name: name, icon: selectedIcon))
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct SymbolOrEmojiPicker: View {
    @Binding var selected: String
    @State private var selectionType: PickerType = .sfSymbol
    @State private var sfSymbols: [String] = []
    @State private var searchText: String = ""

    enum PickerType: String, CaseIterable, Identifiable {
        case sfSymbol = "SF Symbols"
        case emoji = "Emoji"
        var id: String { rawValue }
    }

    var filteredSymbols: [String] {
        if searchText.isEmpty {
            return sfSymbols
        } else {
            return sfSymbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack {
            Picker("Type", selection: $selectionType) {
                ForEach(PickerType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical)

            if selectionType == .emoji {
                TextField("Enter emoji", text: $selected)
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    TextField("Search symbols", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    ScrollView {
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 12) {
                            ForEach(filteredSymbols, id: \.self) { symbol in
                                Image(systemName: symbol)
                                    .font(.title2)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(selected == symbol ? Color.blue.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selected = symbol
                                    }
                            }
                        }
                        .padding()
                    }
                    .frame(height: 250)
                }
            }
        }
        .onAppear {
            if sfSymbols.isEmpty {
                loadSFSymbols()
            }
        }
    }

    func loadSFSymbols() {
        sfSymbols = [
            // Income & Money Sources
            "dollarsign.circle", "dollarsign.circle.fill", "banknote", "banknote.fill", "creditcard", "creditcard.fill",
            "giftcard", "giftcard.fill", "briefcase", "briefcase.fill", "building.columns", "building.columns.fill",
            "hand.thumbsup", "hand.thumbsup.fill", "chart.line.uptrend.xyaxis", "chart.line.uptrend.xyaxis.circle",
            "arrow.up.square", "arrow.up.square.fill", "plus.circle", "plus.circle.fill", "arrow.down.app", "arrow.down.app.fill",
            "dollarsign.arrow.circlepath", "clock.arrow.2.circlepath", "envelope.badge", "envelope.badge.fill",
            
            // Daily Expenses
            "cart", "cart.fill", "cart.badge.plus", "cart.badge.minus", "bag", "bag.fill", "basket", "basket.fill",
            "takeoutbag.and.cup.and.straw", "takeoutbag.and.cup.and.straw.fill", "fork.knife", "fork.knife.circle",
            "cup.and.saucer", "cup.and.saucer.fill", "mug", "mug.fill", "wineglass", "wineglass.fill",
            "popcorn", "popcorn.fill", "bag.circle", "bag.circle.fill", "purchased.circle", "purchased.circle.fill",
            
            // Housing & Utilities
            "house", "house.fill", "house.circle", "house.circle.fill", "building", "building.fill",
            "bed.double", "bed.double.fill", "shower", "shower.fill", "toilet", "toilet.fill",
            "lightbulb", "lightbulb.fill", "bolt", "bolt.fill", "flame", "flame.fill", "drop", "drop.fill",
            "thermometer", "thermometer.snowflake", "wifi", "wifi.circle", "wifi.circle.fill", "network",
            
            // Transportation
            "car", "car.fill", "car.circle", "car.circle.fill", "bus", "bus.fill", "tram", "tram.fill",
            "airplane", "airplane.circle", "airplane.circle.fill", "bicycle", "bicycle.circle", "bicycle.circle.fill",
            "figure.walk", "figure.walk.circle", "figure.walk.circle.fill", "fuelpump", "fuelpump.fill",
            "speedometer", "speedometer.medium", "mappin", "mappin.circle", "mappin.circle.fill", "location.fill",
            
            // Healthcare
            "heart", "heart.fill", "cross", "cross.fill", "cross.circle", "cross.circle.fill",
            "pills", "pills.fill", "stethoscope", "stethoscope.circle", "stethoscope.circle.fill", "bandage",
            "bandage.fill", "waveform.path.ecg", "tooth", "tooth.fill", "eye", "eye.fill",
            "brain", "brain.head.profile", "ear", "ear.fill", "nose", "nose.fill", "medical.thermometer",
            
            // Entertainment & Leisure
            "gamecontroller", "gamecontroller.fill", "film", "film.fill", "tv", "tv.fill",
            "popcorn.circle", "popcorn.circle.fill", "ticket", "ticket.fill", "theatermasks", "theatermasks.fill",
            "sportscourt", "sportscourt.fill", "figure.yoga", "figure.run", "figure.pool.swim", "figure.outdoor.cycle",
            "dumbbell", "dumbbell.fill", "gift", "gift.fill", "balloon", "balloon.fill", "party.popper", "party.popper.fill",
            
            // Shopping
            "tag", "tag.fill", "tag.circle", "tag.circle.fill", "shippingbox", "shippingbox.fill",
            "tshirt", "tshirt.fill", "backpack", "backpack.fill", "case", "case.fill",
            "scissors", "scissors.circle", "scissors.circle.fill", "ruler", "ruler.fill", "books.vertical",
            "books.vertical.fill", "book", "book.fill", "magazine", "magazine.fill", "gift.card", "gift.card.fill",
            
            // Food & Dining
            "carrot", "carrot.fill", "leaf", "leaf.fill", "cart.badge.plus", "cart.badge.plus.fill",
            "wineglass", "wineglass.fill", "cup.and.saucer", "cup.and.saucer.fill", "mug", "mug.fill",
            "birthday.cake", "birthday.cake.fill", "refrigerator", "refrigerator.fill", "water.waves", "water.waves.fill",
            "laurel.leading", "laurel.trailing", "fish", "fish.fill", "tortoise", "tortoise.fill", "egg", "egg.fill",
            
            // Bills & Subscriptions
            "repeat", "repeat.circle", "repeat.circle.fill", "calendar", "calendar.badge.clock",
            "calendar.circle", "calendar.circle.fill", "doc.text", "doc.text.fill", "bell", "bell.fill",
            "bell.badge", "bell.badge.fill", "recordingtape", "recordingtape.circle", "recordingtape.circle.fill",
            "newspaper", "newspaper.fill", "mail.stack", "mail.stack.fill", "wifi.router", "network.badge.shield.half.filled",
            
            // Saving & Investing
            "chart.bar", "chart.bar.fill", "chart.pie", "chart.pie.fill", "chart.line.uptrend.xyaxis",
            "chart.line.uptrend.xyaxis.circle", "chart.line.uptrend.xyaxis.circle.fill", "arrow.up.arrow.down.circle",
            "arrow.up.arrow.down.circle.fill", "arrow.triangle.2.circlepath", "arrow.clockwise.circle", "arrow.clockwise.circle.fill",
            "folder", "folder.fill", "tray.full", "tray.full.fill", "lock", "lock.fill", "checkmark.shield", "checkmark.shield.fill",
            
            // Business Expenses
            "briefcase", "briefcase.fill", "case", "case.fill", "printer", "printer.fill",
            "doc.on.doc", "doc.on.doc.fill", "doc.plaintext", "doc.plaintext.fill", "paperclip", "paperclip.circle",
            "paperclip.circle.fill", "paperplane", "paperplane.fill", "envelope", "envelope.fill", "signature",
            "pencil.tip", "pencil.tip.crop.circle", "pencil.tip.crop.circle.fill", "building.2", "building.2.fill",
            
            // Travel
            "airplane", "airplane.fill", "airplane.circle", "airplane.circle.fill", "suitcase", "suitcase.fill",
            "suitcase.cart", "suitcase.cart.fill", "bed.double", "bed.double.fill", "globe", "globe.americas.fill",
            "globe.europe.africa.fill", "globe.asia.australia.fill", "mappin", "mappin.and.ellipse", "location.north.line",
            "location.north.line.fill", "map", "map.fill", "ferry", "ferry.fill", "beach.umbrella", "beach.umbrella.fill",
            
            // Education
            "book", "book.fill", "book.circle", "book.circle.fill", "books.vertical", "books.vertical.fill",
            "graduationcap", "graduationcap.fill", "studentdesk", "ruler", "ruler.fill", "pencil",
            "pencil.circle", "pencil.circle.fill", "highlighter", "backpack", "backpack.fill", "building.columns.circle",
            "building.columns.circle.fill", "brain", "brain.head.profile", "list.clipboard", "list.clipboard.fill",
            
            // Budget Tracking
            "arrow.left.arrow.right", "arrow.left.arrow.right.circle", "arrow.left.arrow.right.circle.fill",
            "arrow.up", "arrow.up.circle", "arrow.up.circle.fill", "arrow.down", "arrow.down.circle",
            "arrow.down.circle.fill", "equal", "equal.circle", "equal.circle.fill", "percent", "percent.ar",
            "minus", "minus.circle", "minus.circle.fill", "plus", "plus.circle", "plus.circle.fill",
            "exclamationmark.triangle", "exclamationmark.triangle.fill", "checkmark.circle", "checkmark.circle.fill",
            
            // Categories Management
            "folder", "folder.fill", "folder.badge.plus", "folder.badge.plus.fill", "folder.circle",
            "folder.circle.fill", "square.grid.3x3", "square.grid.3x3.fill", "square.stack", "square.stack.fill",
            "rectangle.3.group", "rectangle.3.group.fill", "list.bullet", "list.bullet.circle", "list.bullet.circle.fill",
            "text.badge.plus", "text.badge.plus.fill", "tag", "tag.fill", "list.star", "list.star.fill",
            
            // Time-Related
            "clock", "clock.fill", "clock.circle", "clock.circle.fill", "deskclock", "deskclock.fill",
            "timer", "timer.square", "hourglass", "hourglass.circle", "hourglass.circle.fill",
            "calendar", "calendar.circle", "calendar.circle.fill", "calendar.badge.plus", "calendar.badge.minus",
            "calendar.day.timeline.left", "calendar.day.timeline.right", "speedometer", "gauge.medium", "stopwatch",
            
            // Status & Analytics
            "chart.xyaxis.line", "chart.bar", "chart.bar.fill", "chart.pie", "chart.pie.fill",
            "chart.bar.xaxis", "chart.line.uptrend.xyaxis", "waveform.path", "waveform.path.ecg.rectangle",
            "arrow.up.right", "arrow.up.right.circle", "arrow.up.right.circle.fill", "arrow.down.right",
            "arrow.down.right.circle", "arrow.down.right.circle.fill", "trendingdown", "trendingup"
        ]
    }
}

#Preview {
    CategoriesView()
}
