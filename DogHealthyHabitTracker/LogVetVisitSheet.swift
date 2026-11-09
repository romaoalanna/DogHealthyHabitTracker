import SwiftUI

struct LogVetVisitSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (VetVisit) -> Void
    
    @State private var reason: String = ""
    @State private var clinicName: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var hasFollowUp: Bool = false
    @State private var followUpDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Visit Details") {
                    TextField("Reason (e.g. Annual Rabies, Checkup)", text: $reason)
                    TextField("Clinic / Vet Name", text: $clinicName)
                    DatePicker("Visit Date", selection: $date, in: ...Date(), displayedComponents: .date)
                }
                
                Section("Follow-Up / Next Due") {
                    Toggle("Schedule Follow-Up Reminder", isOn: $hasFollowUp)
                    if hasFollowUp {
                        DatePicker("Next Due Date", selection: $followUpDate, in: Date()..., displayedComponents: .date)
                    }
                }
                
                Section("Veterinarian Notes") {
                    TextField("Instructions, vaccinations given, exam notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Vet Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let visit = VetVisit(
                            date: date,
                            reason: reason.trimmingCharacters(in: .whitespaces),
                            clinicName: clinicName.trimmingCharacters(in: .whitespaces),
                            notes: notes.trimmingCharacters(in: .whitespaces),
                            nextDueDate: hasFollowUp ? followUpDate : nil
                        )
                        onSave(visit)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(DogTheme.accentOrange)
                    .disabled(reason.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
