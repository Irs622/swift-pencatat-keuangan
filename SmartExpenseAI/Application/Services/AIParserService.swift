import Foundation

struct AIReceiptData: Codable {
    let storeName: String
    let date: String
    let totalAmount: Double
    let category: String
}

class AIParserService {
    static let shared = AIParserService()
    
    private init() {}
    
    // Mock implementation for development
    func parseReceiptText(_ text: String, completion: @escaping (Result<AIReceiptData, Error>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Check for keywords in OCR text to provide semi-intelligent mock data
            let textLower = text.lowercased()
            
            var store = "Unknown Store"
            var amount = 15.00
            var category = "Shopping"
            
            if textLower.contains("starbucks") || textLower.contains("coffee") {
                store = "Starbucks"
                category = "Food & Drink"
                amount = 12.50
            } else if textLower.contains("apple") || textLower.contains("iphone") {
                store = "Apple Store"
                category = "Shopping"
                amount = 129.00
            } else if textLower.contains("walmart") || textLower.contains("grocery") {
                store = "Walmart"
                category = "Groceries"
                amount = 85.20
            }
            
            let mockData = AIReceiptData(
                storeName: store,
                date: "2026-03-16",
                totalAmount: amount,
                category: category
            )
            
            completion(.success(mockData))
        }
    }
}
