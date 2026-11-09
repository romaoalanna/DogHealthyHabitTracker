import SwiftUI

struct DogListView: View {
    @State private var store = DogStore()
    @State private var showingAddDogSheet = false
    @State private var dogToEdit: Dog?
    
    // Overall stats
    private var totalHabitsToday: Int {
        store.dogs.reduce(0) { $0 + $1.dailyHabits.reduce(0) { $0 + $1.targetCountPerDay } }
    }
    
    private var completedHabitsToday: Int {
        store.dogs.reduce(0) { $0 + $1.dailyHabits.reduce(0) { $0 + min($1.completedCount(on: Date()), $1.targetCountPerDay) } }
    }
    
    private var overallProgress: Double {
        guard totalHabitsToday > 0 else { return 0 }
        return Double(completedHabitsToday) / Double(totalHabitsToday)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if store.dogs.isEmpty {
                        emptyStateView
                    } else {
                        // Top Summary Dashboard Banner
                        summaryDashboard
                        
                        // Dogs Section Header
                        HStack {
                            Text("Your Dogs")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text("\(store.dogs.count) registered")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DogTheme.textSecondary)
                        }
                        .padding(.horizontal, 4)
                        
                        // Dogs List Cards
                        LazyVStack(spacing: 16) {
                            ForEach(store.dogs) { dog in
                                NavigationLink(destination: DogDetailView(store: store, dogId: dog.id)) {
                                    dogCard(for: dog)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(DogTheme.backgroundWhite)
            .navigationTitle("Dog Health Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddDogSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.headline)
                            Text("Add Dog")
                                .font(.subheadline.weight(.bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DogTheme.accentOrange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: DogTheme.accentOrange.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .sheet(isPresented: $showingAddDogSheet) {
                AddDogView(initialWeightUnit: store.preferredWeightUnit) { newDog in
                    store.addDog(newDog)
                }
            }
        }
    }
    
    // MARK: - Summary Dashboard
    
    private var summaryDashboard: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "pawprint.fill")
                            .font(.caption)
                            .foregroundStyle(DogTheme.primaryGreen)
                        Text("TODAY'S HEALTH HABITS")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(DogTheme.textSecondary)
                    }
                    
                    Text("\(completedHabitsToday) of \(totalHabitsToday) Steps Done")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(DogTheme.subtleGray, lineWidth: 6)
                        .frame(width: 54, height: 54)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(overallProgress))
                        .stroke(
                            DogTheme.greenBlueGradient,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 54, height: 54)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: overallProgress)
                    
                    Text("\(Int(overallProgress * 100))%")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(DogTheme.primaryBlue)
                }
            }
            
            // Habit Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DogTheme.subtleGray)
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(DogTheme.greenBlueGradient)
                        .frame(width: max(0, min(geo.size.width * CGFloat(overallProgress), geo.size.width)), height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: overallProgress)
                }
            }
            .frame(height: 8)
            
            // Quick motivation note
            HStack(spacing: 6) {
                Image(systemName: overallProgress == 1.0 ? "sparkles" : "flame.fill")
                    .font(.caption)
                    .foregroundStyle(DogTheme.accentOrange)
                
                Text(overallProgress == 1.0 ? "Great job! All your dogs are fully cared for today!" : "Keep up the routine to keep your dogs healthy and happy.")
                    .font(.caption)
                    .foregroundStyle(DogTheme.textSecondary)
                
                Spacer()
            }
        }
        .padding(18)
        .background(DogTheme.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Dog Card
    
    private func dogCard(for dog: Dog) -> some View {
        VStack(spacing: 14) {
            // Dog Header Info
            HStack(spacing: 14) {
                // Avatar (supports uploaded photo or icon)
                DogAvatarView(
                    photoData: dog.photoData,
                    iconName: dog.iconName,
                    avatarColor: dog.avatarColor,
                    size: 60
                )
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(dog.name)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        Image(systemName: dog.gender == .male ? "figure.stand" : "figure.stand.dress")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(dog.gender.backgroundColor)
                            .foregroundStyle(dog.gender.tintColor)
                            .clipShape(Capsule())
                    }
                    
                    Text(dog.breed)
                        .font(.subheadline)
                        .foregroundStyle(DogTheme.textSecondary)
                    
                    HStack(spacing: 10) {
                        Label(dog.ageString, systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(DogTheme.textSecondary)
                        
                        Label(dog.formattedWeight(for: store.preferredWeightUnit), systemImage: "scalemass")
                            .font(.caption2)
                            .foregroundStyle(DogTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                // Status Badge
                VStack(alignment: .trailing, spacing: 4) {
                    if dog.dailyHabits.isEmpty {
                        Text("No Habits")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DogTheme.subtleGray)
                            .foregroundStyle(DogTheme.textSecondary)
                            .clipShape(Capsule())
                    } else if dog.todayHabitProgress == 1.0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("All Done")
                        }
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DogTheme.softGreen)
                        .foregroundStyle(DogTheme.primaryGreen)
                        .clipShape(Capsule())
                    } else {
                        let remaining = dog.dailyHabits.count - dog.todayHabitsCompletedCount
                        Text("\(remaining) left")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DogTheme.softOrange)
                            .foregroundStyle(DogTheme.accentOrange)
                            .clipShape(Capsule())
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DogTheme.textSecondary.opacity(0.6))
                        .padding(.top, 4)
                }
            }
            
            // Quick Habit Checklist Row (Allows quick check-in right from card!)
            if !dog.dailyHabits.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Checklist")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DogTheme.textSecondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(dog.dailyHabits) { habit in
                                let isDone = habit.isCompleted(on: Date())
                                let count = habit.completedCount(on: Date())
                                let target = habit.targetCountPerDay
                                
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        store.toggleHabit(dogId: dog.id, habitId: habit.id)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: isDone ? "checkmark.circle.fill" : (count > 0 ? "circle.inset.filled" : "circle"))
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(isDone ? DogTheme.primaryGreen : habit.category.color)
                                        
                                        Text(habit.title)
                                            .font(.caption.weight(isDone ? .regular : .semibold))
                                            .strikethrough(isDone, color: DogTheme.textSecondary)
                                            .foregroundStyle(isDone ? DogTheme.textSecondary : .primary)
                                            .lineLimit(1)
                                        
                                        if target > 1 {
                                            Text("\(count)/\(target)")
                                                .font(.caption2.weight(.bold))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(isDone ? DogTheme.softGreen : DogTheme.softOrange)
                                                .foregroundStyle(isDone ? DogTheme.primaryGreen : DogTheme.accentOrange)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isDone ? DogTheme.softGreen.opacity(0.5) : DogTheme.subtleGray.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(16)
        .background(DogTheme.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 20)
            
            ZStack {
                Circle()
                    .fill(DogTheme.softGreen)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(DogTheme.primaryGreen)
            }
            .shadow(color: DogTheme.primaryGreen.opacity(0.15), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text("No Dogs Added Yet")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Start tracking daily walks, nutrition, teeth brushing, vet visits, and weight for your four-legged family members.")
                    .font(.subheadline)
                    .foregroundStyle(DogTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Button {
                showingAddDogSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    Text("Add Your First Dog")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(DogTheme.accentOrange)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: DogTheme.accentOrange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 32)
            
            Spacer().frame(height: 20)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(DogTheme.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    DogListView()
}
