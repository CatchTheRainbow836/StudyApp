import SwiftUI
import PencilKit

struct CanvasData: Identifiable {
    let id = UUID()
    let questionId: String
    let title: String
    let contextText: String?
    let contextImagePath: String?
    let questionImagePaths: [String]
}

struct CanvasView: View {
    let data: CanvasData
    let initialDrawing: PKDrawing
    var onSaveDrawing: ((PKDrawing) -> Void)? = nil

    @Environment(\.dismiss) var dismiss

    @State private var canvasView = PKCanvasView()
    @State private var isHideWriting = false
    @State private var allowsFingerDrawing = true
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            CanvasContainerRepresentable(
                canvasView: $canvasView,
                data: data,
                initialDrawing: initialDrawing,
                isHideWriting: isHideWriting,
                allowsFingerDrawing: allowsFingerDrawing,
                onSaveDrawing: onSaveDrawing
            )
            .ignoresSafeArea()

            VStack {
                HStack(spacing: 12) {
                    Button(action: {
                        onSaveDrawing?(canvasView.drawing)
                        dismiss()
                    }) {
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
                            showDeleteConfirmation = true
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
        .alert("Clear Scratchpad?", isPresented: $showDeleteConfirmation) {
            Button("Clear All", role: .destructive) {
                canvasView.drawing = PKDrawing()
                onSaveDrawing?(PKDrawing())
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete all writing on this scratchpad? This action cannot be undone.")
        }
        .onDisappear {
            onSaveDrawing?(canvasView.drawing)
        }
    }
}

struct CanvasContainerRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let data: CanvasData
    let initialDrawing: PKDrawing
    let isHideWriting: Bool
    let allowsFingerDrawing: Bool
    var onSaveDrawing: ((PKDrawing) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasWidth: CGFloat = 3600
        let canvasHeight: CGFloat = 3600

        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
        let dotPattern = createDotGridPatternImage()
        containerView.backgroundColor = UIColor(patternImage: dotPattern)
        containerView.isUserInteractionEnabled = false

        let cardView = createCardContent(width: 800)
        cardView.center = CGPoint(x: canvasWidth / 2, y: canvasHeight / 2)
        containerView.addSubview(cardView)

        canvasView.frame = CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = allowsFingerDrawing ? .anyInput : .pencilOnly
        canvasView.overrideUserInterfaceStyle = .light

        if canvasView.drawing.strokes.isEmpty && !initialDrawing.strokes.isEmpty {
            canvasView.drawing = initialDrawing
        }

        canvasView.addSubview(containerView)
        canvasView.sendSubviewToBack(containerView)

        canvasView.contentSize = CGSize(width: canvasWidth, height: canvasHeight)
        canvasView.minimumZoomScale = 0.3
        canvasView.maximumZoomScale = 3.0
        canvasView.zoomScale = 1.0
        canvasView.delegate = context.coordinator
        canvasView.showsHorizontalScrollIndicator = false
        canvasView.showsVerticalScrollIndicator = false
        canvasView.bouncesZoom = true

        let screenBounds = UIScreen.main.bounds
        let initialX = (canvasWidth - screenBounds.width) / 2
        let initialY = (canvasHeight - screenBounds.height) / 2
        canvasView.contentOffset = CGPoint(x: max(0, initialX), y: max(0, initialY))

        context.coordinator.setupToolPicker(for: canvasView)

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawingPolicy = allowsFingerDrawing ? .anyInput : .pencilOnly
        uiView.alpha = isHideWriting ? 0.0 : 1.0
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

    class Coordinator: NSObject, UIScrollViewDelegate, PKToolPickerObserver, PKCanvasViewDelegate {
        var parent: CanvasContainerRepresentable
        var toolPicker: PKToolPicker?
        private var lastOffsetY: CGFloat = 0

        init(_ parent: CanvasContainerRepresentable) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let currentOffsetY = scrollView.contentOffset.y
            let diff = currentOffsetY - lastOffsetY

            if abs(diff) > 12 {
                if diff > 0 {
                    if toolPicker?.isVisible == true {
                        toolPicker?.setVisible(false, forFirstResponder: parent.canvasView)
                    }
                } else {
                    if toolPicker?.isVisible == false {
                        toolPicker?.setVisible(true, forFirstResponder: parent.canvasView)
                    }
                }
                lastOffsetY = currentOffsetY
            }
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onSaveDrawing?(canvasView.drawing)
        }

        func setupToolPicker(for canvasView: PKCanvasView) {
            if #available(iOS 14.0, *) {
                let picker = PKToolPicker()
                self.toolPicker = picker

                let defaultRedPen = PKInkingTool(.pen, color: .red, width: 3.0)
                picker.selectedTool = defaultRedPen
                canvasView.tool = defaultRedPen

                canvasView.delegate = self
                picker.addObserver(canvasView)
                picker.addObserver(self)
                picker.setVisible(true, forFirstResponder: canvasView)
                canvasView.becomeFirstResponder()
            }
        }
    }
}