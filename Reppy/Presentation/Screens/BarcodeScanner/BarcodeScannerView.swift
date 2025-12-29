import SwiftUI
@preconcurrency import AVFoundation

/// Barcode scanner view for scanning food product barcodes
struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BarcodeScannerViewModel

    let onFoodFound: (CustomFood) -> Void
    let onCreateFood: (String) -> Void // Called with barcode when food not found

    @State private var showFoodDetail = false

    init(
        foodRepository: FoodRepository,
        onFoodFound: @escaping (CustomFood) -> Void,
        onCreateFood: @escaping (String) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: BarcodeScannerViewModel(foodRepository: foodRepository))
        self.onFoodFound = onFoodFound
        self.onCreateFood = onCreateFood
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview
                BarcodeCameraPreview(session: viewModel.captureSession)
                    .ignoresSafeArea()

                // Scanning overlay
                VStack {
                    Spacer()

                    // Scanning frame
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.isScanning ? Color.green : Color.white, lineWidth: 3)
                        .frame(width: 280, height: 150)
                        .overlay {
                            if viewModel.isScanning {
                                // Scanning animation
                                Rectangle()
                                    .fill(Color.green.opacity(0.3))
                                    .frame(height: 2)
                                    .offset(y: viewModel.scanLineOffset)
                            }
                        }

                    Text(viewModel.statusMessage)
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.top, 16)
                        .shadow(radius: 2)

                    Spacer()

                    // Manual entry button
                    Button {
                        viewModel.stopScanning()
                        dismiss()
                    } label: {
                        Text("Enter Manually")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }

                // Loading overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.stopScanning()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.toggleFlash()
                    } label: {
                        Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .onChange(of: viewModel.foundFood) { _, food in
            if food != nil {
                showFoodDetail = true
            }
        }
        .sheet(isPresented: $showFoodDetail) {
            if let food = viewModel.foundFood {
                ScannedFoodDetailSheet(
                    food: food,
                    onAdd: {
                        onFoodFound(food)
                        dismiss()
                    },
                    onCancel: {
                        viewModel.resumeScanning()
                    }
                )
            }
        }
        .alert("Food Not Found", isPresented: $viewModel.showNotFoundAlert) {
            Button("Create Food") {
                if let barcode = viewModel.lastScannedBarcode {
                    onCreateFood(barcode)
                    dismiss()
                }
            }
            Button("Scan Again") {
                viewModel.resumeScanning()
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("This barcode wasn't found in our database. Would you like to create a custom food entry?")
        }
        .alert("Camera Access Required", isPresented: $viewModel.showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Please allow camera access in Settings to scan barcodes.")
        }
    }
}

// MARK: - Scanned Food Detail Sheet

struct ScannedFoodDetailSheet: View {
    let food: CustomFood
    let onAdd: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Health Rating Card
                    FoodHealthRatingCard(food: food)
                        .padding(.horizontal)

                    // Ingredients list (if available)
                    if let ingredients = food.ingredients, !ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "list.bullet.rectangle")
                                    .foregroundColor(.blue)
                                Text("Ingredients")
                                    .font(.headline)
                            }

                            Text(ingredients)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Add button
                    Button(action: onAdd) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to Food Log")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(addButtonColor)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)

                    // Warning banner for bad foods
                    if let rating = food.healthRating, rating == .poor || rating == .bad {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)

                            Text("This product contains ingredients that may not align with your health goals.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Scanned Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Scan Again") {
                        dismiss()
                        onCancel()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                        onCancel()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var addButtonColor: Color {
        guard let rating = food.healthRating else { return .blue }
        switch rating {
        case .excellent, .good: return .green
        case .okay: return .blue
        case .poor: return .orange
        case .bad: return .red
        }
    }
}

// MARK: - ViewModel

