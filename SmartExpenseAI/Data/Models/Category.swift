import Foundation
import SwiftData
import SwiftUI

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    
    init(id: UUID = UUID(), name: String, iconName: String, colorHex: String) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
    }
    
    var color: Color {
        Color(hexString: colorHex) ?? .blue
    }
}
