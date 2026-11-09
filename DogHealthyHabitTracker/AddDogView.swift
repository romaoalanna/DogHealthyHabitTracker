import SwiftUI
import PhotosUI

struct AddDogView: View {
    @Environment(\.dismiss) private var dismiss
    var dogToEdit: Dog?
    var initialWeightUnit: WeightUnit = .kg
    var onSave: (Dog) -> Void
    
    @State private var name: String = ""
    @State private var breed: String = ""
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
    @State private var gender: DogGender = .male
    @State private var weightUnit: WeightUnit = .kg
    @State private var weightString: String = "15.0"
    @State private var microchipId: String = ""
    @State private var allergiesString: String = ""
    @State private var selectedIcon: String = "pawprint.fill"
    @State private var selectedColorHex: String = "#28A745"
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    
    // Preset habit selections for new dog
    @State private var includeMorningWalk = true
    @State private var includeNutrition = true
    @State private var includePottyWater = true
    @State private var includeEveningWalk = true
    @State private var includeTeethBrushing = true
    @State private var includeSupplements = false
    
    private let availableIcons = [
        "pawprint.fill",
        "heart.fill",
        "star.fill",
        "bolt.fill",
        "sparkles",
        "figure.walk",
        "leaf.fill",
        "shield.fill"
    ]
    
    private let availableColors: [(hex: String, name: String)] = [
        ("#28A745", "Emerald Green"),
        ("#168038", "Forest Green"),
        ("#2B82E8", "Sky Blue"),
        ("#1253A4", "Ocean Blue"),
        ("#FA8231", "Vibrant Orange"),
        ("#FA7A85", "Salmon Pink"),
        ("#00A896", "Teal"),
        ("#8854D0", "Purple")
    ]
    
    var isEditing: Bool {
        dogToEdit != nil
    }
    
