import SwiftUI

struct LogWeightSheet: View {
    @Environment(\.dismiss) private var dismiss
    var currentWeightKg: Double
    var initialUnit: WeightUnit = .kg
    var onSave: (WeightLog) -> Void
    
    @State private var selectedUnit: WeightUnit
    @State private var weightString: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    
    init(currentWeightKg: Double, initialUnit: WeightUnit = .kg, onSave: @escaping (WeightLog) -> Void) {
        self.currentWeightKg = currentWeightKg
        self.initialUnit = initialUnit
        self.onSave = onSave
        _selectedUnit = State(initialValue: initialUnit)
        let displayVal = WeightUnit.convert(weightKg: currentWeightKg, to: initialUnit)
        _weightString = State(initialValue: String(format: "%.1f", displayVal))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Weight Measurement") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("Weight", text: $weightString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                        
                        Picker("Unit", selection: $selectedUnit) {
                            ForEach(WeightUnit.allCases) { u in
                                Text(u.rawValue).tag(u)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 110)
                        .onChange(of: selectedUnit) { oldUnit, newUnit in
                            if let val = Double(weightString.replacingOccurrences(of: ",", with: ".")) {
                                let kgVal = WeightUnit.toKg(weight: val, from: oldUnit)
                                let converted = WeightUnit.convert(weightKg: kgVal, to: newUnit)
                                weightString = String(format: "%.1f", converted)
                            }
                        }
                    }
                    
                    DatePicker("Date Recorded", selection: $date, in: ...Date(), displayedComponents: .date)
                }
                
                Section("Notes (Optional)") {
                    TextField("e.g. Weigh-in before breakfast", text: $notes)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entered = Double(weightString.replacingOccurrences(of: ",", with: ".")) ?? WeightUnit.convert(weightKg: currentWeightKg, to: selectedUnit)
                        let weightInKg = WeightUnit.toKg(weight: entered, from: selectedUnit)
                        let log = WeightLog(date: date, weight: weightInKg, notes: notes)
                        onSave(log)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(DogTheme.accentOrange)
                }
            }
        }
    }
}

#Preview {
    LogWeightSheet(currentWeightKg: 25.0) { _ in }
}
