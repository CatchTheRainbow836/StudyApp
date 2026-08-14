import SwiftUI
import PencilKit

struct CanvasData: Identifiable {
    let id = UUID()
    let title: String
    let contextText: String?
    let contextImagePath: String?
    let questionImagePaths: [String]
}

struct CanvasView: View {
    let data: CanvasData
    @Environment(\.dismiss) var dismiss

    @State private var canvasView = PKCanvasView()
    @State private var isHideWriting = false
    @State private var allowsFingerDrawing = true

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            CanvasContainerRepresentable(
                canvasView: $canvasView,
                data: data,
                isHideWriting: isHideWriting,
                allowsFingerDrawing: allowsFingerDrawing
            )
            .ignoresSafeArea(.all, edges: .bottom)

            VStack {
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                            Text("Back")
                                .font(.headline)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                    }

                    Spacer()

                    Text(data.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)

                    Spacer()

                    HStack(spacing: 12) {
                        Button(action: {
                            canvasView.undoManager?.undo()
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 16, weight: .semibold))
                        }

                        Button(action: {
                            canvasView.undoManager?.redo()
                        }) {
                            Image(systemName: "arrow.uturn.forward")
                                .font(.system(size: 16, weight: .semibold))
                        }

                        Divider()
                            .frame(height: 16)

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isHideWriting.toggle()
                            }
                        }) {
                            Image(systemName: isHideWriting ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isHideWriting ? .orange : .blue)
                        }

                        Button(action: {
                            allowsFingerDrawing.toggle()
                        }) {
                            Image(systemName: allowsFingerDrawing ? "hand.draw.fill" : "hand.raised.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(allowsFingerDrawing ? .blue : .gray)
                        }

                        Button(action: {
                            canvasView.drawing = PKDrawing()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

struct CanvasContainerRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let data: CanvasData
    let isHideWriting: Bool
    let allowsFingerDrawing: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 0.3
        scrollView.maximumZoomScale = 3.0
        scrollView.zoomScale = 1.0
        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = UIColor.systemGroupedBackground

        let canvasWidth: CGFloat = 3600
        let canvasHeight: CGFloat = 3600

        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))

        let dotPattern = createDotGridPatternImage()
        contentView.backgroundColor = UIColor(patternImage: dotPattern)

        let cardView = createCardContent(width: 800)
        cardView.center = CGPoint(x: canvasWidth / 2, y: canvasHeight / 2)
        contentView.addSubview(cardView)

        canvasView.frame = CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = allowsFingerDrawing ? .anyInput : .pencilOnly
        canvasView.overrideUserInterfaceStyle = .light

        contentView.addSubview(canvasView)
        scrollView.addSubview(contentView)
        scrollView.contentSize = CGSize(width: canvasWidth, height: canvasHeight)

        let screenBounds = UIScreen.main.bounds
        let initialX = (canvasWidth - screenBounds.width) / 2
        let initialY = (canvasHeight - screenBounds.height) / 2
        scrollView.contentOffset = CGPoint(x: max(0, initialX), y: max(0, initialY))

        context.coordinator.setupToolPicker(for: canvasView)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        canvasView.drawingPolicy = allowsFingerDrawing ? .anyInput : .pencilOnly
        canvasView.alpha = isHideWriting ? 0.0 : 1.0
    }

    private func createDotGridPatternImage(gridSize: CGFloat = 24, dotRadius: CGFloat = 1.8) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: gridSize, height: gridSize))
        return renderer.image { ctx in
            UIColor.systemBackground.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: gridSize, height: gridSize))

            UIColor.systemGray3.setFill()
            let dotRect = CGRect(
                x: gridSize/2 - dotRadius,
                y: gridSize/2 - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )
            ctx.cgContext.addEllipse(in: dotRect)
            ctx.cgContext.fillPath()
        }
    }

    private func createCardContent(width: CGFloat) -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill

        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 16
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.12
        container.layer.shadowRadius = 12
        container.layer.shadowOffset = CGSize(width: 0, height: 4)

        if let text = data.contextText, !text.isEmpty {
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 16, weight: .regular)
            label.textColor = .label
            label.numberOfLines = 0

            let textPadding = UIView()
            textPadding.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
            textPadding.layer.cornerRadius = 8

            label.translatesAutoresizingMaskIntoConstraints = false
            textPadding.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: textPadding.topAnchor, constant: 12),
                label.bottomAnchor.constraint(equalTo: textPadding.bottomAnchor, constant: -12),
                label.leadingAnchor.constraint(equalTo: textPadding.leadingAnchor, constant: 12),
                label.trailingAnchor.constraint(equalTo: textPadding.trailingAnchor, constant: -12)
            ])

            stackView.addArrangedSubview(textPadding)
        }

        if let ctxPath = data.contextImagePath, let img = UIImage(contentsOfFile: ctxPath) {
            let iv = UIImageView(image: img)
            iv.contentMode = .scaleAspectFit
            iv.clipsToBounds = true
            let aspect = img.size.height / max(img.size.width, 1)
            iv.heightAnchor.constraint(equalTo: iv.widthAnchor, multiplier: aspect).isActive = true
            stackView.addArrangedSubview(iv)
        }

        for imgPath in data.questionImagePaths {
            if let img = UIImage(contentsOfFile: imgPath) {
                let iv = UIImageView(image: img)
                iv.contentMode = .scaleAspectFit
                iv.clipsToBounds = true
                let aspect = img.size.height / max(img.size.width, 1)
                iv.heightAnchor.constraint(equalTo: iv.widthAnchor, multiplier: aspect).isActive = true
                stackView.addArrangedSubview(iv)
            }
        }

        stackView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            container.widthAnchor.constraint(equalToConstant: width)
        ])

        container.layoutIfNeeded()
        let targetSize = container.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        container.frame = CGRect(x: 0, y: 0, width: width, height: targetSize.height)

        return container
    }

    class Coordinator: NSObject, UIScrollViewDelegate, PKToolPickerObserver {
        var parent: CanvasContainerRepresentable
        var toolPicker: PKToolPicker?

        init(_ parent: CanvasContainerRepresentable) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }

        func setupToolPicker(for canvasView: PKCanvasView) {
            if #available(iOS 14.0, *) {
                let picker = PKToolPicker()
                self.toolPicker = picker
                picker.addObserver(canvasView)
                picker.addObserver(self)
                picker.setVisible(true, forFirstResponder: canvasView)
                canvasView.becomeFirstResponder()
            }
        }
    }
}