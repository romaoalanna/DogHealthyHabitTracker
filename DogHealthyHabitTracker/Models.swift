import Foundation
import SwiftUI

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg = "kg"
    case lbs = "lbs"
    
    var id: String { rawValue }
    
    static func convert(weightKg: Double, to unit: WeightUnit) -> Double {
        switch unit {
        case .kg:
            return weightKg
        case .lbs:
            return weightKg * 2.20462
        }
    }
    
    static func toKg(weight: Double, from unit: WeightUnit) -> Double {
        switch unit {
        case .kg:
            return weight
        case .lbs:
            return weight / 2.20462
        }
    }
}

enum DogGender: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .male: return "figure.stand"
        case .female: return "figure.stand.dress"
        }
    }
    
    var tintColor: Color {
        switch self {
        case .male: return DogTheme.primaryBlue
        case .female: return DogTheme.salmonPink
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .male: return DogTheme.softBlue
        case .female: return DogTheme.softSalmonPink
        }
    }
}

enum HabitCategory: String, Codable, CaseIterable, Identifiable {
    case walk = "Walk & Exercise"
    case nutrition = "Food & Water"
    case medication = "Medication"
    case hygiene = "Grooming & Teeth"
    case wellness = "Play & Wellness"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .walk: return "figure.walk"
        case .nutrition: return "fork.knife"
        case .medication: return "pills.fill"
        case .hygiene: return "sparkles"
        case .wellness: return "heart.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .walk: return DogTheme.primaryGreen
        case .nutrition: return DogTheme.primaryBlue
        case .medication: return DogTheme.accentOrange
        case .hygiene: return Color.teal
        case .wellness: return Color.indigo
        }
    }
}

struct HabitComment: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date()
    var text: String
}

struct DailyHabit: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var category: HabitCategory
    var targetFrequency: String = "Once Daily"
    var completedDateStrings: [String] = [] // format: yyyy-MM-dd
    var notes: String = "" // Instructions / guidelines
    var comments: [HabitComment] = []
    
    var targetCountPerDay: Int {
        if targetFrequency.contains("3x") {
            return 3
        } else if targetFrequency.contains("2x") {
            return 2
        }
        return 1
    }
    
    static func dateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    func completedCount(on date: Date = Date()) -> Int {
        let key = DailyHabit.dateKey(from: date)
        return completedDateStrings.filter { $0 == key }.count
    }
    
    func isCompleted(on date: Date = Date()) -> Bool {
        return completedCount(on: date) >= targetCountPerDay
    }
    
    mutating func toggleCompletion(for date: Date = Date()) {
        let key = DailyHabit.dateKey(from: date)
        let current = completedCount(on: date)
        if current >= targetCountPerDay {
            completedDateStrings.removeAll { $0 == key }
        } else {
            completedDateStrings.append(key)
        }
    }
    
    mutating func addComment(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        comments.append(HabitComment(text: trimmed))
    }
}

struct WeightLog: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var weight: Double // stored in kg
    var notes: String = ""
    
    func formatted(for unit: WeightUnit) -> String {
        let val = WeightUnit.convert(weightKg: weight, to: unit)
        return String(format: "%.1f %@", val, unit.rawValue)
    }
    
    func value(for unit: WeightUnit) -> Double {
        WeightUnit.convert(weightKg: weight, to: unit)
    }
}

struct VetVisit: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var reason: String
    var clinicName: String
    var notes: String = ""
    var nextDueDate: Date?
}

struct Medication: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var dosage: String
    var frequency: String
    var isActive: Bool = true
}

struct Dog: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var breed: String
    var birthDate: Date
    var gender: DogGender
    var weightKg: Double
    var iconName: String = "pawprint.fill"
    var avatarColorHex: String = "#28A745"
    var photoData: Data? = nil
    var microchipId: String = ""
    var allergies: [String] = []
    var dailyHabits: [DailyHabit] = []
    var weightLogs: [WeightLog] = []
    var vetVisits: [VetVisit] = []
    var medications: [Medication] = []
    
    var ageString: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: birthDate, to: Date())
        let years = components.year ?? 0
        let months = components.month ?? 0
        
        if years > 0 {
            if months > 0 {
                return "\(years) yr\(years == 1 ? "" : "s") \(months) mo"
            }
            return "\(years) yr\(years == 1 ? "" : "s")"
        } else {
            return "\(max(1, months)) mo\(months == 1 ? "" : "s")"
        }
    }
    
    var avatarColor: Color {
        Color(hex: avatarColorHex) ?? DogTheme.primaryGreen
    }
    
    var todayHabitsCompletedCount: Int {
        dailyHabits.filter { $0.isCompleted(on: Date()) }.count
    }
    
    var todayHabitProgress: Double {
        guard !dailyHabits.isEmpty else { return 0.0 }
        let totalTarget = dailyHabits.reduce(0) { $0 + $1.targetCountPerDay }
        guard totalTarget > 0 else { return 0.0 }
        let currentCompleted = dailyHabits.reduce(0) { $0 + min($1.completedCount(on: Date()), $1.targetCountPerDay) }
        return Double(currentCompleted) / Double(totalTarget)
    }
    
    var latestWeight: Double {
        if let latest = weightLogs.sorted(by: { $0.date > $1.date }).first {
            return latest.weight
        }
        return weightKg
    }
    
    func displayWeight(for unit: WeightUnit) -> Double {
        WeightUnit.convert(weightKg: latestWeight, to: unit)
    }
    
    func formattedWeight(for unit: WeightUnit) -> String {
        let val = displayWeight(for: unit)
        return String(format: "%.1f %@", val, unit.rawValue)
    }
}

// Color hex helper
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
    
    func toHex() -> String {
        let uic = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uic.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(Float(red * 255)),
                      lroundf(Float(green * 255)),
                      lroundf(Float(blue * 255)))
    }
}
