import SwiftUI
import Charts

struct IdentifiableUUID: Identifiable {
    var id: UUID
}

struct DogDetailView: View {
    @Bindable var store: DogStore
    var dogId: UUID
    var initialTab: DetailTab = .habits
    
    @State private var selectedTab: DetailTab
    
    init(store: DogStore, dogId: UUID, initialTab: DetailTab = .habits) {
        self.store = store
        self.dogId = dogId
        self.initialTab = initialTab
        _selectedTab = State(initialValue: initialTab)
    }
    
    @State private var showingAddHabitSheet = false
    @State private var showingLogWeightSheet = false
    @State private var showingLogVetSheet = false
    @State private var showingEditDogSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAddMedSheet = false
    @State private var selectedHabitForDetail: IdentifiableUUID? = nil
    
    @State private var newMedName = ""
    @State private var newMedDosage = ""
    @State private var newMedFrequency = "Daily"
    
    @Environment(\.dismiss) private var dismiss
    
    enum DetailTab: String, CaseIterable, Identifiable {
        case habits = "Habits"
        case health = "Weight"
        case medical = "Medical"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .habits: return "checklist"
            case .health: return "scalemass.fill"
            case .medical: return "cross.case.fill"
            }
        }
    }
    
    private var currentDog: Dog? {
        store.dogs.first(where: { $0.id == dogId })
    }
    
    var body: some View {
        Group {
            if let dog = currentDog {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Profile Card
                        headerCard(for: dog)
                        
                        // Tab Selector
                        tabPicker
                        
                        // Tab Content
                        switch selectedTab {
                        case .habits:
                            habitsSection(for: dog)
                        case .health:
                            healthSection(for: dog)
                        case .medical:
                            medicalSection(for: dog)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .background(DogTheme.backgroundWhite)
                .navigationTitle(dog.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showingEditDogSheet = true
                            } label: {
                                Label("Edit Profile", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Dog", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.body)
                                .foregroundStyle(DogTheme.primaryBlue)
                        }
                    }
                }
                .sheet(isPresented: $showingEditDogSheet) {
                    AddDogView(dogToEdit: dog, initialWeightUnit: store.preferredWeightUnit) { updatedDog in
                        store.updateDog(updatedDog)
                    }
                }
                .sheet(isPresented: $showingAddHabitSheet) {
                    AddHabitSheet { newHabit in
                        store.addHabit(to: dog.id, habit: newHabit)
                    }
                }
                .sheet(isPresented: $showingLogWeightSheet) {
                    LogWeightSheet(currentWeightKg: dog.latestWeight, initialUnit: store.preferredWeightUnit) { newLog in
                        store.addWeightLog(to: dog.id, log: newLog)
                    }
                }
                .sheet(isPresented: $showingLogVetSheet) {
                    LogVetVisitSheet { newVisit in
                        store.addVetVisit(to: dog.id, visit: newVisit)
                    }
                }
                .sheet(isPresented: $showingAddMedSheet) {
                    addMedicationSheet(dogId: dog.id)
                }
                .sheet(item: $selectedHabitForDetail) { item in
                    HabitDetailSheet(dogId: dog.id, habitId: item.id, store: store)
                }
                .alert("Delete \(dog.name)?", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        store.deleteDog(dog)
                        dismiss()
                    }
                } message: {
                    Text("Are you sure you want to remove \(dog.name) and all recorded health history?")
                }
            } else {
                ContentUnavailableView("Dog Not Found", systemImage: "pawprint.fill")
            }
        }
    }
    
    // MARK: - Header Profile Card
    
    private func headerCard(for dog: Dog) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Avatar (supports uploaded photo or icon)
                DogAvatarView(
                    photoData: dog.photoData,
                    iconName: dog.iconName,
                    avatarColor: dog.avatarColor,
                    size: 72
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(dog.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        Image(systemName: dog.gender == .male ? "figure.stand" : "figure.stand.dress")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(dog.gender.backgroundColor)
                            .foregroundStyle(dog.gender.tintColor)
                            .clipShape(Capsule())
                    }
                    
                    Text(dog.breed)
                        .font(.subheadline)
                        .foregroundStyle(DogTheme.textSecondary)
                    
                    HStack(spacing: 12) {
                        Label(dog.ageString, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(DogTheme.textSecondary)
                        
                        Label(dog.formattedWeight(for: store.preferredWeightUnit), systemImage: "scalemass")
                            .font(.caption)
                            .foregroundStyle(DogTheme.textSecondary)
                    }
                }
                Spacer()
            }
            
            // Progress Bar for Today's Habits
            VStack(alignment: .leading, spacing: 8) {
                let totalSteps = dog.dailyHabits.reduce(0) { $0 + $1.targetCountPerDay }
                let doneSteps = dog.dailyHabits.reduce(0) { $0 + min($1.completedCount(on: Date()), $1.targetCountPerDay) }
                
                HStack {
                    Text("Today's Healthy Routine")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DogTheme.textSecondary)
                    
                    Spacer()
                    
                    Text("\(doneSteps) of \(totalSteps) steps done")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(dog.todayHabitProgress == 1.0 ? DogTheme.primaryGreen : DogTheme.accentOrange)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DogTheme.subtleGray)
                            .frame(height: 10)
                        
                        Capsule()
                            .fill(dog.todayHabitProgress == 1.0 ? AnyShapeStyle(DogTheme.primaryGreen) : AnyShapeStyle(DogTheme.greenBlueGradient))
                            .frame(width: max(0, min(geo.size.width * CGFloat(dog.todayHabitProgress), geo.size.width)), height: 10)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dog.todayHabitProgress)
                    }
                }
                .frame(height: 10)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(DogTheme.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - Tab Picker
    
    private var tabPicker: some View {
        HStack(spacing: 8) {
            ForEach(DetailTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.subheadline)
                        Text(tab.rawValue)
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTab == tab ? DogTheme.primaryBlue : DogTheme.pureWhite)
                    .foregroundStyle(selectedTab == tab ? .white : DogTheme.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: Color.black.opacity(selectedTab == tab ? 0.08 : 0.02), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Habits Section
    
    private func habitsSection(for dog: Dog) -> some View {
        VStack(spacing: 14) {
            // Header & Add Habit Button
            HStack {
                Text("Daily Habits")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    showingAddHabitSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Habit")
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DogTheme.softOrange)
                    .foregroundStyle(DogTheme.accentOrange)
                    .clipShape(Capsule())
                }
            }
            
            if dog.dailyHabits.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "pawprint.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(DogTheme.primaryGreen.opacity(0.7))
                    Text("No habits set yet")
                        .font(.headline)
                    Text("Add daily habits like morning walks, fresh water, medication, or teeth brushing.")
                        .font(.caption)
                        .foregroundStyle(DogTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button {
                        showingAddHabitSheet = true
                    } label: {
                        Text("+ Add First Habit")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(DogTheme.accentOrange)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(DogTheme.pureWhite)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                // If all done, show celebratory card
                if dog.todayHabitProgress == 1.0 {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(DogTheme.primaryGreen)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("All Habits Done Today! 🎉")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(DogTheme.primaryGreen)
                            Text("\(dog.name) has completed their healthy habits for the day.")
                                .font(.caption)
                                .foregroundStyle(DogTheme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(DogTheme.softGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                ForEach(dog.dailyHabits) { habit in
                    let isCompleted = habit.isCompleted(on: Date())
                    let count = habit.completedCount(on: Date())
                    let target = habit.targetCountPerDay
                    
                    HStack(spacing: 14) {
                        // Category Icon
                        ZStack {
                            Circle()
                                .fill(habit.category.color.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: habit.category.iconName)
                                .font(.headline)
                                .foregroundStyle(habit.category.color)
                        }
                        
                        // Habit Info
                        VStack(alignment: .leading, spacing: 3) {
                            Text(habit.title)
                                .font(.subheadline.weight(.semibold))
                                .strikethrough(isCompleted, color: DogTheme.textSecondary)
                                .foregroundStyle(isCompleted ? DogTheme.textSecondary : .primary)
                            
                            HStack(spacing: 6) {
                                Text(habit.category.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(DogTheme.textSecondary)
                                Text("•")
                                    .font(.caption2)
                                    .foregroundStyle(DogTheme.textSecondary)
                                Text(habit.targetFrequency)
                                    .font(.caption2)
                                    .foregroundStyle(DogTheme.textSecondary)
                                
                                // Comment indicator button
                                Button {
                                    selectedHabitForDetail = IdentifiableUUID(id: habit.id)
                                } label: {
                                    HStack(spacing: 2) {
                                        Image(systemName: habit.comments.isEmpty ? "bubble.left" : "bubble.left.fill")
                                        if !habit.comments.isEmpty {
                                            Text("\(habit.comments.count)")
                                        }
                                    }
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(habit.comments.isEmpty ? DogTheme.textSecondary : DogTheme.accentOrange)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(habit.comments.isEmpty ? Color.clear : DogTheme.softOrange)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if !habit.notes.isEmpty {
                                Text(habit.notes)
                                    .font(.caption2)
                                    .foregroundStyle(DogTheme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // Checkbox / Multi-step Completion Button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                store.toggleHabit(dogId: dog.id, habitId: habit.id)
                            }
                        } label: {
                            if target > 1 {
                                HStack(spacing: 4) {
                                    Image(systemName: isCompleted ? "checkmark.circle.fill" : (count > 0 ? "circle.inset.filled" : "circle"))
                                        .font(.system(size: 14, weight: .bold))
                                    Text("\(count)/\(target)")
                                        .font(.caption.weight(.bold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isCompleted ? DogTheme.softGreen : (count > 0 ? DogTheme.softOrange : DogTheme.subtleGray))
                                .foregroundStyle(isCompleted ? DogTheme.primaryGreen : (count > 0 ? DogTheme.accentOrange : DogTheme.textSecondary))
                                .clipShape(Capsule())
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(isCompleted ? DogTheme.primaryGreen : Color.clear)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(isCompleted ? DogTheme.primaryGreen : DogTheme.subtleGray, lineWidth: 2)
                                        )
                                    
                                    if isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(DogTheme.pureWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedHabitForDetail = IdentifiableUUID(id: habit.id)
                    }
                    .contextMenu {
                        Button {
                            selectedHabitForDetail = IdentifiableUUID(id: habit.id)
                        } label: {
                            Label("View Comments & Notes", systemImage: "bubble.left.and.text.bubble.right")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            store.deleteHabit(from: dog.id, habitId: habit.id)
                        } label: {
                            Label("Delete Habit", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Health & Weight Section
    
    private func healthSection(for dog: Dog) -> some View {
        VStack(spacing: 16) {
            // Summary Card
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Weight")
                        .font(.caption)
                        .foregroundStyle(DogTheme.textSecondary)
                    Text(dog.formattedWeight(for: store.preferredWeightUnit))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DogTheme.primaryBlue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(DogTheme.softBlue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Weigh-ins")
                        .font(.caption)
                        .foregroundStyle(DogTheme.textSecondary)
                    Text("\(dog.weightLogs.count)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DogTheme.primaryGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(DogTheme.softGreen)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            // Weight Trend Chart (shown when 2 or more weigh-ins exist)
            if dog.weightLogs.count >= 2 {
                weightTrendChart(for: dog)
            }
            
            // Header & Log Weight Button with Unit Switcher
            HStack {
                Text("Weight History")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Picker("Unit", selection: $store.preferredWeightUnit) {
                    ForEach(WeightUnit.allCases) { u in
                        Text(u.rawValue.uppercased()).tag(u)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 86)
                
                Button {
                    showingLogWeightSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Weight")
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DogTheme.softOrange)
                    .foregroundStyle(DogTheme.accentOrange)
                    .clipShape(Capsule())
                }
            }
            
            if dog.weightLogs.isEmpty {
                Text("No weight records logged yet.")
                    .font(.subheadline)
                    .foregroundStyle(DogTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(DogTheme.pureWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 10) {
                    ForEach(dog.weightLogs.sorted(by: { $0.date > $1.date })) { log in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(DogTheme.softBlue)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "scalemass.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(DogTheme.primaryBlue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.formatted(for: store.preferredWeightUnit))
                                    .font(.subheadline.weight(.bold))
                                if !log.notes.isEmpty {
                                    Text(log.notes)
                                        .font(.caption)
                                        .foregroundStyle(DogTheme.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text(log.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(DogTheme.textSecondary)
                        }
                        .padding(14)
                        .background(DogTheme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deleteWeightLog(from: dog.id, logId: log.id)
                            } label: {
                                Label("Delete Log", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Weight Trend Chart
    
    private func weightTrendChart(for dog: Dog) -> some View {
        let sortedLogs = dog.weightLogs.sorted(by: { $0.date < $1.date })
        let values = sortedLogs.map { $0.value(for: store.preferredWeightUnit) }
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 10
        let diffSpan = maxVal - minVal
        let padding = max(0.8, diffSpan * 0.25)
        let yMin = max(0, minVal - padding)
        let yMax = maxVal + padding
        
        let firstLog = sortedLogs.first
        let lastLog = sortedLogs.last
        let totalChange = (lastLog?.value(for: store.preferredWeightUnit) ?? 0) - (firstLog?.value(for: store.preferredWeightUnit) ?? 0)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weight Change Graph")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let first = firstLog, let last = lastLog {
                        Text("\(first.date.formatted(date: .abbreviated, time: .omitted)) – \(last.date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(DogTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                // Trend badge
                HStack(spacing: 4) {
                    Image(systemName: totalChange > 0.05 ? "arrow.up.right" : (totalChange < -0.05 ? "arrow.down.right" : "equal"))
                    let sign = totalChange > 0 ? "+" : ""
                    Text("\(sign)\(String(format: "%.1f", totalChange)) \(store.preferredWeightUnit.rawValue)")
                }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(abs(totalChange) < 0.1 ? DogTheme.subtleGray : (totalChange > 0 ? DogTheme.softOrange : DogTheme.softGreen))
                .foregroundStyle(abs(totalChange) < 0.1 ? DogTheme.textSecondary : (totalChange > 0 ? DogTheme.accentOrange : DogTheme.primaryGreen))
                .clipShape(Capsule())
            }
            
            Chart {
                ForEach(sortedLogs) { log in
                    AreaMark(
                        x: .value("Date", log.date, unit: .day),
                        yStart: .value("Min", yMin),
                        yEnd: .value("Weight", log.value(for: store.preferredWeightUnit))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                DogTheme.primaryBlue.opacity(0.35),
                                DogTheme.primaryBlue.opacity(0.04)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Date", log.date, unit: .day),
                        y: .value("Weight", log.value(for: store.preferredWeightUnit))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(DogTheme.primaryBlue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Date", log.date, unit: .day),
                        y: .value("Weight", log.value(for: store.preferredWeightUnit))
                    )
                    .foregroundStyle(DogTheme.accentOrange)
                    .symbolSize(50)
                    .annotation(position: .top, alignment: .center, spacing: 4) {
                        Text(String(format: "%.1f", log.value(for: store.preferredWeightUnit)))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DogTheme.textSecondary)
                    }
                }
            }
            .chartYScale(domain: yMin...yMax)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                        .foregroundStyle(DogTheme.subtleGray)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundStyle(DogTheme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                        .foregroundStyle(DogTheme.subtleGray)
                    if let doubleVal = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.1f", doubleVal))
                                .font(.caption2)
                                .foregroundStyle(DogTheme.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(.top, 6)
        }
        .padding(16)
        .background(DogTheme.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Medical & Care Section
    
    private func medicalSection(for dog: Dog) -> some View {
        VStack(spacing: 20) {
            // Microchip & Allergies Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Identification & Allergies")
                    .font(.headline)
                
                HStack {
                    Label("Microchip:", systemImage: "barcode.viewfinder")
                        .font(.caption)
                        .foregroundStyle(DogTheme.textSecondary)
                    Text(dog.microchipId.isEmpty ? "Not registered" : dog.microchipId)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Allergies / Sensitivities")
                        .font(.caption)
                        .foregroundStyle(DogTheme.textSecondary)
                    
                    if dog.allergies.isEmpty {
                        Text("No known allergies reported.")
                            .font(.caption)
                            .foregroundStyle(DogTheme.primaryGreen)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(dog.allergies, id: \.self) { allergy in
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                    Text(allergy)
                                        .font(.caption.weight(.medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DogTheme.softOrange)
                                .foregroundStyle(DogTheme.accentOrange)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(DogTheme.pureWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Medications
            VStack(spacing: 12) {
                HStack {
                    Text("Medications & Supplements")
                        .font(.headline)
                    Spacer()
                    Button {
                        showingAddMedSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Med")
                        }
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DogTheme.softBlue)
                        .foregroundStyle(DogTheme.primaryBlue)
                        .clipShape(Capsule())
                    }
                }
                
                if dog.medications.isEmpty {
                    Text("No medications logged.")
                        .font(.subheadline)
                        .foregroundStyle(DogTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .background(DogTheme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    ForEach(dog.medications) { med in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(med.isActive ? DogTheme.softGreen : DogTheme.subtleGray)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "pills.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(med.isActive ? DogTheme.primaryGreen : Color.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(med.name)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(med.dosage) • \(med.frequency)")
                                    .font(.caption)
                                    .foregroundStyle(DogTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { med.isActive },
                                set: { _ in store.toggleMedication(dogId: dog.id, medicationId: med.id) }
                            ))
                            .labelsHidden()
                            .tint(DogTheme.primaryGreen)
                        }
                        .padding(14)
                        .background(DogTheme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            
            // Vet Visits
            VStack(spacing: 12) {
                HStack {
                    Text("Vet Visits & Checkups")
                        .font(.headline)
                    Spacer()
                    Button {
                        showingLogVetSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Visit")
                        }
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DogTheme.softOrange)
                        .foregroundStyle(DogTheme.accentOrange)
                        .clipShape(Capsule())
                    }
                }
                
                if dog.vetVisits.isEmpty {
                    Text("No veterinary visits logged yet.")
                        .font(.subheadline)
                        .foregroundStyle(DogTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .background(DogTheme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    ForEach(dog.vetVisits.sorted(by: { $0.date > $1.date })) { visit in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(visit.reason)
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Text(visit.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(DogTheme.textSecondary)
                            }
                            
                            if !visit.clinicName.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "building.2.fill")
                                        .font(.caption2)
                                    Text(visit.clinicName)
                                        .font(.caption)
                                }
                                .foregroundStyle(DogTheme.primaryBlue)
                            }
                            
                            if !visit.notes.isEmpty {
                                Text(visit.notes)
                                    .font(.caption)
                                    .foregroundStyle(DogTheme.textSecondary)
                            }
                            
                            if let followUp = visit.nextDueDate {
                                HStack(spacing: 4) {
                                    Image(systemName: "bell.fill")
                                        .font(.caption2)
                                    Text("Next due: \(followUp.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption2.weight(.semibold))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(DogTheme.softOrange)
                                .foregroundStyle(DogTheme.accentOrange)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(14)
                        .background(DogTheme.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }
    
    // MARK: - Add Medication Sheet
    
    private func addMedicationSheet(dogId: UUID) -> some View {
        NavigationStack {
            Form {
                Section("Medication Info") {
                    TextField("Name (e.g. Heartgard, Apoquel)", text: $newMedName)
                    TextField("Dosage (e.g. 1 tablet, 5mg)", text: $newMedDosage)
                    TextField("Frequency (e.g. Daily, Monthly)", text: $newMedFrequency)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddMedSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let med = Medication(
                            name: newMedName.trimmingCharacters(in: .whitespaces),
                            dosage: newMedDosage.trimmingCharacters(in: .whitespaces),
                            frequency: newMedFrequency.trimmingCharacters(in: .whitespaces),
                            isActive: true
                        )
                        store.addMedication(to: dogId, medication: med)
                        newMedName = ""
                        newMedDosage = ""
                        newMedFrequency = "Daily"
                        showingAddMedSheet = false
                    }
                    .font(.headline)
                    .foregroundStyle(DogTheme.accentOrange)
                    .disabled(newMedName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// FlowLayout helper for chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
        height = y + maxHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
    }
}

#Preview("Habits Tab") {
    let store = DogStore()
    if let first = store.dogs.first {
        NavigationStack {
            DogDetailView(store: store, dogId: first.id)
        }
    }
}

#Preview("Weight History Graph") {
    let store = DogStore()
    if let first = store.dogs.first {
        NavigationStack {
            DogDetailView(store: store, dogId: first.id, initialTab: .health)
        }
    }
}
