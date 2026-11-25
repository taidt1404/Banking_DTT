import XCTest
import UIKit
import SwiftData
import AppIntents
@testable import BankingDTT

private typealias Transaction = BankingDTT.Transaction
private typealias Category = BankingDTT.Category

final class SaveBillIntentTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var temporaryDirectory: URL!
    var storageManager: BillStorageManager!

    override func setUpWithError() throws {
        let schema = Schema([Transaction.self, Category.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)

        temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        storageManager = BillStorageManager(baseDirectory: temporaryDirectory)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
        if let temporaryDirectory = temporaryDirectory, FileManager.default.fileExists(atPath: temporaryDirectory.path) {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        temporaryDirectory = nil
        storageManager = nil
    }

    // Step 1: Unit test simulating SaveBillIntent execution logic from brief
    func testProcessBillImageToTransaction() async throws {
        let rawOCR = """
        CHUYỂN TIỀN THÀNH CÔNG
        Techcombank
        120.000 VND
        Người nhận: PHUC LONG TEA
        Nội dung: Tra sua
        """
        let parsed = TransactionRegexParser.parse(rawText: rawOCR)
        XCTAssertEqual(parsed.amount, 120000)
        XCTAssertEqual(parsed.recipientName, "PHUC LONG TEA")
        
        let tx = Transaction(
            amount: parsed.amount ?? 0,
            type: parsed.type,
            recipientName: parsed.recipientName,
            bankName: parsed.bankName,
            note: parsed.note
        )
        XCTAssertEqual(tx.amount, 120000)
    }

    func testSaveBillIntentMetadata() {
        XCTAssertEqual(String(localized: SaveBillIntent.title), "Lưu Bill Ngân Hàng")
        XCTAssertFalse(SaveBillIntent.openAppWhenRun, "SaveBillIntent must run in the background for Back Tap")
    }

    func testBankingShortcutsProvider() {
        let shortcuts = BankingShortcutsProvider.appShortcuts
        XCTAssertFalse(shortcuts.isEmpty)
        XCTAssertEqual(shortcuts.count, 1)
        XCTAssertEqual(String(localized: BankingShortcutsProvider.shortcutTitle), "Lưu Bill Ngân Hàng")
        XCTAssertEqual(BankingShortcutsProvider.shortcutSystemImage, "doc.text.viewfinder")
    }

    func testSaveBillIntentDialogFormatting() {
        let dialogWithRecipient = SaveBillIntent.formatSuccessDialog(amount: 150000, recipientName: "NGUYEN VAN A")
        XCTAssertEqual(dialogWithRecipient, "Đã lưu bill 150000 đ (NGUYEN VAN A)")

        let dialogWithoutRecipient = SaveBillIntent.formatSuccessDialog(amount: 50000, recipientName: nil)
        XCTAssertEqual(dialogWithoutRecipient, "Đã lưu bill 50000 đ (giao dịch)")
    }

    func testFullTransactionPersistenceFromParsedOCR() throws {
        let sampleOCR = """
        GIAO DỊCH THÀNH CÔNG
        Vietcombank
        500.000 VND
        Người nhận: Highlands Coffee
        Mã GD: VCB123456789
        Nội dung: Tien ca phe sang
        """
        let parsed = TransactionRegexParser.parse(rawText: sampleOCR)
        XCTAssertNotNil(parsed.amount)
        XCTAssertEqual(parsed.amount, 500000)
        XCTAssertEqual(parsed.bankName, "Vietcombank")
        XCTAssertEqual(parsed.recipientName, "Highlands Coffee")
        XCTAssertEqual(parsed.transactionCode, "VCB123456789")
        XCTAssertEqual(parsed.note, "Tien ca phe sang")

        // Create sample dummy image and save through storage manager
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100), format: format)
        let dummyImage = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }

        let relativePath = try storageManager.saveBillImage(dummyImage)
        XCTAssertTrue(relativePath.hasPrefix("Bills/"))

        let transaction = Transaction(
            amount: parsed.amount!,
            type: parsed.type,
            date: Date(),
            recipientName: parsed.recipientName,
            bankName: parsed.bankName,
            transactionCode: parsed.transactionCode,
            note: parsed.note,
            billImagePath: relativePath,
            rawOcrText: sampleOCR
        )
        modelContext.insert(transaction)
        try modelContext.save()

        let descriptor = FetchDescriptor<Transaction>()
        let savedTransactions = try modelContext.fetch(descriptor)
        XCTAssertEqual(savedTransactions.count, 1)

        let saved = savedTransactions.first
        XCTAssertEqual(saved?.amount, 500000)
        XCTAssertEqual(saved?.type, .expense)
        XCTAssertEqual(saved?.recipientName, "Highlands Coffee")
        XCTAssertEqual(saved?.bankName, "Vietcombank")
        XCTAssertEqual(saved?.transactionCode, "VCB123456789")
        XCTAssertEqual(saved?.note, "Tien ca phe sang")
        XCTAssertEqual(saved?.billImagePath, relativePath)
        XCTAssertEqual(saved?.rawOcrText, sampleOCR)

        // Verify loaded image from sandbox path
        let loadedImage = storageManager.loadBillImage(relativePath: relativePath)
        XCTAssertNotNil(loadedImage)
    }

    func testIncomeTransactionPersistence() throws {
        let sampleOCR = """
        NHẬN TIỀN THÀNH CÔNG
        +2.000.000 VND
        MB Bank
        Từ người gửi: CONG TY TNHH ABC
        Nội dung: Tam ung luong
        """
        let parsed = TransactionRegexParser.parse(rawText: sampleOCR)
        XCTAssertEqual(parsed.amount, 2000000)
        XCTAssertEqual(parsed.type, .income)
        XCTAssertEqual(parsed.bankName, "MB Bank")

        let transaction = Transaction(
            amount: parsed.amount ?? 0,
            type: parsed.type,
            recipientName: parsed.recipientName,
            bankName: parsed.bankName,
            note: parsed.note
        )
        modelContext.insert(transaction)
        try modelContext.save()

        let descriptor = FetchDescriptor<Transaction>(predicate: #Predicate { $0.amount > 1000000 })
        let results = try modelContext.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.type, .income)
        XCTAssertEqual(results.first?.amount, 2000000)
    }
}
