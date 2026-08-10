import Foundation

struct RawQuestion: Codable {
    let number: Int
    let choices: [String: ChoiceData]
    let images: [String]
    let area_of_study: String
    let contexts: [ContextData]?
    let answer: String
}

struct ChoiceData: Codable {
    let images: [String]
}

struct ContextData: Codable {
    let questions: [Int]
    let text: String?
    let image: String?
}

struct Question: Identifiable, Codable {
    let id: String
    let setFolderName: String
    let number: Int
    let choices: [String: [String]]
    let questionImages: [String]
    let areaOfStudy: String
    let contextText: String?
    let contextImage: String?
    let correctAnswer: String
}

struct SingleAttempt: Codable, Identifiable {
    var id: UUID = UUID()
    let questionId: String
    let setFolderName: String
    let questionNumber: Int
    let areaOfStudy: String
    let selectedChoice: String
    let correctAnswer: String
    let isCorrect: Bool
    let timestamp: Date
}

struct AppSettings: Codable {
    var autoTargetCount: Int = 5
    var enabledAreas: Set<String> = []
    var areaBiases: [String: Double] = [:]
}