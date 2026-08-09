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
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    Text("StudyTester")
                        .font(.largeTitle.bold())
                }
                .padding(.top, 24)

                VStack(spacing: 14) {
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
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .opacity(0.6)
            }
            .foregroundColor(.white)
            .padding()
            .frame(height: 56)
            .background(color)
            .cornerRadius(14)
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
                        Text("Total Answered")
                        Spacer()
                        Text("\(totalAnswered)")
                            .bold()
                    }
                    HStack {
                        Text("Total Correct")
                        Spacer()
                        Text("\(totalCorrect)")
                            .bold()
                            .foregroundColor(.green)
                    }
                }

                Section(header: Text("Per Area of Study")) {
                    ForEach(qManager.availableAreas, id: \.self) { area in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(area).font(.headline)
                            HStack {
                                Text("Answered: \(areaAnswered(area))")
                                Spacer()
                                Text("Correct: \(areaCorrect(area))")
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

    private var totalAnswered: Int { 
        qManager.attempts.values.reduce(0) { $0 + $1.totalAttempts } 
    }
    
    private var totalCorrect: Int { 
        qManager.attempts.values.reduce(0) { $0 + $1.correctAttempts } 
    }

    private func areaAnswered(_ area: String) -> Int {
        let qIds = Set(qManager.questions.filter { $0.areaOfStudy == area }.map { $0.id })
        return qManager.attempts.values
            .filter { qIds.contains($0.questionId) }
            .reduce(0) { $0 + $1.totalAttempts }
    }

    private func areaCorrect(_ area: String) -> Int {
        let qIds = Set(qManager.questions.filter { $0.areaOfStudy == area }.map { $0.id })
        return qManager.attempts.values
            .filter { qIds.contains($0.questionId) }
            .reduce(0) { $0 + $1.correctAttempts }
    }
}

struct ExportDataView: View {
    @EnvironmentObject var qManager: QuestionManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Raw JSON Attempt Logs")
                    .font(.headline)

                ScrollView {
                    Text(qManager.exportDataJSON())
                        .font(.system(.caption, design: .monospaced))
                        .padding()
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

    var body: some View {
        NavigationView {
            Form {
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
        }
        .navigationViewStyle(.stack)
    }
}