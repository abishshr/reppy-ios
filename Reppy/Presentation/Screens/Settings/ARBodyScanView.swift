import SwiftUI
import AVFoundation
import ARKit
import RealityKit

// MARK: - User-Friendly AR Body Scan View

struct ARBodyScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ARBodyScanViewModel()

    var body: some View {
        ZStack {
            // Camera background
            Color.black.ignoresSafeArea()

            // Camera/AR feed based on device capability
            if viewModel.isCameraReady {
                if viewModel.deviceCapability == .bodyTrackingSupported,
                   let arSession = viewModel.arSession {
                    ARBodyScanPreview(session: arSession)
                        .ignoresSafeArea()
                } else {
                    CameraScanPreview(session: viewModel.captureSession)
                        .ignoresSafeArea()
                }
            }

            // Skeleton overlay (shows body detection)
            if let pose = viewModel.detectedPose, viewModel.showSkeleton {
                SkeletonOverlayView(pose: pose)
            }

            // Main content based on mode
            Group {
                switch viewModel.currentMode {
                case .tutorial:
                    TutorialOverlay(onStart: viewModel.startScanning)

                case .detecting:
                    DetectingOverlay()

                case .tooClose:
                    DistanceWarningOverlay(message: "Step back a bit", icon: "arrow.backward")

                case .tooFar:
                    DistanceWarningOverlay(message: "Step closer", icon: "arrow.forward")

                case .positioningFront:
                    PositioningOverlay(
                        title: "Face the camera",
                        subtitle: "Stand with arms slightly away from body",
                        silhouetteRotation: 0,
                        isReady: viewModel.isBodyAligned
                    )

                case .countdown(let count):
                    ScanCountdownOverlay(count: count)

                case .capturingFront, .capturingSide:
                    CapturingOverlay()

                case .turningSide:
                    TurnInstructionOverlay()

                case .positioningSide:
                    PositioningOverlay(
                        title: "Show your side",
                        subtitle: "Turn 90° to face left or right",
                        silhouetteRotation: 90,
                        isReady: viewModel.isBodyAligned
                    )

                case .processing:
                    ProcessingOverlay()

                case .complete:
                    if let measurements = viewModel.finalMeasurements {
                        CompletionOverlay(
                            measurements: measurements,
                            onSave: { saveMeasurements(measurements) },
                            onRetake: viewModel.reset
                        )
                    }

                case .error(let message):
                    ScanErrorOverlay(message: message, onRetry: viewModel.reset)
                }
            }

            // Top bar (always visible except in tutorial)
            if viewModel.currentMode != .tutorial {
                VStack {
                    TopScanBar(
                        step: viewModel.currentStep,
                        totalSteps: 2,
                        capability: viewModel.deviceCapability,
                        onClose: { dismiss() }
                    )
                    Spacer()
                }
            }

            // Capture button (when ready)
            if viewModel.showCaptureButton {
                VStack {
                    Spacer()
                    CaptureButton(
                        isReady: viewModel.isBodyAligned,
                        onTap: viewModel.capture
                    )
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            viewModel.userHeightCm = appState.userProfile?.heightCm ?? 170
            viewModel.userSex = appState.userProfile?.sex ?? .male
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: viewModel.currentMode) { _, newMode in
            // Haptic feedback on mode changes
            provideHapticFeedback(for: newMode)
        }
    }

    private func saveMeasurements(_ measurements: ScanMeasurements) {
        Task {
            let create = BodyMeasurementCreate(
                neckCm: measurements.neckCm,
                shouldersCm: measurements.shouldersCm,
                chestCm: measurements.chestCm,
                waistCm: measurements.waistCm,
                hipsCm: measurements.hipsCm,
                bodyFatPercentage: nil, // Backend will calculate
                notes: "AR Scan (confidence: \(Int(measurements.confidence * 100))%)"
            )

            do {
                _ = try await DependencyContainer.shared.apiClient.createMeasurement(create)
                dismiss()
            } catch {
                viewModel.currentMode = .error("Failed to save. Please try again.")
            }
        }
    }

    private func provideHapticFeedback(for mode: ARBodyScanViewModel.ScanMode) {
        let generator = UINotificationFeedbackGenerator()

        switch mode {
        case .countdown:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .complete:
            generator.notificationOccurred(.success)
        case .error:
            generator.notificationOccurred(.error)
        case .positioningFront, .positioningSide:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        default:
            break
        }
    }
}

// MARK: - Tutorial Overlay

struct TutorialOverlay: View {
    let onStart: () -> Void
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Animated illustration
                TutorialAnimation(page: currentPage)
                    .frame(height: 250)

                // Title and description
                VStack(spacing: 12) {
                    Text(tutorialTitles[currentPage])
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(tutorialDescriptions[currentPage])
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        if currentPage < 2 {
                            withAnimation { currentPage += 1 }
                        } else {
                            onStart()
                        }
                    }) {
                        Text(currentPage < 2 ? "Next" : "Start Scanning")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    if currentPage < 2 {
                        Button("Skip Tutorial") {
                            onStart()
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private var tutorialTitles: [String] {
        ["Prop Your Phone", "Stand Back", "Two Quick Photos"]
    }

    private var tutorialDescriptions: [String] {
        [
            "Place your phone on a stable surface at waist height, with the back camera facing you.",
            "Stand 6-8 feet away (about 2-3 arm lengths) so your whole body is visible.",
            "We'll guide you through a front photo and a side photo. Just follow the on-screen instructions!"
        ]
    }
}

struct TutorialAnimation: View {
    let page: Int

    var body: some View {
        ZStack {
            switch page {
            case 0:
                // Phone on surface
                VStack {
                    Image(systemName: "iphone.rear.camera")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 120, height: 4)
                        .offset(y: 10)
                    Text("📱 → 👤")
                        .font(.title)
                        .padding(.top, 20)
                }
            case 1:
                // Distance indicator
                HStack(spacing: 40) {
                    Image(systemName: "iphone")
                        .font(.system(size: 40))
                        .foregroundColor(.white)

                    VStack(spacing: 4) {
                        Text("6-8 ft")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: 80, height: 2)
                    }

                    Image(systemName: "figure.stand")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
            case 2:
                // Two photos
                HStack(spacing: 24) {
                    VStack {
                        Image(systemName: "figure.stand")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        Text("Front")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundColor(.yellow)

                    VStack {
                        Image(systemName: "figure.stand")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .rotation3DEffect(.degrees(90), axis: (x: 0, y: 1, z: 0))
                        Text("Side")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Detecting Overlay

struct DetectingOverlay: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            // Scanning animation
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)

                Image(systemName: "person.fill.viewfinder")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }

            Text("Looking for you...")
                .font(.headline)
                .foregroundColor(.white)

            Text("Make sure your whole body is visible")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - Distance Warning Overlay

struct DistanceWarningOverlay: View {
    let message: String
    let icon: String
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .offset(x: isAnimating ? 10 : -10)
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: isAnimating)

            Text(message)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(40)
        .background(Color.black.opacity(0.7))
        .cornerRadius(20)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Positioning Overlay

struct PositioningOverlay: View {
    let title: String
    let subtitle: String
    let silhouetteRotation: Double
    let isReady: Bool

    var body: some View {
        VStack {
            Spacer()

            // Silhouette guide
            ZStack {
                // Dashed outline
                Image(systemName: "figure.stand")
                    .font(.system(size: 200))
                    .foregroundColor(isReady ? .green.opacity(0.5) : .white.opacity(0.2))
                    .rotationEffect(.degrees(silhouetteRotation))

                // Measurement lines
                if silhouetteRotation == 0 {
                    VStack(spacing: 50) {
                        DashedLine(color: isReady ? .green : .yellow)
                        DashedLine(color: isReady ? .green : .yellow)
                        DashedLine(color: isReady ? .green : .yellow)
                    }
                }
            }

            Spacer()

            // Instructions
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: isReady ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isReady ? .green : .yellow)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(12)
            .padding(.bottom, 120)
        }
    }
}

struct DashedLine: View {
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { _ in
                Rectangle()
                    .fill(color)
                    .frame(width: 8, height: 2)
            }
        }
    }
}

// MARK: - Scan Countdown Overlay

struct ScanCountdownOverlay: View {
    let count: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 150, height: 150)

            Text("\(count)")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(.white)
        }
        .transition(.scale)
    }
}

// MARK: - Capturing Overlay

struct CapturingOverlay: View {
    @State private var flash = false

    var body: some View {
        ZStack {
            if flash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.1)) {
                flash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    flash = false
                }
            }
        }
    }
}