    init(dogToEdit: Dog? = nil, initialWeightUnit: WeightUnit = .kg, onSave: @escaping (Dog) -> Void) {
        self.dogToEdit = dogToEdit
        self.initialWeightUnit = initialWeightUnit
        self.onSave = onSave
        
        if let dog = dogToEdit {
            _name = State(initialValue: dog.name)
            _breed = State(initialValue: dog.breed)
            _birthDate = State(initialValue: dog.birthDate)
            _gender = State(initialValue: dog.gender)
            _weightUnit = State(initialValue: initialWeightUnit)
            let displayVal = WeightUnit.convert(weightKg: dog.weightKg, to: initialWeightUnit)
            _weightString = State(initialValue: String(format: "%.1f", displayVal))
            _microchipId = State(initialValue: dog.microchipId)
            _allergiesString = State(initialValue: dog.allergies.joined(separator: ", "))
            _selectedIcon = State(initialValue: dog.iconName)
            _selectedColorHex = State(initialValue: dog.avatarColorHex)
            _selectedPhotoData = State(initialValue: dog.photoData)
        } else {
            _weightUnit = State(initialValue: initialWeightUnit)
            let defaultVal = WeightUnit.convert(weightKg: 15.0, to: initialWeightUnit)
            _weightString = State(initialValue: String(format: "%.1f", defaultVal))
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Section: Avatar & Photo preview
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            DogAvatarView(
                                photoData: selectedPhotoData,
                                iconName: selectedIcon,
                                avatarColor: Color(hex: selectedColorHex) ?? DogTheme.primaryGreen,
                                size: 88
                            )
                            
                            // Photo picker button
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack(spacing: 6) {
                                    Image(systemName: selectedPhotoData == nil ? "camera.fill" : "arrow.triangle.2.circlepath.camera.fill")
                                    Text(selectedPhotoData == nil ? "Upload Photo" : "Change Photo")
                                }
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(DogTheme.softOrange)
                                .foregroundStyle(DogTheme.accentOrange)
                                .clipShape(Capsule())
                            }
                            
                            if selectedPhotoData != nil {
                                Button(role: .destructive) {
                                    selectedPhotoData = nil
                                    selectedPhotoItem = nil
                                } label: {
                                    Text("Remove Photo")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text(name.isEmpty ? "Dog Name" : name)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                            
                            if !breed.isEmpty {
                                Text(breed)
                                    .font(.subheadline)
                                    .foregroundStyle(DogTheme.textSecondary)
                            }
                        }
                        .padding(.vertical, 8)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                // Section: Basic Details
                Section("Basic Information") {
                    TextField("Dog's Name (e.g. Buster)", text: $name)
                        .autocorrectionDisabled()
                    
                    TextField("Breed (e.g. Golden Retriever)", text: $breed)
                    
                    DatePicker("Birth Date", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                    
                    // Gender selection with distinct male (blue) and female (salmon pink) styles
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender")
                            .font(.caption)
                            .foregroundStyle(DogTheme.textSecondary)
                        
                        HStack(spacing: 12) {
                            ForEach(DogGender.allCases) { g in
                                Button {
                                    gender = g
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: g.iconName)
                                            .font(.subheadline.weight(.bold))
                                        Text(g.rawValue)
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(gender == g ? g.backgroundColor : DogTheme.subtleGray.opacity(0.5))
                                    .foregroundStyle(gender == g ? g.tintColor : DogTheme.textSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(gender == g ? g.tintColor : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Weight with kg / lbs selection
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("Weight", text: $weightString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                        
                        Picker("Unit", selection: $weightUnit) {
                            ForEach(WeightUnit.allCases) { u in
                                Text(u.rawValue).tag(u)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 110)
                        .onChange(of: weightUnit) { oldUnit, newUnit in
                            if let val = Double(weightString.replacingOccurrences(of: ",", with: ".")) {
                                let kgVal = WeightUnit.toKg(weight: val, from: oldUnit)
                                let converted = WeightUnit.convert(weightKg: kgVal, to: newUnit)
                                weightString = String(format: "%.1f", converted)
                            }
                        }
                    }
                }
                
                // Section: Appearance Customization (for fallback icon or color)
                Section("Fallback Icon & Accent Color") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Choose Icon (used when no photo is uploaded)")
                            .font(.caption)
                            .foregroundStyle(DogTheme.textSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.title3)
                                            .frame(width: 44, height: 44)
                                            .background(selectedIcon == icon ? DogTheme.accentOrange.opacity(0.18) : DogTheme.subtleGray)
                                            .foregroundStyle(selectedIcon == icon ? DogTheme.accentOrange : .primary)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedIcon == icon ? DogTheme.accentOrange : Color.clear, lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Choose Theme Color")
                            .font(.caption)
                            .foregroundStyle(DogTheme.textSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(availableColors, id: \.hex) { item in
                                    Button {
                                        selectedColorHex = item.hex
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: item.hex) ?? .green)
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColorHex == item.hex ? 3 : 0)
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColorHex == item.hex ? Color.primary : Color.clear, lineWidth: selectedColorHex == item.hex ? 2 : 0)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Section: Starter Habits (Only for brand new dog)
                if !isEditing {
                    Section {
                        Toggle(isOn: $includeMorningWalk) {
                            Label("Morning Walk & Exercise", systemImage: "figure.walk")
                                .foregroundStyle(DogTheme.primaryGreen)
                        }
                        Toggle(isOn: $includeNutrition) {
                            Label("Fresh Water & Meal", systemImage: "fork.knife")
                                .foregroundStyle(DogTheme.primaryBlue)
                        }
                        Toggle(isOn: $includePottyWater) {
                            Label("Potty & Water (3x a day)", systemImage: "drop.fill")
                                .foregroundStyle(DogTheme.primaryBlue)
                        }
                        Toggle(isOn: $includeEveningWalk) {
                            Label("Evening Walk & Playtime", systemImage: "figure.walk.motion")
                                .foregroundStyle(DogTheme.primaryGreen)
                        }
                        Toggle(isOn: $includeTeethBrushing) {
                            Label("Teeth Brushing / Dental Chew", systemImage: "sparkles")
                                .foregroundStyle(DogTheme.accentOrange)
                        }
                        Toggle(isOn: $includeSupplements) {
                            Label("Daily Vitamin / Supplement", systemImage: "pills.fill")
                                .foregroundStyle(DogTheme.primaryBlue)
                        }
                    } header: {
                        Text("Starter Daily Habits")
                    } footer: {
                        Text("You can easily add, edit, or remove habits anytime.")
                    }
                }
                
                // Section: Medical Info
                Section("Health & Identification") {
                    TextField("Microchip Number (optional)", text: $microchipId)
                        .autocorrectionDisabled()
                    
                    TextField("Known Allergies (comma separated)", text: $allergiesString)
                }
            }
            .navigationTitle(isEditing ? "Edit Dog" : "Add New Dog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add Dog") {
                        saveDog()
                    }
                    .font(.headline)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : DogTheme.accentOrange)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data),
                           let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                            await MainActor.run {
                                selectedPhotoData = jpegData
                            }
                        } else {
                            await MainActor.run {
                                selectedPhotoData = data
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveDog() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let enteredWeight = Double(weightString.replacingOccurrences(of: ",", with: ".")) ?? 10.0
        let weightKg = WeightUnit.toKg(weight: enteredWeight, from: weightUnit)
        
        let allergies = allergiesString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var starterHabits: [DailyHabit] = []
        if !isEditing {
            if includeMorningWalk {
                starterHabits.append(DailyHabit(title: "Morning Walk", category: .walk, targetFrequency: "Once Daily"))
            }
            if includeNutrition {
                starterHabits.append(DailyHabit(title: "Fresh Meal & Water", category: .nutrition, targetFrequency: "Once Daily"))
            }
            if includePottyWater {
                starterHabits.append(DailyHabit(title: "Potty & Fresh Water", category: .nutrition, targetFrequency: "3x a Day", notes: "Check 3 times daily"))
            }
            if includeEveningWalk {
                starterHabits.append(DailyHabit(title: "Evening Walk & Fetch", category: .walk, targetFrequency: "Once Daily"))
            }
            if includeTeethBrushing {
                starterHabits.append(DailyHabit(title: "Teeth Cleaning / Chew", category: .hygiene, targetFrequency: "Once Daily"))
            }
            if includeSupplements {
                starterHabits.append(DailyHabit(title: "Daily Vitamins", category: .medication, targetFrequency: "Once Daily"))
            }
        }
        
        var dog = dogToEdit ?? Dog(
            name: trimmedName,
            breed: breed.isEmpty ? "Mixed Breed" : breed,
            birthDate: birthDate,
            gender: gender,
            weightKg: weightKg,
            iconName: selectedIcon,
            avatarColorHex: selectedColorHex,
            photoData: selectedPhotoData,
            microchipId: microchipId,
            allergies: allergies,
            dailyHabits: starterHabits,
            weightLogs: [WeightLog(date: Date(), weight: weightKg, notes: "Initial registered weight")],
            vetVisits: [],
            medications: []
        )
        
        if isEditing {
            dog.name = trimmedName
            dog.breed = breed.isEmpty ? "Mixed Breed" : breed
            dog.birthDate = birthDate
            dog.gender = gender
            dog.weightKg = weightKg
            dog.iconName = selectedIcon
            dog.avatarColorHex = selectedColorHex
            dog.photoData = selectedPhotoData
            dog.microchipId = microchipId
            dog.allergies = allergies
        }
        
        onSave(dog)
        dismiss()
    }
}

#Preview {
    AddDogView { _ in }
}
