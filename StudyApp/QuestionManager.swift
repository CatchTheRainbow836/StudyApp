import Foundation

class QuestionManager: ObservableObject {
    @Published var questions: [Question] = []
    @Published var records: [QuestionRecord] = []
    @Published var settings: AppSettings = AppSettings()
    @Published var availableAreas: [String] = []

    private let recordsKey = "study_app_records_v3"
    private let settingsKey = "study_app_settings_v2"

    init() {
        loadUserData()
        loadBundledQuestions()
    }

    func loadBundledQuestions() {
        var loadedQuestions: [Question] = []
        var detectedAreas: Set<String> = []

        let fileManager = FileManager.default
        guard let resourcePath = Bundle.main.resourcePath else { return }

        let enumerator = fileManager.enumerator(atPath: resourcePath)
        while let relativePath = enumerator?.nextObject() as? String {
            if relativePath.hasSuffix(".json") {
                let fullPath = (resourcePath as NSString).appendingPathComponent(relativePath)
                let url = URL(fileURLWithPath: fullPath)
                let folderName = url.deletingLastPathComponent().lastPathComponent

                if let data = try? Data(contentsOf: url),
                   let rawQuestions = try? JSONDecoder().decode([RawQuestion].self, from: data) {
                    
                    for raw in rawQuestions {
                        let uniqueId = "\(folderName)_q\(raw.number)"
                        
                        var choiceMap: [String: [String]] = [:]
                        for (key, choiceVal) in raw.choices {
                            choiceMap[key] = choiceVal.images
                        }

                        var ctxText: String? = nil
                        var ctxImage: String? = nil
                        if let firstCtx = raw.contexts?.first {
                            ctxText = firstCtx.text
                            ctxImage = firstCtx.image
                        }

                        let q = Question(
                            id: uniqueId,
                            setFolderName: folderName,
                            number: raw.number,
                            choices: choiceMap,
                            questionImages: raw.images,
                            areaOfStudy: raw.area_of_study,
                            contextText: ctxText,
                            contextImage: ctxImage,
                            correctAnswer: raw.answer
                        )

                        loadedQuestions.append(q)
                        detectedAreas.insert(q.areaOfStudy)
                    }
                }
            }
        }

        self.questions = loadedQuestions
        self.availableAreas = Array(detectedAreas).sorted()

        if settings.enabledAreas.isEmpty || settings.enabledAreas.isDisjoint(with: detectedAreas) {
            settings.enabledAreas = detectedAreas
            for area in detectedAreas {
                if settings.areaBiases[area] == nil {
                    settings.areaBiases[area] = 1.0
                }
            }
            saveSettings()
        }
    }

    func selectNextQuestion(excluding currentId: String? = nil) -> Question? {
        let activePool = questions.filter { settings.enabledAreas.contains($0.areaOfStudy) && $0.id != currentId }
        guard !activePool.isEmpty else { return nil }

        let recordsByQ = Dictionary(uniqueKeysWithValues: records.map { ($0.questionId, $0) })

        let unanswered = activePool.filter { recordsByQ[$0.id] == nil || (recordsByQ[$0.id]?.selectedChoices.isEmpty ?? true) }
        if let chosen = unanswered.randomElement() { return chosen }

        let unmastered = activePool.filter { q in
            guard let rec = recordsByQ[q.id], let lastChoice = rec.selectedChoices.last else { return true }
            return lastChoice != q.correctAnswer
        }
        if let chosen = unmastered.randomElement() { return chosen }

        var areaWeights: [String: Double] = [:]
        for area in settings.enabledAreas {
            let areaQuestions = activePool.filter { $0.areaOfStudy == area }
            guard !areaQuestions.isEmpty else { continue }

            let areaRecords = records.filter { rec in areaQuestions.contains(where: { $0.id == rec.questionId }) }
            let totalAttempts = areaRecords.reduce(0) { $0 + $1.selectedChoices.count }
            let totalCorrect = areaRecords.reduce(0) { count, rec in
                count + rec.selectedChoices.filter { $0 == rec.correctAnswer }.count
            }

            let accuracy = totalAttempts > 0 ? Double(totalCorrect) / Double(totalAttempts) : 0.5
            let inverseAccuracyWeight = 1.0 - accuracy + 0.1
            let userBias = settings.areaBiases[area] ?? 1.0

            areaWeights[area] = inverseAccuracyWeight * userBias
        }

        let totalWeight = areaWeights.values.reduce(0, +)
        if totalWeight > 0 {
            var randomPoint = Double.random(in: 0..<totalWeight)
            for (area, weight) in areaWeights {
                if randomPoint < weight {
                    let candidates = activePool.filter { $0.areaOfStudy == area }
                    if let chosen = candidates.randomElement() { return chosen }
                }
                randomPoint -= weight
            }
        }

        return activePool.randomElement()
    }

    func recordAttempt(question: Question, selectedChoice: String) {
        if let index = records.firstIndex(where: { $0.questionId == question.id }) {
            records[index].selectedChoices.append(selectedChoice)
            records[index].timestamps.append(Date())
        } else {
            let newRecord = QuestionRecord(
                questionId: question.id,
                setFolderName: question.setFolderName,
                questionNumber: question.number,
                areaOfStudy: question.areaOfStudy,
                correctAnswer: question.correctAnswer,
                selectedChoices: [selectedChoice],
                timestamps: [Date()]
            )
            records.append(newRecord)
        }
        saveUserData()
    }

    func imagePath(for filename: String, folderName: String) -> String? {
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        
        if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: folderName) {
            return path
        }
        if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: "Questions/\(folderName)") {
            return path
        }
        if let path = Bundle.main.path(forResource: name, ofType: ext) {
            return path
        }
        return nil
    }

    private func loadUserData() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([QuestionRecord].self, from: data) {
            self.records = decoded
        } else {
            self.records = []
        }

        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        }
    }

    private func saveUserData() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }

    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }

    func resetSettingsToDefault() {
        self.settings = AppSettings()
        let detectedAreas = Set(availableAreas)
        self.settings.enabledAreas = detectedAreas
        for area in detectedAreas {
            self.settings.areaBiases[area] = 1.0
        }
        saveSettings()
    }

    func clearAllSavedData() {
        self.records = []
        UserDefaults.standard.removeObject(forKey: recordsKey)
    }

    func exportDataJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let encoded = try? encoder.encode(records),
              let jsonStr = String(data: encoded, encoding: .utf8) else {
            return "[]"
        }
        return jsonStr
    }
}