// MARK: - Turn Instruction Overlay

struct TurnInstructionOverlay: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            // Animated turning figure
            Image(systemName: "figure.stand")
                .font(.system(size: 100))
                .foregroundColor(.white)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))

            Text("Turn to your side")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("90°")
                Image(systemName: "arrow.clockwise")
            }
            .font(.headline)
            .foregroundColor(.yellow)
        }
        .padding(40)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                rotation = 90
            }
        }
    }
}

// MARK: - Processing Overlay

struct ProcessingOverlay: View {
    @State private var progress: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated processing indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "ruler")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }

                Text("Calculating measurements...")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("This only takes a few seconds")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2)) {
                progress = 1
            }
        }
    }
}

// MARK: - Completion Overlay

struct CompletionOverlay: View {
    let measurements: ScanMeasurements
    let onSave: () -> Void
    let onRetake: () -> Void
    @State private var showCheckmark = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()

            VStack(spacing: 24) {
                // Success animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(showCheckmark ? 1 : 0)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .scaleEffect(showCheckmark ? 1 : 0)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCheckmark)

                Text("Measurements Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Measurements card
                VStack(spacing: 16) {
                    MeasurementResultItem(label: "Neck", value: measurements.neckCm)
                    MeasurementResultItem(label: "Shoulders", value: measurements.shouldersCm)
                    MeasurementResultItem(label: "Chest", value: measurements.chestCm)
                    MeasurementResultItem(label: "Waist", value: measurements.waistCm)
                    MeasurementResultItem(label: "Hips", value: measurements.hipsCm)
                }
                .padding(20)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)

                // Confidence badge
                HStack {
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 8, height: 8)
                    Text("\(Int(measurements.confidence * 100))% confidence")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                // Actions
                HStack(spacing: 16) {
                    Button(action: onRetake) {
                        Label("Retake", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }

                    Button(action: onSave) {
                        Label("Save", systemImage: "checkmark")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showCheckmark = true
            }
        }
    }

    private var confidenceColor: Color {
        if measurements.confidence > 0.8 { return .green }
        if measurements.confidence > 0.6 { return .yellow }
        return .orange
    }
}

struct MeasurementResultItem: View {
    let label: String
    let value: Double

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text("\(Int(value)) cm")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Scan Error Overlay

struct ScanErrorOverlay: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                Text("Something went wrong")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(message)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: onRetry) {
                    Label("Try Again", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Top Bar

struct TopScanBar: View {
    let step: Int
    let totalSteps: Int
    let capability: ARBodyScanViewModel.DeviceCapability
    let onClose: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }

            Spacer()

            // Step indicator
            HStack(spacing: 8) {
                ForEach(1...totalSteps, id: \.self) { s in
                    Circle()
                        .fill(s <= step ? Color.green : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.5))
            .cornerRadius(20)

            Spacer()

            // Capability badge
            Text(capability.shortName)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(capability.color.opacity(0.8))
                .cornerRadius(8)
        }
        .padding()
    }
}

// MARK: - Capture Button

struct CaptureButton: View {
    let isReady: Bool
    let onTap: () -> Void
    @State private var isPressing = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(isReady ? Color.green : Color.white.opacity(0.5), lineWidth: 4)
                    .frame(width: 80, height: 80)

