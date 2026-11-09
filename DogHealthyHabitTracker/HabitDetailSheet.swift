import SwiftUI

struct HabitDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    var dogId: UUID
    var habitId: UUID
    var store: DogStore
    
    @State private var newCommentText: String = ""
    @State private var editingNotes: String = ""
    @State private var isEditingNotes: Bool = false
    
    private var dog: Dog? {
        store.dogs.first(where: { $0.id == dogId })
    }
    
    private var habit: DailyHabit? {
        dog?.dailyHabits.first(where: { $0.id == habitId })
    }
    
    var body: some View {
        NavigationStack {
            if let habit = habit {
                List {
                    // Habit Summary Header Card
                    Section {
                        VStack(spacing: 12) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(habit.category.color.opacity(0.15))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: habit.category.iconName)
                                        .font(.title2)
                                        .foregroundStyle(habit.category.color)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(habit.title)
                                        .font(.headline.weight(.bold))
                                    
                                    HStack(spacing: 6) {
                                        Text(habit.category.rawValue)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(habit.category.color)
                                        
                                        Text("•")
                                            .font(.caption)
                                            .foregroundStyle(DogTheme.textSecondary)
                                        
                                        Text(habit.targetFrequency)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(DogTheme.textSecondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                            
                            // Today's Progress row
                            HStack {
                                let count = habit.completedCount(on: Date())
                                let target = habit.targetCountPerDay
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Today's Progress")
                                        .font(.caption)
                                        .foregroundStyle(DogTheme.textSecondary)
                                    
                                    Text(target > 1 ? "\(count) of \(target) completed" : (habit.isCompleted(on: Date()) ? "Completed today" : "Not yet completed"))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(habit.isCompleted(on: Date()) ? DogTheme.primaryGreen : DogTheme.accentOrange)
                                }
                                
                                Spacer()
                                
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        store.toggleHabit(dogId: dogId, habitId: habit.id)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: habit.isCompleted(on: Date()) ? "checkmark.circle.fill" : "circle.dashed")
                                        Text(target > 1 ? "+ Log Step (\(count)/\(target))" : (habit.isCompleted(on: Date()) ? "Done" : "Mark Done"))
                                    }
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(habit.isCompleted(on: Date()) ? DogTheme.softGreen : DogTheme.softOrange)
                                    .foregroundStyle(habit.isCompleted(on: Date()) ? DogTheme.primaryGreen : DogTheme.accentOrange)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    
                    // Instructions & Notes Section
                    Section {
                        if isEditingNotes {
                            VStack(alignment: .leading, spacing: 10) {
                                TextField("Enter instructions or notes...", text: $editingNotes, axis: .vertical)
                                    .lineLimit(2...5)
                                
                                HStack {
                                    Button("Save Notes") {
                                        store.updateHabitNotes(dogId: dogId, habitId: habit.id, notes: editingNotes)
                                        isEditingNotes = false
                                    }
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(DogTheme.accentOrange)
                                    
                                    Spacer()
                                    
                                    Button("Cancel") {
                                        isEditingNotes = false
                                    }
                                    .font(.caption)
                                    .foregroundStyle(DogTheme.textSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                        } else {
                            HStack(alignment: .top) {
                                if habit.notes.isEmpty {
                                    Text("No specific instructions added yet.")
                                        .font(.subheadline)
                                        .foregroundStyle(DogTheme.textSecondary)
                                } else {
                                    Text(habit.notes)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    editingNotes = habit.notes
                                    isEditingNotes = true
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(DogTheme.accentOrange)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Routine Notes & Instructions")
                    }
                    
                    // Comments Section
                    Section {
                        // New comment input
                        HStack(spacing: 10) {
                            TextField("Add a comment (e.g. walked 2 miles, drank well)...", text: $newCommentText)
                                .textFieldStyle(.plain)
                            
                            Button {
                                addComment()
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : DogTheme.accentOrange)
                            }
                            .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty)
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        
                        // Comment logs list
                        if habit.comments.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 6) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.title2)
                                        .foregroundStyle(DogTheme.textSecondary.opacity(0.6))
                                    Text("No comments yet")
                                        .font(.caption)
                                        .foregroundStyle(DogTheme.textSecondary)
                                    Text("Leave quick observations or notes about today's routine.")
                                        .font(.caption2)
                                        .foregroundStyle(DogTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 12)
                                Spacer()
                            }
                        } else {
                            ForEach(habit.comments.sorted(by: { $0.date > $1.date })) { comment in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(comment.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    
                                    Text(comment.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(DogTheme.textSecondary)
                                }
                                .padding(.vertical, 3)
                            }
                            .onDelete { offsets in
                                let sortedComments = habit.comments.sorted(by: { $0.date > $1.date })
                                for index in offsets {
                                    let c = sortedComments[index]
                                    store.deleteComment(from: dogId, habitId: habit.id, commentId: c.id)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("Activity Comments (\(habit.comments.count))")
                            Spacer()
                            if !habit.comments.isEmpty {
                                Text("Swipe to delete")
                                    .font(.caption2)
                                    .foregroundStyle(DogTheme.textSecondary)
                            }
                        }
                    }
                }
                .navigationTitle("Habit Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundStyle(DogTheme.accentOrange)
                    }
                }
            } else {
                Text("Habit not found")
            }
        }
    }
    
    private func addComment() {
        let trimmed = newCommentText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.addComment(to: dogId, habitId: habitId, comment: trimmed)
        newCommentText = ""
    }
}

#Preview {
    let store = DogStore()
    if let dog = store.dogs.first, let habit = dog.dailyHabits.first {
        HabitDetailSheet(dogId: dog.id, habitId: habit.id, store: store)
    }
}
