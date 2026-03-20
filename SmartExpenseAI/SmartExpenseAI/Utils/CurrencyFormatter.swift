import Foundation

struct CurrencyFormatter {
    static let shared: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        formatter.currencyCode = "IDR"
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    static func format(_ value: Double) -> String {
        return shared.string(from: NSNumber(value: value)) ?? "Rp 0"
    }
    
    static func formatInput(_ input: String) -> String {
        let cleanText = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if let value = Double(cleanText) {
            return format(value)
        }
        return ""
    }
    
    static func parse(_ input: String) -> Double? {
        let cleanText = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return Double(cleanText)
    }
}
