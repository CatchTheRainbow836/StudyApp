import SwiftUI

struct ZoomableImageView: View {
    let imagePath: String?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        Group {
            if let path = imagePath, let uiImage = UIImage(contentsOfFile: path) {
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { val in
                                    let delta = val / lastScale
                                    lastScale = val
                                    scale = min(max(scale * delta, 1.0), 4.0)
                                }
                                .onEnded { _ in lastScale = 1.0 }
                        )
                }
                .frame(maxHeight: 350)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            } else {
                Text("Image Unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}