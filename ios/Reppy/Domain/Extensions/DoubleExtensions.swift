import Foundation

extension Double {
    /// Formats a quantity cleanly - shows decimals only when needed
    /// 250.0 -> "250", 250.5 -> "250.5", 250.123 -> "250.1"
    var cleanQuantity: String {
        if self == floor(self) {
            return String(format: "%.0f", self)
        } else {
            // Round to 1 decimal and remove trailing .0
            let formatted = String(format: "%.1f", self)
            if formatted.hasSuffix(".0") {
                return String(formatted.dropLast(2))
            }
            return formatted
        }
    }
}
