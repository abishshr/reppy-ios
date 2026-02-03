import PhotosUI
import SwiftUI

// Wrapper that accepts external ViewModel
struct ChatViewWrapper: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        ChatViewContent(viewModel: viewModel)
    }
}

// Standalone version that creates its own ViewModel
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        ChatViewContent(viewModel: viewModel)
    }
}

// MARK: - Main Chat Content

struct ChatViewContent: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var inputText = ""
    @State private var showingCamera = false
    @State private var cameraMode: CameraMode = .food
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var isTextFieldFocused: Bool
    @State private var isReady = false
    @State private var hasHandledCameraCapture = false  // Prevent double capture handling

    enum CameraMode {
        case food
        case menu
        case workoutBoard      // Log a workout from whiteboard
        case workoutSchedule   // Create a workout plan from class schedule
    }

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if isReady {
                    VStack(spacing: 0) {
                        // Quick actions (when no messages)
                        if viewModel.messages.isEmpty {
                            modernQuickActions
                        }

                        // Messages
                        messagesView

                        // Image preview
                        if viewModel.selectedImage != nil {
                            imagePreview
                        }

                        // Input bar
                        modernInputBar
                    }
                }
            }
            .navigationTitle("Reppy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        impactLight.impactOccurred()
                        viewModel.startNewSession()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 17, weight: .medium))
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPickerView(selectedImage: $viewModel.selectedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: viewModel.selectedImage) { _, newImage in
                // When camera returns with image, auto-send appropriate message
                // Only handle for gallery photos (showingCamera is false)
                // Camera photos are handled by the showingCamera onChange
                if newImage != nil && showingCamera == false && !hasHandledCameraCapture {
                    hasHandledCameraCapture = true
                    handleCameraCapture()
                    // Reset flag after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        hasHandledCameraCapture = false
                    }
                }
            }
            .onChange(of: showingCamera) { _, isShowing in
                // Only handle when camera dismisses with an image
                if !isShowing && viewModel.selectedImage != nil && !hasHandledCameraCapture {
                    hasHandledCameraCapture = true
                    handleCameraCapture()
                    // Reset flag after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        hasHandledCameraCapture = false
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadPhoto(from: newItem)
            }
            .task {
                impactLight.prepare()
                impactMedium.prepare()
                try? await Task.sleep(nanoseconds: 50_000_000)
                withAnimation(.easeOut(duration: 0.15)) {
                    isReady = true
                }
            }
        }
    }

    // MARK: - Modern Quick Actions (Empty State)

    private var modernQuickActions: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)

                        Image(systemName: "figure.run")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("Hey! How can I help?")
                        .font(.title2.bold())

                    Text("Tap an action or describe what you need")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Scan Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("SCAN")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ScanActionCard(
                            icon: "camera.fill",
                            title: "Snap Food",
                            subtitle: "AI identifies your meal",
                            gradient: [.orange, .red]
                        ) {
                            cameraMode = .food
                            showingCamera = true
                        }

                        ScanActionCard(
                            icon: "menucard.fill",
                            title: "Scan Menu",
                            subtitle: "Get healthy picks",
                            gradient: [.pink, .purple]
                        ) {
                            cameraMode = .menu
                            showingCamera = true
                        }

                        ScanActionCard(
                            icon: "square.text.square.fill",
                            title: "Log Workout",
                            subtitle: "CrossFit WOD board",
                            gradient: [.blue, .cyan]
                        ) {
                            cameraMode = .workoutBoard
                            showingCamera = true
                        }

                        ScanActionCard(
                            icon: "calendar.badge.plus",
                            title: "Class Schedule",
                            subtitle: "Create plan from photo",
                            gradient: [.indigo, .purple]
                        ) {
                            cameraMode = .workoutSchedule
                            showingCamera = true
                        }

                        ScanActionCard(
                            icon: "barcode.viewfinder",
                            title: "Barcode",
                            subtitle: "Packaged foods",
                            gradient: [.green, .mint]
                        ) {
                            inputText = "I want to scan a barcode"
                            sendMessage()
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Quick Actions Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("QUICK ACTIONS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 10) {
                        QuickActionRow(
                            icon: "fork.knife",
                            title: "Log a Meal",
                            subtitle: "Tell me what you ate",
                            color: .orange
                        ) {
                            inputText = "I want to log a meal"
                            sendMessage()
                        }

                        QuickActionRow(
                            icon: "dumbbell.fill",
                            title: "Log Workout",
                            subtitle: "Record your exercise",
                            color: .blue
                        ) {
                            inputText = "I want to log a workout"
                            sendMessage()
                        }

                        QuickActionRow(
                            icon: "figure.strengthtraining.traditional",
                            title: "Today's Workout",
                            subtitle: "What should I do today?",
                            color: .purple
                        ) {
                            inputText = "What workout should I do today?"
                            sendMessage()
                        }

                        QuickActionRow(
                            icon: "leaf.fill",
                            title: "Meal Suggestion",
                            subtitle: "Based on my macros",
                            color: .green
                        ) {
                            inputText = "Suggest a meal based on my remaining macros"
                            sendMessage()
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Explore Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("EXPLORE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ExploreChip(icon: "chart.line.uptrend.xyaxis", text: "My Progress", color: .cyan) {
                                inputText = "How am I doing with my fitness goals?"
                                sendMessage()
                            }

                            ExploreChip(icon: "calendar", text: "Create Meal Plan", color: .green) {
                                inputText = "Create a meal plan for this week"
                                sendMessage()
                            }

                            ExploreChip(icon: "calendar.badge.plus", text: "Create Workout Plan", color: .purple) {
                                inputText = "Create a workout plan for me"
                                sendMessage()
                            }

                            ExploreChip(icon: "questionmark.circle", text: "Nutrition Tips", color: .orange) {
                                inputText = "Give me some nutrition tips"
                                sendMessage()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // Try These Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("TRY SAYING")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 8) {
                        SuggestionRow(text: "What's my workout for today?", icon: "figure.run") {
                            inputText = "What's my workout for today?"
                            sendMessage()
                        }

                        SuggestionRow(text: "What should I eat for dinner?", icon: "fork.knife") {
                            inputText = "What should I eat for dinner based on my remaining macros?"
                            sendMessage()
                        }

                        SuggestionRow(text: "How many calories have I eaten?", icon: "flame.fill") {
                            inputText = "How many calories have I eaten today?"
                            sendMessage()
                        }

                        SuggestionRow(text: "Create a CrossFit workout", icon: "figure.cross.training") {
                            inputText = "Create a CrossFit style workout for me"
                            sendMessage()
                        }

                        SuggestionRow(text: "High protein meal ideas", icon: "leaf.fill") {
                            inputText = "Give me some high protein meal ideas"
                            sendMessage()
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 100)
            }
        }
    }

    // MARK: - Messages View

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.messages) { message in
                        ChatBubble(
                            message: message,
                            onConfirm: { type, id in
                                impactMedium.impactOccurred()
                                Task {
                                    await viewModel.confirmSuggestion(type: type, suggestionId: id)
                                }
                            },
                            onApprovePlan: { plan in
                                impactMedium.impactOccurred()
                                Task {
                                    await viewModel.approvePlan(plan)
                                }
                            }
                        )
                        .id(message.id)
                    }

                    if viewModel.isLoading {
                        EnhancedTypingIndicator(message: viewModel.loadingMessage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }

                    Color.clear.frame(height: 8)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isLoading) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.25)) {
                if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Image Preview

    private var imagePreview: some View {
        HStack(spacing: 12) {
            if let image = viewModel.selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        impactLight.impactOccurred()
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.selectedImage = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .offset(x: 6, y: -6)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Photo ready")
                    .font(.subheadline.weight(.medium))
                Text(cameraModeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var cameraModeDescription: String {
        switch cameraMode {
        case .food: return "AI will identify your food"
        case .menu: return "AI will suggest healthy options"
        case .workoutBoard: return "AI will parse & log the workout"
        case .workoutSchedule: return "AI will create a workout plan"
        }
    }

    // MARK: - Modern Input Bar

    private var modernInputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 10) {
                // Camera button
                Menu {
                    Button {
                        cameraMode = .food
                        showingCamera = true
                    } label: {
                        Label("Snap Food", systemImage: "camera.fill")
                    }

                    Button {
                        cameraMode = .menu
                        showingCamera = true
                    } label: {
                        Label("Scan Menu", systemImage: "menucard.fill")
                    }

                    Button {
                        cameraMode = .workoutBoard
                        showingCamera = true
                    } label: {
                        Label("Log Workout (WOD)", systemImage: "square.text.square.fill")
                    }

                    Button {
                        cameraMode = .workoutSchedule
                        showingCamera = true
                    } label: {
                        Label("Create Plan from Schedule", systemImage: "calendar.badge.plus")
                    }

                    Divider()

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Photo Library", systemImage: "photo.fill")
                    }
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                }

                // Text input
                HStack(spacing: 8) {
                    TextField("Message Reppy...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...5)
                        .focused($isTextFieldFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            if canSend { sendMessage() }
                        }

                    // Voice button
                    Button {
                        impactLight.impactOccurred()
                        Task { await viewModel.toggleRecording() }
                    } label: {
                        ZStack {
                            if viewModel.isRecording {
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                    .scaleEffect(viewModel.isRecording ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.isRecording)
                            }

                            Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(viewModel.isRecording ? .red : .secondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.secondarySystemBackground))
                )

                // Send button
                Button {
                    impactMedium.impactOccurred()
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(
                                    canSend
                                        ? LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color(.tertiaryLabel)], startPoint: .top, endPoint: .bottom)
                                )
                        )
                }
                .disabled(!canSend)
                .scaleEffect(canSend ? 1.0 : 0.9)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: canSend)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Helpers

    private var canSend: Bool {
        (!inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.selectedImage != nil) && !viewModel.isLoading
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || viewModel.selectedImage != nil else { return }
        let hasImage = viewModel.selectedImage != nil
        inputText = ""
        isTextFieldFocused = false

        Task {
            await viewModel.sendMessage(text, withImage: hasImage)
        }
    }

    private func handleCameraCapture() {
        // Auto-send message based on camera mode
        switch cameraMode {
        case .food:
            inputText = "What food is this? Log it for me"
        case .menu:
            inputText = "This is a restaurant menu. What are the healthiest options that fit my goals?"
        case .workoutBoard:
            inputText = "This is a workout board (like CrossFit WOD). Parse this workout and log it for me"
        case .workoutSchedule:
            inputText = "This is a workout schedule from my gym/CrossFit class. Create a workout plan based on this schedule. Include all the exercises, sets, and reps shown."
        }
        sendMessage()
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    cameraMode = .food // Default for photo library
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.selectedImage = image
                    }
                    impactMedium.impactOccurred()
                }
            }
            selectedPhotoItem = nil
        }
    }
}