                // Inner circle
                Circle()
                    .fill(isReady ? Color.white : Color.white.opacity(0.5))
                    .frame(width: 65, height: 65)
                    .scaleEffect(isPressing ? 0.9 : 1)

                // Ready indicator
                if isReady {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.black)
                        .font(.title2)
                }
            }
        }
        .disabled(!isReady)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressing = pressing
            }
        }, perform: {})
    }
}

// MARK: - Skeleton Overlay

struct SkeletonOverlayView: View {
    let pose: ARBodyScanViewModel.DetectedPose

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw connections
                ForEach(pose.connections, id: \.0) { connection in
                    if let start = pose.joints[connection.0],
                       let end = pose.joints[connection.1] {
                        Path { path in
                            path.move(to: CGPoint(
                                x: start.x * geometry.size.width,
                                y: start.y * geometry.size.height
                            ))
                            path.addLine(to: CGPoint(
                                x: end.x * geometry.size.width,
                                y: end.y * geometry.size.height
                            ))
                        }
                        .stroke(Color.green, lineWidth: 2)
                    }
                }

                // Draw joints
                ForEach(Array(pose.joints.keys), id: \.self) { key in
                    if let point = pose.joints[key] {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .position(
                                x: point.x * geometry.size.width,
                                y: point.y * geometry.size.height
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Camera Preview (Vision fallback)

struct CameraScanPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - AR Body Scan Preview (ARKit body tracking)

struct ARBodyScanPreview: UIViewRepresentable {
    let session: ARSession

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session = session
        arView.automaticallyConfigureSession = false
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Session is managed by the ViewModel
    }
}

// MARK: - Preview

#Preview {
    ARBodyScanView()
        .environmentObject(AppState())
}
