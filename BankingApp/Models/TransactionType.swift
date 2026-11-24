import Foundation

public enum TransactionType: String, Codable, CaseIterable {
    case expense = "expense"
    case income = "income"
}