// MARK: - Scan Action Card

struct ScanActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(gradient[0].opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring(response: 0.2)) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring(response: 0.25)) { isPressed = false } }
        )
    }
}

// MARK: - Quick Action Row

struct QuickActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(color)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Explore Chip

struct ExploreChip: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)

                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Suggestion Row (Try Saying)

struct SuggestionRow: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 24)

                Text("\"\(text)\"")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .italic()

                Spacer()

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Enhanced Typing Indicator with Message

struct EnhancedTypingIndicator: View {
    let message: String?
    @State private var animationPhase = 0.0
    @State private var dotCount = 0

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Reppy avatar
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 38, height: 38)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "figure.run")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                // Name tag
                HStack(spacing: 6) {
                    Text("Reppy")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                }

                // Loading message or typing dots
                if let message = message {
                    HStack(spacing: 4) {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Animated dots
                        Text(String(repeating: ".", count: dotCount))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                    }
                } else {
                    // Bouncing dots
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 10, height: 10)
                                .offset(y: bounceOffset(for: index))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .padding(.horizontal, 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: false)) {
                animationPhase = 1.0
            }
            // Animate dots
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dotCount = (dotCount % 3) + 1
            }
        }
    }

    private func bounceOffset(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.15
        let phase = (animationPhase + delay).truncatingRemainder(dividingBy: 1.0)
        if phase < 0.5 {
            return -6 * sin(phase * .pi * 2)
        } else {
            return 0
        }
    }
}

// MARK: - Modern Typing Indicator

struct ModernTypingIndicator: View {
    @State private var animationPhase = 0.0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 10, height: 10)
                    .offset(y: bounceOffset(for: index))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: false)) {
                animationPhase = 1.0
            }
        }
    }

    private func bounceOffset(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.15
        let phase = (animationPhase + delay).truncatingRemainder(dividingBy: 1.0)
        if phase < 0.5 {
            return -6 * sin(phase * .pi * 2)
        } else {
            return 0
        }
    }
}

// MARK: - Quick Chip (Legacy support)

struct QuickChip: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)

                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Typing Indicator (Legacy)

struct TypingIndicator: View {
    var body: some View {
        ModernTypingIndicator()
    }
}

#Preview("Chat View") {
    ChatView()
}
