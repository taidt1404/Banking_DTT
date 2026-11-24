import Foundation
import SwiftData

@Model
public final class Transaction {
    @Attribute(.unique) public var id: UUID
    public var amount: Double
    public var type: TransactionType
    public var date: Date
    public var recipientName: String?
    public var bankName: String?
    public var transactionCode: String?
    public var note: String?
    public var categoryId: UUID?
    public var billImagePath: String?
    public var rawOcrText: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        date: Date = Date(),
        recipientName: String? = nil,
        bankName: String? = nil,
        transactionCode: String? = nil,
        note: String? = nil,
        categoryId: UUID? = nil,
        billImagePath: String? = nil,
        rawOcrText: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.date = date
        self.recipientName = recipientName
        self.bankName = bankName
        self.transactionCode = transactionCode
        self.note = note
        self.categoryId = categoryId
        self.billImagePath = billImagePath
        self.rawOcrText = rawOcrText
        self.createdAt = createdAt
    }
}
