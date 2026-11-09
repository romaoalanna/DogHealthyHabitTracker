import Foundation
import SwiftUI
import Observation

@Observable
class DogStore {
    var dogs: [Dog] = [] {
        didSet {
            save()
        }
    }
    
    var preferredWeightUnit: WeightUnit = {
        if let saved = UserDefaults.standard.string(forKey: "preferred_weight_unit"),
           let unit = WeightUnit(rawValue: saved) {
            return unit
        }
        return .kg
    }() {
        didSet {
            UserDefaults.standard.set(preferredWeightUnit.rawValue, forKey: "preferred_weight_unit")
        }
    }
    
    init() {
        load()
        if dogs.isEmpty {
            loadSampleData()
        }
    }
    
    // MARK: - CRUD Dogs
    
    func addDog(_ dog: Dog) {
        dogs.append(dog)
    }
    
    func updateDog(_ dog: Dog) {
        if let index = dogs.firstIndex(where: { $0.id == dog.id }) {
            dogs[index] = dog
        }
    }
    
    func deleteDog(at offsets: IndexSet) {
        dogs.remove(atOffsets: offsets)
    }
    
    func deleteDog(_ dog: Dog) {
        dogs.removeAll { $0.id == dog.id }
    }
    
    // MARK: - Habit Management
    
    func toggleHabit(dogId: UUID, habitId: UUID, for date: Date = Date()) {
        guard let dogIndex = dogs.firstIndex(where: { $0.id == dogId }),
              let habitIndex = dogs[dogIndex].dailyHabits.firstIndex(where: { $0.id == habitId }) else {
            return
        }
        dogs[dogIndex].dailyHabits[habitIndex].toggleCompletion(for: date)
    }
    
    func addHabit(to dogId: UUID, habit: DailyHabit) {
        guard let index = dogs.firstIndex(where: { $0.id == dogId }) else { return }
        dogs[index].dailyHabits.append(habit)
    }
    
    func deleteHabit(from dogId: UUID, habitId: UUID) {
        guard let index = dogs.firstIndex(where: { $0.id == dogId }) else { return }
        dogs[index].dailyHabits.removeAll { $0.id == habitId }
    }
    
    func addComment(to dogId: UUID, habitId: UUID, comment: String) {
        guard let dogIndex = dogs.firstIndex(where: { $0.id == dogId }),
              let habitIndex = dogs[dogIndex].dailyHabits.firstIndex(where: { $0.id == habitId }) else { return }
        dogs[dogIndex].dailyHabits[habitIndex].addComment(comment)
    }
    
    func deleteComment(from dogId: UUID, habitId: UUID, commentId: UUID) {
        guard let dogIndex = dogs.firstIndex(where: { $0.id == dogId }),
              let habitIndex = dogs[dogIndex].dailyHabits.firstIndex(where: { $0.id == habitId }) else { return }
        dogs[dogIndex].dailyHabits[habitIndex].comments.removeAll { $0.id == commentId }
    }
    
    func updateHabitNotes(dogId: UUID, habitId: UUID, notes: String) {
        guard let dogIndex = dogs.firstIndex(where: { $0.id == dogId }),
              let habitIndex = dogs[dogIndex].dailyHabits.firstIndex(where: { $0.id == habitId }) else { return }
        dogs[dogIndex].dailyHabits[habitIndex].notes = notes
    }
    
    // MARK: - Weight Logs
    
    func addWeightLog(to dogId: UUID, log: WeightLog) {
        guard let index = dogs.firstIndex(where: { $0.id == dogId }) else { return }
        dogs[index].weightLogs.append(log)
        // Keep weightKg updated with the latest logged weight
        dogs[index].weightKg = log.weight
    }
    
    func deleteWeightLog(from dogId: UUID, logId: UUID) {
        guard let index = dogs.firstIndex(where: { $0.id == dogId }) else { return }
        dogs[index].weightLogs.removeAll { $0.id == logId }
    }
    
