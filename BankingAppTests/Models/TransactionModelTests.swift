import XCTest
import SwiftData
@testable import BankingDTT

private typealias Transaction = BankingDTT.Transaction
private typealias Category = BankingDTT.Category

final class TransactionModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Transaction.self, Category.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }

    func testCreateAndFetchTransaction() throws {
        let category = Category(name: "Ăn uống", icon: "fork.knife", colorHex: "#FF9500", isDefault: true)
        modelContext.insert(category)

        let tx = Transaction(
            amount: 150000,
            type: .expense,
            date: Date(),
            recipientName: "NGUYEN VAN A",
            bankName: "Techcombank",
            transactionCode: "FT2632891048",
            note: "An trua phuc long",
            categoryId: category.id,
            billImagePath: "Bills/2026-11/test.jpg",
            rawOcrText: "Chuyen tien thanh cong 150.000 VND"
        )
        modelContext.insert(tx)
        try modelContext.save()

        let descriptor = FetchDescriptor<Transaction>()
        let results = try modelContext.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.amount, 150000)
        XCTAssertEqual(results.first?.type, .expense)
        XCTAssertEqual(results.first?.recipientName, "NGUYEN VAN A")
    }
}
