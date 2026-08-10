import SwiftUI

struct ManualDashboardView: View {
    @EnvironmentObject var qManager: QuestionManager
    @State private var activeSheet: SheetType? = nil

    enum SheetType: Identifiable {
        case quiz, stats, exportData, settings
        var id: Int { hashValue }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 28) {
                VStack(spacing: 16) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 110))
                        .foregroundColor(.blue)
                    Text("StudyApp")
                        .font(.system(size: 40, weight: .bold))
                }
                .padding(.top, 24)

                VStack(spacing: 18) {
                    DashboardButton(title: "Answer Questions", icon: "play.circle.fill", color: .blue) {
                        activeSheet = .quiz
                    }
                    DashboardButton(title: "Statistics", icon: "chart.bar.fill", color: .purple) {
                        activeSheet = .stats
                    }
                    DashboardButton(title: "Export Data", icon: "square.and.arrow.up.fill", color: .green) {
                        activeSheet = .exportData
                    }
                    DashboardButton(title: "Settings", icon: "gearshape.fill", color: .gray) {
                        activeSheet = .settings
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $activeSheet) { item in
                switch item {
                case .quiz:
                    QuizView(isAutoMode: false, returnURL: nil, onAutoComplete: {})
                case .stats:
                    StatisticsView()
                case .exportData:
                    ExportDataView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct DashboardButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                Text(title)
                    .font(.title2.bold())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .opacity(0.6)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .frame(height: 112)
            .background(color)
            .cornerRadius(20)
        }
    }
}

struct StatisticsView: View {
    @EnvironmentObject var qManager: QuestionManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Overall Summary")) {
                    HStack {
                        Text("Questions Attempted")
                        Spacer()
                        Text("\(totalQuestionsAttempted)")
                            .bold()
                    }
                    HStack {
                        Text("Total Choices Submitted")
                        Spacer()
                        Text("\(totalChoiceAttempts)")
                            .bold()
                    }
                    HStack {
                        Text("Total Correct Answers")
                        Spacer()
                        Text("\(totalCorrectAnswers)")
                            .bold()
                            .foregroundColor(.green)
                    }
                }

                Section(header: Text("Per Area of Study")) {
                    ForEach(qManager.availableAreas, id: \.self) { area in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(area).font(.headline)
                            HStack {
                                Text("Questions Tracked: \(areaQuestionsCount(area))")
                                Spacer()
                                Text("Correct: \(areaCorrectCount(area))")
                                    .foregroundColor(.green)
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var totalQuestionsAttempted: Int { qManager.records.count }
    
    private var totalChoiceAttempts: Int {
        qManager.records.reduce(0) { $0 + $1.selectedChoices.count }
    }

    private var totalCorrectAnswers: Int {
        qManager.records.reduce(0) { count, rec in
            count + rec.selectedChoices.filter { $0 == rec.correctAnswer }.count
        }
    }

    private func areaQuestionsCount(_ area: String) -> Int {
        qManager.records.filter { $0.areaOfStudy == area }.count
    }

    private func areaCorrectCount(_ area: String) -> Int {
        qManager.records.filter { $0.areaOfStudy == area }.reduce(0) { count, rec in
            count + rec.selectedChoices.filter { $0 == rec.correctAnswer }.count
        }
    }
}

struct ExportDataView: View {
    @EnvironmentObject var qManager: QuestionManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Raw Question Records JSON")
                    .font(.headline)

                ScrollView {
                    Text(qManager.exportDataJSON())
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }

                ShareLink(item: qManager.exportDataJSON()) {
                    Label("Export JSON File", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct SettingsView: View {
    @EnvironmentObject var qManager: QuestionManager
    @Environment(\.dismiss) var dismiss
    @State private var showClearConfirmation: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $qManager.settings.isDarkMode)
                }

                Section(header: Text("Auto-Trigger Settings")) {
                    Stepper("Questions Required: \(qManager.settings.autoTargetCount)", value: $qManager.settings.autoTargetCount, in: 1...20)
                }

                Section(header: Text("Area of Study Lock")) {
                    ForEach(qManager.availableAreas, id: \.self) { area in
                        Toggle(area, isOn: Binding(
                            get: { qManager.settings.enabledAreas.contains(area) },
                            set: { isEnabled in
                                if isEnabled { qManager.settings.enabledAreas.insert(area) }
                                else { qManager.settings.enabledAreas.remove(area) }
                            }
                        ))
                    }
                }

                Section(header: Text("Area Biases (Probability Weighting)")) {
                    ForEach(qManager.availableAreas, id: \.self) { area in
                        VStack(alignment: .leading) {
                            Text("\(area): \(String(format: "%.1f", qManager.settings.areaBiases[area] ?? 1.0))x")
                            Slider(
                                value: Binding(
                                    get: { qManager.settings.areaBiases[area] ?? 1.0 },
                                    set: { qManager.settings.areaBiases[area] = $0 }
                                ),
                                in: 0.5...2.0, step: 0.1
                            )
                        }
                    }
                }

                Section(header: Text("Manage Data & Defaults")) {
                    Button(action: {
                        qManager.resetSettingsToDefault()
                    }) {
                        Text("Reset to Default Settings")
                            .foregroundColor(.blue)
                    }

                    Button(action: {
                        showClearConfirmation = true
                    }) {
                        Text("Clear Saved Data")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        qManager.saveSettings()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showClearConfirmation) {
                ClearDataSheet()
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct ClearDataSheet: View {
    @EnvironmentObject var qManager: QuestionManager
    @Environment(\.dismiss) var dismiss
    @State private var inputWord: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)

                Text("Clear All Saved Data?")
                    .font(.title2.bold())

                Text("This action cannot be undone. All recorded question history will be permanently deleted.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Type **clear** to confirm:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Type 'clear'", text: $inputWord)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal)

                Button(action: {
                    qManager.clearAllSavedData()
                    dismiss()
                }) {
                    Text("Permanently Delete Data")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isClearEnabled ? Color.red : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isClearEnabled)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Confirm Wipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var isClearEnabled: Bool {
        inputWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "clear"
    }
}