@MainActor
final class BarcodeScannerViewModel: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var isLoading = false
    @Published var isFlashOn = false
    @Published var statusMessage = "Position barcode in the frame"
    @Published var scanLineOffset: CGFloat = -60
    @Published var foundFood: CustomFood?
    @Published var showNotFoundAlert = false
    @Published var showPermissionAlert = false
    @Published var lastScannedBarcode: String?

    let captureSession = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private let foodRepository: FoodRepository
    private var scanTimer: Timer?
    private var lastProcessedBarcode: String?
    private var processingBarcode = false

    init(foodRepository: FoodRepository) {
        self.foodRepository = foodRepository
        super.init()
        setupCaptureSession()
    }

    private func setupCaptureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [
                .ean8,
                .ean13,
                .upce,
                .code128,
                .code39,
                .code93,
                .itf14
            ]
        }
    }

    func startScanning() {
        checkCameraPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                Task { @MainActor in
                    self.isScanning = true
                    self.startScanAnimation()
                    await self.startSession()
                }
            } else {
                self.showPermissionAlert = true
            }
        }
    }

    private func startSession() async {
        let session = captureSession
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
                continuation.resume()
            }
        }
    }

    func stopScanning() {
        isScanning = false
        scanTimer?.invalidate()
        let session = captureSession
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }

    func resumeScanning() {
        lastProcessedBarcode = nil
        processingBarcode = false
        statusMessage = "Position barcode in the frame"
        startScanning()
    }

    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            isFlashOn.toggle()
            device.torchMode = isFlashOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Flash toggle failed: \(error)")
        }
    }

    private func startScanAnimation() {
        scanTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                withAnimation(.linear(duration: 0.02)) {
                    self.scanLineOffset += 2
                    if self.scanLineOffset > 60 {
                        self.scanLineOffset = -60
                    }
                }
            }
        }
    }

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }

    func processBarcode(_ barcode: String) {
        guard !processingBarcode, barcode != lastProcessedBarcode else { return }

        processingBarcode = true
        lastProcessedBarcode = barcode
        lastScannedBarcode = barcode
        statusMessage = "Looking up barcode..."
        isLoading = true

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        Task {
            do {
                let response = try await foodRepository.lookupBarcode(barcode)
                await MainActor.run {
                    self.isLoading = false
                    if response.found, let food = response.food {
                        self.foundFood = food
                        self.statusMessage = "Found: \(food.name)"
                        // Success haptic
                        let successGenerator = UINotificationFeedbackGenerator()
                        successGenerator.notificationOccurred(.success)
                    } else {
                        self.showNotFoundAlert = true
                        self.statusMessage = "Food not found"
                    }
                    self.processingBarcode = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.statusMessage = "Error: \(error.localizedDescription)"
                    self.processingBarcode = false
                    // Allow retry after error
                    self.lastProcessedBarcode = nil
                }
            }
        }
    }
}

extension BarcodeScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcode = metadataObject.stringValue else {
            return
        }

        Task { @MainActor in
            self.processBarcode(barcode)
        }
    }
}

// MARK: - Camera Preview

struct BarcodeCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

#Preview {
    // Mock repository for preview
    BarcodeScannerView(
        foodRepository: MockFoodRepository(),
        onFoodFound: { _ in },
        onCreateFood: { _ in }
    )
}

// Mock for preview
private class MockFoodRepository: FoodRepository {
    func searchFoods(query: String, limit: Int) async throws -> [CustomFood] { [] }
    func lookupBarcode(_ barcode: String) async throws -> BarcodeLookupResponse {
        BarcodeLookupResponse(found: false, food: nil, barcode: barcode)
    }
    func getRecentFoods(limit: Int) async throws -> [CustomFood] { [] }
    func getFrequentFoods(limit: Int) async throws -> [CustomFood] { [] }
    func getMyFoods() async throws -> [CustomFood] { [] }
    func createFood(_ food: CustomFoodCreate) async throws -> CustomFood {
        CustomFood(id: "", name: "", brand: nil, servingSize: nil, servingSizeG: nil,
                   calories: nil, proteinG: nil, carbsG: nil, fatG: nil, fiberG: nil,
                   sugarG: nil, barcode: nil, source: "", isVerified: false,
                   imageUrl: nil, createdAt: Date(), ingredients: nil, ingredientAnalysis: nil)
    }
    func deleteFood(id: String) async throws {}
    func recordFoodUsage(foodId: String) async throws {}
}
