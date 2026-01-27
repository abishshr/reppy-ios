import SwiftUI
import AVKit

/// A SwiftUI video player that auto-plays, loops, and can fall back to GIF display.
struct VideoPlayerView: View {
    let videoUrl: String?
    let gifUrl: String?
    let aspectRatio: CGFloat

    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var hasError = false
    @State private var isMuted = true
    @State private var playerLooper: AVPlayerLooper?

    init(videoUrl: String?, gifUrl: String? = nil, aspectRatio: CGFloat = 16/9) {
        self.videoUrl = videoUrl
        self.gifUrl = gifUrl
        self.aspectRatio = aspectRatio
    }

    var body: some View {
        ZStack {
            if let videoUrl = videoUrl, let url = URL(string: videoUrl), !hasError {
                // Video player
                VideoPlayer(player: player)
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .onAppear {
                        setupPlayer(url: url)
                    }
                    .onDisappear {
                        cleanupPlayer()
                    }
                    .overlay(alignment: .bottomTrailing) {
                        // Mute/unmute button
                        Button {
                            isMuted.toggle()
                            player?.isMuted = isMuted
                        } label: {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(8)
                    }
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                    }
            } else if let gifUrl = gifUrl {
                // Fallback to async GIF image
                AsyncImage(url: URL(string: gifUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(aspectRatio, contentMode: .fit)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .background(Color.black.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray5))
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }

    private func setupPlayer(url: URL) {
        let playerItem = AVPlayerItem(url: url)

        // Use AVQueuePlayer with looper for seamless looping
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

        queuePlayer.isMuted = isMuted
        queuePlayer.play()

        // Track loading state
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                switch status {
                case .readyToPlay:
                    isLoading = false
                case .failed:
                    hasError = true
                    isLoading = false
                default:
                    break
                }
            }
            .store(in: &cancellables)

        self.player = queuePlayer
    }

    private func cleanupPlayer() {
        player?.pause()
        player = nil
        playerLooper = nil
    }

    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Combine Support

import Combine

// MARK: - Compact Exercise Media View

/// A compact media view for exercise cards - shows video or GIF with minimal chrome
struct ExerciseMediaView: View {
    let exercise: PlannedExercise
    let height: CGFloat

    var body: some View {
        if exercise.hasVideo, let videoUrl = exercise.videoUrl {
            CompactVideoPlayer(videoUrl: videoUrl, height: height)
        } else if let gifUrl = exercise.gifUrl {
            AsyncImage(url: URL(string: gifUrl)) { phase in
                switch phase {
                case .empty:
                    loadingView
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: height)
                        .clipped()
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
            .frame(height: height)
        } else {
            placeholderView
        }
    }

    private var loadingView: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: height)
            .overlay {
                ProgressView()
            }
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: height)
            .overlay {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
    }
}

/// Compact video player without controls - just plays and loops
struct CompactVideoPlayer: UIViewRepresentable {
    let videoUrl: String
    let height: CGFloat

    func makeUIView(context: Context) -> VideoLoopView {
        let view = VideoLoopView()
        view.configure(with: videoUrl)
        return view
    }

    func updateUIView(_ uiView: VideoLoopView, context: Context) {
        // URL changed - reconfigure
        if uiView.currentUrl != videoUrl {
            uiView.configure(with: videoUrl)
        }
    }
}

/// UIView that loops a video continuously
class VideoLoopView: UIView {
    private var playerLayer: AVPlayerLayer?
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private(set) var currentUrl: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.systemGray5
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with urlString: String) {
        // Clean up existing player
        cleanup()

        guard let url = URL(string: urlString) else { return }
        currentUrl = urlString

        let playerItem = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

        queuePlayer.isMuted = true
        queuePlayer.play()

        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.addSublayer(layer)

        self.player = queuePlayer
        self.playerLayer = layer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    private func cleanup() {
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLooper = nil
        playerLayer = nil
        currentUrl = nil
    }

    deinit {
        cleanup()
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Video Player")
            .font(.headline)

        VideoPlayerView(
            videoUrl: "https://example.com/exercise.mp4",
            gifUrl: "https://example.com/exercise.gif"
        )
        .frame(height: 200)

        Text("Exercise Media (compact)")
            .font(.headline)

        ExerciseMediaView(
            exercise: PlannedExercise(
                name: "Barbell Squat",
                sets: 3,
                reps: .int(10),
                weightKg: 60,
                weightSuggestion: nil,
                restSec: 90,
                tempo: nil,
                notes: nil,
                isSuperset: nil,
                supersetWith: nil,
                gifUrl: "https://v2.exercisedb.io/image/demo.gif",
                targetMuscle: "quadriceps",
                instructions: nil,
                secondaryMuscles: nil,
                videoUrl: nil
            ),
            height: 150
        )
    }
    .padding()
}
