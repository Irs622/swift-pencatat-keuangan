import SwiftUI

struct Theme {
    static let primaryBackground = LinearGradient(
        colors: [
            Color(hexString: "0F172A") ?? Color(red: 15/255, green: 23/255, blue: 42/255), // Deep Navy
            Color(hexString: "1E293B") ?? Color(red: 30/255, green: 41/255, blue: 59/255), // Slate
            Color(hexString: "020617") ?? Color(red: 2/255, green: 6/255, blue: 23/255)    // Black
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentColor = Color(hexString: "38BDF8") ?? .blue // Sky Blue
    static let secondaryAccent = Color(hexString: "818CF8") ?? .indigo // Indigo
    static let dangerColor = Color(hexString: "F43F5E") ?? .red // Rose
    static let successColor = Color(hexString: "10B981") ?? .green // Emerald
    
    static let glassOpacity = 0.15
    static let glassBlur = 25.0
    static let cornerRadius: CGFloat = 28
    
    // Currency Formatter
    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        formatter.currencyCode = "IDR"
        formatter.maximumFractionDigits = 0 // Rupiah usually doesn't show decimals
        return formatter.string(from: NSNumber(value: amount)) ?? "Rp 0"
    }
}

// Global styles and spacing
struct Spacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
}
