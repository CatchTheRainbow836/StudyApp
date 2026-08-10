import SwiftUI

struct ContentView: View {
    @Binding var returnURL: URL?
    @EnvironmentObject var qManager: QuestionManager
    @State private var isInvalidDeepLink: Bool = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            Group {
                if isInvalidDeepLink {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("Invalid Deep Link")
                            .font(.title2.bold())
                        Text("No target app was specified. Opening manual mode.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Continue") {
                            isInvalidDeepLink = false
                            returnURL = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 10)
                        Spacer()
                    }
                    .padding()
                } else if let validReturn = returnURL {
                    QuizView(
                        isAutoMode: true,
                        returnURL: validReturn,
                        onAutoComplete: {
                            self.returnURL = nil
                        }
                    )
                } else {
                    ManualDashboardView()
                }
            }
        }
        .onChange(of: returnURL) { newValue in
            validateDeepLink(newValue)
        }
        .onAppear {
            validateDeepLink(returnURL)
        }
    }

    private func validateDeepLink(_ url: URL?) {
        guard let url = url else {
            isInvalidDeepLink = false
            return
        }

        let absolute = url.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let scheme = url.scheme?.lowercased(), !scheme.isEmpty else {
            isInvalidDeepLink = true
            return
        }

        if absolute == "://" || absolute.isEmpty {
            isInvalidDeepLink = true
        } else {
            isInvalidDeepLink = false
        }
    }
}