import SwiftUI

@main
struct StudyTesterApp: App {
    @State private var returnURL: URL? = nil

    var body: some Scene {
        WindowGroup {
            ContentView(returnURL: $returnURL)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return }

        if let target = queryItems.first(where: { $0.name == "return_url" })?.value,
           let decodedString = target.removingPercentEncoding,
           let validURL = URL(string: decodedString) {
            self.returnURL = validURL
        }
    }
}