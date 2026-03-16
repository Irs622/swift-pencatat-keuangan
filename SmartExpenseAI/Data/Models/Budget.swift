import Foundation
import SwiftData

@Model
final class Budget {
    @Attribute(.unique) var id: UUID
    var categoryId: UUID
    var limitAmount: Double
    var currentSpent: Double
    var month: Int
    var year: Int
    
    init(id: UUID = UUID(), 
         categoryId: UUID, 
         limitAmount: Double, 
         currentSpent: Double = 0, 
         month: Int = Calendar.current.component(.month, from: Date()), 
         year: Int = Calendar.current.component(.year, from: Date())) {
        self.id = id
        self.categoryId = categoryId
        self.limitAmount = limitAmount
        self.currentSpent = currentSpent
        self.month = month
        self.year = year
    }
    
    var progress: Double {
        guard limitAmount > 0 else { return 0 }
        return currentSpent / limitAmount
    }
    
    var isOverBudget: Bool {
        currentSpent > limitAmount
    }
    
    var isNearLimit: Bool {
        progress >= 0.8 && progress < 1.0
    }
}
