import Foundation

public struct ParsedBillResult: Equatable, Sendable {
    public var amount: Double?
    public var type: TransactionType
    public var recipientName: String?
    public var bankName: String?
    public var transactionCode: String?
    public var note: String?
    public var rawText: String

    public init(
        amount: Double? = nil,
        type: TransactionType = .expense,
        recipientName: String? = nil,
        bankName: String? = nil,
        transactionCode: String? = nil,
        note: String? = nil,
        rawText: String = ""
    ) {
        self.amount = amount
        self.type = type
        self.recipientName = recipientName
        self.bankName = bankName
        self.transactionCode = transactionCode
        self.note = note
        self.rawText = rawText
    }
}
