import SwiftUI
import WebKit
import ImageIO

/// A view that displays an animated GIF from a URL using native ImageIO
struct AnimatedGIFView: View {
    let url: URL

    @State private var gifImage: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            if isLoading {
                // Loading state
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.2)
                    )
            } else if gifImage != nil {
                // Show animated GIF using UIKit wrapper
                GIFImageView(gifURL: url)
                    .cornerRadius(12)
            } else if loadFailed {
                // Fallback placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)

                            Text("Exercise Demo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
        .task {
            await loadGIF()
        }
    }

    private func loadGIF() async {
        isLoading = true

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.gifImage = image
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.loadFailed = true
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.loadFailed = true
                self.isLoading = false
            }
        }
    }
}

/// UIKit wrapper for displaying animated GIFs
struct GIFImageView: UIViewRepresentable {
    let gifURL: URL
    var speedMultiplier: Double = 2.0 // Slow down GIFs (2.0 = half speed)

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        // Load and animate GIF
        let multiplier = speedMultiplier
        Task {
            await Self.loadAnimatedGIF(into: imageView, from: gifURL, speedMultiplier: multiplier)
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private static func loadAnimatedGIF(into imageView: UIImageView, from gifURL: URL, speedMultiplier: Double) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: gifURL)

            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return }

            let frameCount = CGImageSourceGetCount(source)
            var images: [UIImage] = []
            var totalDuration: Double = 0

            for i in 0..<frameCount {
                if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(UIImage(cgImage: cgImage))

                    // Get frame duration
                    if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                       let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                        let delayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double
                            ?? gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double
                            ?? 0.1
                        totalDuration += delayTime
                    } else {
                        totalDuration += 0.1
                    }
                }
            }

            await MainActor.run {
                imageView.animationImages = images
                // Apply speed multiplier (higher = slower animation)
                // Also ensure minimum duration for very fast GIFs
                let adjustedDuration = max(totalDuration * speedMultiplier, 1.5)
                imageView.animationDuration = adjustedDuration
                imageView.animationRepeatCount = 0 // Infinite loop
                imageView.startAnimating()

                // Also set static image as fallback
                if let firstImage = images.first {
                    imageView.image = firstImage
                }
            }
        } catch {
            // Load failed - show nothing (placeholder shown by parent)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AnimatedGIFView(url: URL(string: "https://v2.exercisedb.io/image/DY8bWkHifqNdRV")!)
            .frame(height: 200)

        AnimatedGIFView(url: URL(string: "https://media.giphy.com/media/JIX9t2j0ZTN9S/giphy.gif")!)
            .frame(height: 200)
    }
    .padding()
}
