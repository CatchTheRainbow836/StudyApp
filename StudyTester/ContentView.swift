import SwiftUI

struct ContentView: View {
    @Binding var returnURL: URL?
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Study Interruption Active")
                .font(.title)
                .bold()

            if let target = returnURL {
                Text("Target return app: \(target.absoluteString)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("No return URL provided. Open via deep link to test auto-return.")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: {
                if let target = returnURL {
                    openURL(target)
                }
            }) {
                Text("OK")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(returnURL != nil ? Color.blue : Color.gray)
                    .cornerRadius(14)
            }
            .disabled(returnURL == nil)
            .padding(.horizontal, 40)
        }
        .padding()
    }
}