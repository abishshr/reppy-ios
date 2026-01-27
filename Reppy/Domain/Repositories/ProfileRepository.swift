import Foundation

/// Protocol for profile repository
protocol ProfileRepository {
    func fetchProfile() async throws -> UserProfile
    func createProfile(_ profile: ProfileCreate) async throws -> UserProfile
    func updateProfile(_ profile: ProfileUpdate) async throws -> UserProfile
}

/// Implementation of ProfileRepository
final class ProfileRepositoryImpl: ProfileRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchProfile() async throws -> UserProfile {
        try await apiClient.fetchProfile()
    }

    func createProfile(_ profile: ProfileCreate) async throws -> UserProfile {
        try await apiClient.createProfile(profile)
    }

    func updateProfile(_ profile: ProfileUpdate) async throws -> UserProfile {
        try await apiClient.updateProfile(profile)
    }
}
