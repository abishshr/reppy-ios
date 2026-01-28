import SwiftUI

/// Compact row of quick action buttons
struct QuickActionsRow: View {
    let onLogMeal: () -> Void
    let onLogWorkout: () -> Void
    let onScanBarcode: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            QuickActionButton(
                icon: "fork.knife",
                label: "+ Meal",
                color: .green,
                action: onLogMeal
            )

            QuickActionButton(
                icon: "dumbbell.fill",
                label: "+ Workout",
                color: .blue,
                action: onLogWorkout
            )

            QuickActionButton(
                icon: "barcode.viewfinder",
                label: "Scan",
                color: .purple,
                action: onScanBarcode
            )
        }
    }
}

/// Individual quick action button
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))

                Text(label)
                    .font(.caption.bold())
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.12))
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

#Preview {
    QuickActionsRow(
        onLogMeal: {},
        onLogWorkout: {},
        onScanBarcode: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
