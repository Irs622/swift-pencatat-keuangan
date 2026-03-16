import Foundation
import SwiftData

enum TransactionType: String, Codable {
    case income
    case expense
}

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var date: Date
    var amount: Double
    var typeString: String
    var categoryId: UUID?
    var storeName: String?
    var note: String?
    var receiptImageData: Data?
    
    init(id: UUID = UUID(), 
         date: Date = Date(), 
         amount: Double, 
         type: TransactionType, 
         categoryId: UUID? = nil, 
         storeName: String? = nil, 
         note: String? = nil, 
         receiptImageData: Data? = nil) {
        self.id = id
        self.date = date
        self.amount = amount
        self.typeString = type.rawValue
        self.categoryId = categoryId
        self.storeName = storeName
        self.note = note
        self.receiptImageData = receiptImageData
    }
    
    var type: TransactionType {
        get { TransactionType(rawValue: typeString) ?? .expense }
        set { typeString = newValue.rawValue }
    }
    
    var amountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        formatter.currencyCode = "IDR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "Rp 0"
    }
}