    // MARK: - Vet Visits & Meds
    
    func addVetVisit(to dogId: UUID, visit: VetVisit) {
        guard let index = dogs.firstIndex(where: { $0.id == dogId }) else { return }
        dogs[index].vetVisits.append(visit)
    }
    
    func addMedication(to dogId: UUID, medication: Medication) {
        guard let index = dogs.firstIndex(where: { $0.id == dogId }) else { return }
        dogs[index].medications.append(medication)
    }
    
    func toggleMedication(dogId: UUID, medicationId: UUID) {
        guard let dogIndex = dogs.firstIndex(where: { $0.id == dogId }),
              let medIndex = dogs[dogIndex].medications.firstIndex(where: { $0.id == medicationId }) else { return }
        dogs[dogIndex].medications[medIndex].isActive.toggle()
    }
    
    // MARK: - Persistence
    
    private func fileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("dog_health_data.json")
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(dogs)
            try data.write(to: fileURL(), options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Failed to save dogs: \(error.localizedDescription)")
        }
    }
    
    private func load() {
        let url = fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            dogs = try JSONDecoder().decode([Dog].self, from: data)
        } catch {
            print("Failed to load dogs: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sample Data
    
    private func loadSampleData() {
        let calendar = Calendar.current
        let todayStr = DailyHabit.dateKey(from: Date())
        let yesterdayStr = DailyHabit.dateKey(from: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        
        let busterBirthDate = calendar.date(byAdding: .year, value: -3, to: Date()) ?? Date()
        let lunaBirthDate = calendar.date(byAdding: .month, value: -14, to: Date()) ?? Date()
        
        let buster = Dog(
            name: "Buster",
            breed: "Golden Retriever",
            birthDate: busterBirthDate,
            gender: .male,
            weightKg: 31.5,
            iconName: "pawprint.fill",
            avatarColorHex: "#28A745", // Green
            microchipId: "985-141-002-392",
            allergies: ["Chicken", "Certain Grass Pollens"],
            dailyHabits: [
                DailyHabit(
                    title: "Morning 30-min Walk",
                    category: .walk,
                    targetFrequency: "Once Daily",
                    completedDateStrings: [todayStr, yesterdayStr],
                    notes: "Use the 6ft flat leash and avoid dog parks when crowded",
                    comments: [
                        HabitComment(date: Date(), text: "Buster was super energetic this morning!")
                    ]
                ),
                DailyHabit(
                    title: "Potty & Fresh Water Break",
                    category: .nutrition,
                    targetFrequency: "3x a Day",
                    completedDateStrings: [todayStr, todayStr, yesterdayStr, yesterdayStr, yesterdayStr],
                    notes: "Refresh water bowl with cold filtered water after outdoor break",
                    comments: [
                        HabitComment(date: Date(), text: "Morning and afternoon breaks completed, drinking plenty of water.")
                    ]
                ),
                DailyHabit(
                    title: "Breakfast & Fresh Bowl",
                    category: .nutrition,
                    targetFrequency: "Once Daily",
                    completedDateStrings: [todayStr, yesterdayStr],
                    notes: "1.5 cups salmon recipe kibble"
                ),
                DailyHabit(
                    title: "Evening Walk & Fetch",
                    category: .walk,
                    targetFrequency: "Once Daily",
                    completedDateStrings: []
                ),
                DailyHabit(
                    title: "Teeth Brushing / Dental Stick",
                    category: .hygiene,
                    targetFrequency: "Once Daily",
                    completedDateStrings: [yesterdayStr],
                    notes: "Enzymatic poultry flavor toothpaste"
                ),
                DailyHabit(
                    title: "Glucosamine Joint Chew",
                    category: .medication,
                    targetFrequency: "Once Daily",
                    completedDateStrings: [todayStr, yesterdayStr]
                )
            ],
            weightLogs: [
                WeightLog(
                    date: calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
                    weight: 30.8,
                    notes: "Annual check-up weigh-in"
                ),
                WeightLog(
                    date: calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
                    weight: 31.2,
                    notes: "Post-holiday weigh-in"
                ),
                WeightLog(
                    date: Date(),
                    weight: 31.5,
                    notes: "Current healthy target weight"
                )
            ],
            vetVisits: [
                VetVisit(
                    date: calendar.date(byAdding: .month, value: -4, to: Date()) ?? Date(),
                    reason: "Annual Exam & Rabies Booster",
                    clinicName: "Happy Paws Vet Hospital",
                    notes: "Coat looks shiny, teeth in good condition. Heart and lungs clear.",
                    nextDueDate: calendar.date(byAdding: .month, value: 8, to: Date())
                ),
                VetVisit(
                    date: calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
                    reason: "Ear Checkup",
                    clinicName: "Happy Paws Vet Hospital",
                    notes: "Mild yeast infection treated with topical drops. Fully resolved.",
                    nextDueDate: nil
                )
            ],
            medications: [
                Medication(name: "Heartgard Plus", dosage: "1 chewable", frequency: "Monthly", isActive: true),
                Medication(name: "NexGard Flea/Tick", dosage: "1 chewable", frequency: "Monthly", isActive: true),
                Medication(name: "Glucosamine Supplement", dosage: "2 chews", frequency: "Daily", isActive: true)
            ]
        )
        
        let luna = Dog(
            name: "Luna",
            breed: "French Bulldog",
            birthDate: lunaBirthDate,
            gender: .female,
            weightKg: 11.8,
            iconName: "heart.fill",
            avatarColorHex: "#FA7A85", // Salmon Pink
            microchipId: "985-230-891-114",
            allergies: ["Beef", "Dairy"],
            dailyHabits: [
                DailyHabit(
                    title: "Gentle Morning Walk",
                    category: .walk,
                    targetFrequency: "Once Daily",
                    completedDateStrings: [todayStr, yesterdayStr],
                    notes: "Keep walks under 20 mins if temperature is above 75°F"
                ),
                DailyHabit(
                    title: "Potty & Hydration Check",
                    category: .nutrition,
                    targetFrequency: "3x a Day",
                    completedDateStrings: [todayStr, yesterdayStr, yesterdayStr, yesterdayStr],
                    notes: "Check breathing and cooling down after potty"
                ),
                DailyHabit(
                    title: "Morning Grain-Free Meal",
                    category: .nutrition,
                    targetFrequency: "Once Daily",
                    completedDateStrings: [todayStr, yesterdayStr]
                ),
                DailyHabit(
                    title: "Face Wrinkle & Ear Cleaning",
                    category: .hygiene,
                    targetFrequency: "Once Daily",
                    completedDateStrings: [todayStr],
                    notes: "Use vet-approved antiseptic wipes",
                    comments: [
                        HabitComment(date: Date(), text: "Folds look nice and clean, no redness today.")
                    ]
                ),
                DailyHabit(
                    title: "Evening Calming Massage",
                    category: .wellness,
                    targetFrequency: "Once Daily",
                    completedDateStrings: []
                )
            ],
            weightLogs: [
                WeightLog(
                    date: calendar.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
                    weight: 11.5,
                    notes: "Healthy baseline"
                ),
                WeightLog(
                    date: Date(),
                    weight: 11.8,
                    notes: "Steady and stable"
                )
            ],
            vetVisits: [
                VetVisit(
                    date: calendar.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
                    reason: "Routine Wellness & Allergy Review",
                    clinicName: "City Pet Health Center",
                    notes: "Recommended grain-free hypoallergenic diet.",
                    nextDueDate: calendar.date(byAdding: .month, value: 10, to: Date())
                )
            ],
            medications: [
                Medication(name: "Simparica Trio", dosage: "1 tablet", frequency: "Monthly", isActive: true),
                Medication(name: "Apoquel", dosage: "5.4 mg (as needed)", frequency: "PRN", isActive: false)
            ]
        )
        
        dogs = [buster, luna]
    }
}
