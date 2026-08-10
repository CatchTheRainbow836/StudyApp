import SwiftUI

struct QuizView: View {
    @EnvironmentObject var qManager: QuestionManager
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss

    let isAutoMode: Bool
    let returnURL: URL?
    let onAutoComplete: () -> Void

    @State private var currentQuestion: Question?
    @State private var selectedChoice: String?
    @State private var isAnswerSubmitted: Bool = false
    @State private var isCorrect: Bool = false

    @State private var autoCorrectCount: Int = 0
    @State private var flashColor: Color? = nil
    @State private var overlaySymbol: String? = nil
    @State private var overlayColor: Color = .green

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if let flash = flashColor {
                flash.opacity(0.18).ignoresSafeArea().transition(.opacity)
            }

            VStack(spacing: 0) {
                HStack {
                    if !isAutoMode {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                        }
                    }

                    Spacer()

                    if isAutoMode {
                        Text("Progress: \(autoCorrectCount) / \(qManager.settings.autoTargetCount)")
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(8)
                    } else {
                        Text("Practice Mode")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

                if let q = currentQuestion {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            if let ctxText = q.contextText {
                                Text(ctxText)
                                    .font(.subheadline)
                                    .padding()
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            if let ctxImg = q.contextImage {
                                ZoomableImageView(imagePath: qManager.imagePath(for: ctxImg, folderName: q.setFolderName), maxHeight: 180)
                            }

                            ForEach(q.questionImages, id: \.self) { imgName in
                                ZoomableImageView(imagePath: qManager.imagePath(for: imgName, folderName: q.setFolderName), maxHeight: 180)
                            }

                            VStack(spacing: 12) {
                                ForEach(sortedChoiceKeys(q.choices), id: \.self) { key in
                                    ChoiceRow(
                                        key: key,
                                        images: q.choices[key] ?? [],
                                        folderName: q.setFolderName,
                                        isSelected: selectedChoice == key,
                                        isSubmitted: isAnswerSubmitted,
                                        isCorrectChoice: key == q.correctAnswer,
                                        action: {
                                            if !isAnswerSubmitted { selectedChoice = key }
                                        }
                                    )
                                }
                            }

                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal)
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

                    VStack {
                        if !isAnswerSubmitted {
                            Button(action: submitAnswer) {
                                Text("Submit Answer")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(selectedChoice != nil ? Color.blue : Color.gray)
                                    .cornerRadius(12)
                            }
                            .disabled(selectedChoice == nil)
                        } else {
                            Button(action: advanceQuestion) {
                                Text("Next Question")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No questions available for the selected areas.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("Exit Practice") { dismiss() }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .padding(.top, 40)
                    Spacer()
                }
            }

            if let symbol = overlaySymbol {
                Image(systemName: symbol)
                    .font(.system(size: 100))
                    .foregroundColor(overlayColor)
                    .scaleEffect(1.2)
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear { loadNextQuestion() }
    }

    private func sortedChoiceKeys(_ choices: [String: [String]]) -> [String] {
        return choices.keys.sorted()
    }

    private func loadNextQuestion() {
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedChoice = nil
            isAnswerSubmitted = false
            currentQuestion = qManager.selectNextQuestion(excluding: currentQuestion?.id)
        }
    }

    private func submitAnswer() {
        guard let q = currentQuestion, let choice = selectedChoice else { return }

        let correct = (choice == q.correctAnswer)
        isCorrect = correct
        isAnswerSubmitted = true

        qManager.recordAttempt(question: q, selectedChoice: choice, isCorrect: correct)

        withAnimation(.easeInOut(duration: 0.2)) {
            flashColor = correct ? .green : .red
            overlaySymbol = correct ? "checkmark.circle.fill" : "xmark.circle.fill"
            overlayColor = correct ? .green : .red
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                flashColor = nil
                overlaySymbol = nil
            }
        }

        if correct {
            autoCorrectCount += 1
            if isAutoMode && autoCorrectCount >= qManager.settings.autoTargetCount {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    executeDeepLinkReturn()
                }
            }
        }
    }

    private func advanceQuestion() {
        loadNextQuestion()
    }

    private func executeDeepLinkReturn() {
        guard let target = returnURL else { return }
        onAutoComplete()
        openURL(target)
    }
}

struct ChoiceRow: View {
    @EnvironmentObject var qManager: QuestionManager
    let key: String
    let images: [String]
    let folderName: String
    let isSelected: Bool
    let isSubmitted: Bool
    let isCorrectChoice: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(key)
                    .font(.title3.bold())
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)

                VStack {
                    ForEach(images, id: \.self) { img in
                        ZoomableImageView(imagePath: qManager.imagePath(for: img, folderName: folderName), maxHeight: 120)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var backgroundColor: Color {
        if isSubmitted {
            if isCorrectChoice { return Color.green.opacity(0.2) }
            if isSelected && !isCorrectChoice { return Color.red.opacity(0.2) }
        } else if isSelected {
            return Color.blue.opacity(0.1)
        }
        return Color(.secondarySystemGroupedBackground)
    }

    private var borderColor: Color {
        if isSubmitted {
            if isCorrectChoice { return .green }
            if isSelected && !isCorrectChoice { return .red }
        } else if isSelected {
            return .blue
        }
        return .clear
    }
}