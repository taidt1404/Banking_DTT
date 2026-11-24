import Foundation

public enum CurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.currencyCode = "VND"
        formatter.currencySymbol = "₫"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Formats a monetary value using standard Vietnamese currency grouping (e.g. 15.000.000 ₫).
    public static func format(_ value: Double) -> String {
        let absValue = abs(value)
        if let formatted = formatter.string(from: NSNumber(value: absValue)) {
            return formatted
        }
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        let formattedNumber = numberFormatter.string(from: NSNumber(value: absValue)) ?? "\(Int(absValue))"
        return "\(formattedNumber) ₫"
    }

    /// Alias for format(_:) to satisfy formatCurrency callers
    public static func formatCurrency(_ value: Double) -> String {
        format(value)
    }
}
