import SwiftUI
import UIKit

struct ZoomableImageView: View {
    let imagePath: String?
    var maxHeight: CGFloat = 160

    var body: some View {
        Group {
            if let path = imagePath, let uiImage = UIImage(contentsOfFile: path) {
                ZoomableScrollView(image: uiImage, maxHeight: maxHeight)
                    .frame(height: maxHeight)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            } else {
                Text("Image Unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
        }
    }
}

struct ZoomableScrollView: UIViewRepresentable {
    let image: UIImage
    let maxHeight: CGFloat

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .clear

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tag = 999
        scrollView.addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        guard let imageView = uiView.viewWithTag(999) as? UIImageView else { return }
        imageView.image = image

        let aspect = image.size.width / max(image.size.height, 1)
        let calculatedWidth = maxHeight * aspect
        let screenWidth = UIScreen.main.bounds.width - 32
        let contentWidth = max(calculatedWidth, screenWidth)

        imageView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: maxHeight)
        uiView.contentSize = CGSize(width: contentWidth, height: maxHeight)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(999)
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            if scrollView.zoomScale > 1.0 {
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                let point = gesture.location(in: scrollView)
                let rect = CGRect(x: point.x - 40, y: point.y - 40, width: 80, height: 80)
                scrollView.zoom(to: rect, animated: true)
            }
        }
    }
}