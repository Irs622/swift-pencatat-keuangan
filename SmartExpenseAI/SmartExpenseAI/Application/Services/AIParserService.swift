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
    
    // Local fallback for receipt parsing using RegEx
    func parseReceiptText(_ text: String, completion: @escaping (Result<AIReceiptData, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let lines = text.components(separatedBy: .newlines)
            var storeName = "Unknown Store"
            var totalAmount: Double = 0.0
            
            // Extract store name
            for line in lines.prefix(5) {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count > 3 && !trimmed.lowercased().contains("reprint") {
                    storeName = trimmed
                    break
                }
            }
            
            // Extract amount with RegEx
            var amounts: [Double] = []
            let amountPattern = "(?:rp|rp\\.)?\\s?([0-9]{1,3}(?:[.,][0-9]{3})*|[0-9]+)"
            if let regex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive) {
                let nsString = text as NSString
                let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for result in results {
                    var match = nsString.substring(with: result.range(at: 1))
                    match = match.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")
                    if let val = Double(match) { amounts.append(val) }
                }
            }
            totalAmount = amounts.max() ?? 0.0
            
            let data = AIReceiptData(
                storeName: storeName,
                date: Date().formatted(.dateTime.year().month().day()),
                totalAmount: totalAmount,
                category: "Others"
            )
            
            DispatchQueue.main.async {
                completion(.success(data))
            }
        }
    }
}
