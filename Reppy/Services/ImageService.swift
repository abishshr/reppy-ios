import UIKit

/// Service for image compression and upload to Supabase Storage
final class ImageService {
    private let maxDimension: CGFloat = 1024
    private let compressionQuality: CGFloat = 0.8

    // Supabase configuration - should match backend .env
    private let supabaseURL: String
    private let supabaseKey: String
    private let bucket = "meal-images"

    init() {
        // Load from Constants or environment
        self.supabaseURL = Constants.Supabase.url
        self.supabaseKey = Constants.Supabase.anonKey
    }

    /// Compress an image for upload
    /// - Parameter image: Original UIImage
    /// - Returns: Compressed JPEG data
    func compressImage(_ image: UIImage) -> Data? {
        // Resize if needed
        let resizedImage = resizeImage(image, maxDimension: maxDimension)

        // Compress to JPEG
        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }

    /// Convert image to base64 string for API requests
    /// - Parameter image: UIImage to convert
    /// - Returns: Base64-encoded string
    func imageToBase64(_ image: UIImage) -> String? {
        guard let data = compressImage(image) else { return nil }
        return data.base64EncodedString()
    }

    /// Upload image to Supabase Storage
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - userId: User ID for file organization
    /// - Returns: Public URL of uploaded image
    func uploadImage(_ image: UIImage, userId: String) async throws -> String {
        guard let imageData = compressImage(image) else {
            throw ImageServiceError.compressionFailed
        }

        // Generate unique filename
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        let uniqueId = UUID().uuidString.prefix(8)
        let filename = "\(userId)/\(timestamp)_\(uniqueId).jpg"

        // Build upload URL
        guard let uploadURL = URL(string: "\(supabaseURL)/storage/v1/object/\(bucket)/\(filename)") else {
            throw ImageServiceError.invalidURL
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...201).contains(httpResponse.statusCode) else {
            throw ImageServiceError.uploadFailed
        }

        // Return public URL
        return "\(supabaseURL)/storage/v1/object/public/\(bucket)/\(filename)"
    }

    // MARK: - Private Helpers

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // Check if resizing is needed
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        // Resize
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }
}

// MARK: - Errors

enum ImageServiceError: LocalizedError {
    case compressionFailed
    case invalidURL
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .invalidURL:
            return "Invalid upload URL"
        case .uploadFailed:
            return "Failed to upload image"
        }
    }
}
