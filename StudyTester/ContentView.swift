import SwiftUI

struct ContentView: View {
    @Binding var returnURL: URL?
    @EnvironmentObject var qManager: QuestionManager
    @State private var isInvalidDeepLink: Bool = false

    var body: some View {
        Group {
            if isInvalidDeepLink {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    Text("Invalid Deep Link")
                        .font(.title2.bold())
                    Text("No target app was specified. Opening manual mode.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Continue") {
                        isInvalidDeepLink = false
                        returnURL = nil
                    }
                    .buttonStyle(.borderedProminent)
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
        .onChange(of: returnURL) { _ in
            validateDeepLink(returnURL)
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

        let scheme = url.scheme?.lowercased() ?? ""
        let absolute = url.absoluteString

        if absolute.contains("://") && (scheme.isEmpty || absolute == "://" || absolute.hasSuffix("://")) {
            isInvalidDeepLink = true
        } else {
            isInvalidDeepLink = false
        }
    }
}