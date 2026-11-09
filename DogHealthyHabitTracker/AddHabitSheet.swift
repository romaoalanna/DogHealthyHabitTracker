import SwiftUI

struct AddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (DailyHabit) -> Void
    
    @State private var title: String = ""
    @State private var category: HabitCategory = .walk
    @State private var targetFrequency: String = "Once Daily"
    @State private var notes: String = ""
    
    private let frequencyOptions = [
        "Once Daily",
        "2x a Day",
        "3x a Day",
        "Weekly",
        "As Needed"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Habit Details") {
                    TextField("Habit Name (e.g. Afternoon Stroll)", text: $title)
                    
                    Picker("Category", selection: $category) {
                        ForEach(HabitCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }
                    
                    Picker("Target Frequency", selection: $targetFrequency) {
                        ForEach(frequencyOptions, id: \.self) { freq in
                            Text(freq).tag(freq)
                        }
                    }
                }
                
                Section("Instructions & Notes (Optional)") {
                    TextField("e.g. 1.5 cups after morning walk, fresh bowl", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Category Preview") {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: category.iconName)
                                .font(.title3)
                                .foregroundStyle(category.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title.isEmpty ? "New Habit" : title)
                                .font(.headline)
                            
                            Text("\(category.rawValue) • \(targetFrequency)")
                                .font(.caption)
                                .foregroundStyle(DogTheme.textSecondary)
                            
                            if !notes.isEmpty {
                                Text(notes)
                                    .font(.caption2)
                                    .foregroundStyle(DogTheme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Daily Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let habit = DailyHabit(
                            title: title.trimmingCharacters(in: .whitespaces),
                            category: category,
                            targetFrequency: targetFrequency,
                            notes: notes.trimmingCharacters(in: .whitespaces)
                        )
                        onAdd(habit)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(DogTheme.accentOrange)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddHabitSheet { _ in }
}
