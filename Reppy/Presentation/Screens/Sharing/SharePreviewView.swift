import SwiftUI

struct SharePreviewView: View {
    let cardType: SharingCardType
    @State private var generatedImage: UIImage?
    @State private var isSharePresented = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Preview
                    if let image = generatedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(9/16, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .white.opacity(0.1), radius: 20)
                            .padding(.horizontal, 40)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }

                    // Share button
                    Button {
                        isSharePresented = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share to Instagram")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 40)
                    .disabled(generatedImage == nil)
                }
            }
            .navigationTitle("Share Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .sheet(isPresented: $isSharePresented) {
                if let image = generatedImage {
                    ShareSheet(items: [image])
                }
            }
            .task {
                await generateCard()
            }
        }
    }

    @MainActor
    private func generateCard() async {
        // Small delay for smooth transition
        try? await Task.sleep(nanoseconds: 200_000_000)
        generatedImage = SharingService.shared.generateCard(type: cardType)
    }
}

// MARK: - Share Trigger View

struct ShareTriggerButton: View {
    let cardType: SharingCardType
    let label: String
    let icon: String
    @State private var showSharePreview = false

    var body: some View {
        Button {
            showSharePreview = true
        } label: {
            Label(label, systemImage: icon)
        }
        .sheet(isPresented: $showSharePreview) {
            SharePreviewView(cardType: cardType)
        }
    }
}

#Preview {
    SharePreviewView(cardType: .streakMilestone(days: 30, milestone: .month))
}
