import Foundation
import SwiftData

@Model
public final class Category {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var isDefault: Bool

    public init(id: UUID = UUID(), name: String, icon: String, colorHex: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isDefault = isDefault
    }
}
