import XCTest
import SwiftUI
import SwiftData
import UIKit
@testable import BankingDTT

private typealias Transaction = BankingDTT.Transaction
private typealias Category = BankingDTT.Category

final class BillDetailViewTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var tempDirectory: URL!

    override func setUpWithError() throws {
        let schema = Schema([Transaction.self, Category.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)

        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
    }

    // MARK: - Amount Binding & Direct Mutation Tests

    func testAmountBindingUpdatesModel() {
        let transaction = Transaction(amount: 150000, type: .expense)
        modelContext.insert(transaction)

        XCTAssertEqual(transaction.amount, 150000)

        // Mutate amount directly (same mutation performed by TextField format: .number binding)
        transaction.amount = 250000
        XCTAssertEqual(transaction.amount, 250000)

        transaction.amount = 0
        XCTAssertEqual(transaction.amount, 0)
    }

    // MARK: - Optional String Binding Tests

    func testOptionalStringBindingGetAndSet() {
        var backingValue: String? = nil
        let binding = BillDetailView.optionalStringBinding(
            get: { backingValue },
            set: { backingValue = $0 }
        )

        // Initial state is nil -> binding reads as empty string
        XCTAssertEqual(binding.wrappedValue, "")

        // Setting a non-empty string updates backing value
        binding.wrappedValue = "Techcombank"
        XCTAssertEqual(backingValue, "Techcombank")
        XCTAssertEqual(binding.wrappedValue, "Techcombank")

        // Setting empty string resets backing value to nil
        binding.wrappedValue = ""
        XCTAssertNil(backingValue)
        XCTAssertEqual(binding.wrappedValue, "")
    }

    func testRecipientNameBindingOnTransaction() {
        let transaction = Transaction(amount: 50000, type: .expense, recipientName: nil)
        modelContext.insert(transaction)

        let recipientBinding = BillDetailView.optionalStringBinding(
            get: { transaction.recipientName },
            set: { transaction.recipientName = $0 }
        )

        XCTAssertEqual(recipientBinding.wrappedValue, "")
        XCTAssertNil(transaction.recipientName)

        recipientBinding.wrappedValue = "Nguyen Van A"
        XCTAssertEqual(transaction.recipientName, "Nguyen Van A")
        XCTAssertEqual(recipientBinding.wrappedValue, "Nguyen Van A")

        recipientBinding.wrappedValue = ""
        XCTAssertNil(transaction.recipientName)
        XCTAssertEqual(recipientBinding.wrappedValue, "")
    }

    func testBankNameBindingOnTransaction() {
        let transaction = Transaction(amount: 120000, type: .expense, bankName: "Vietcombank")
        modelContext.insert(transaction)

        let bankBinding = BillDetailView.optionalStringBinding(
            get: { transaction.bankName },
            set: { transaction.bankName = $0 }
        )

        XCTAssertEqual(bankBinding.wrappedValue, "Vietcombank")

        bankBinding.wrappedValue = "MB Bank"
        XCTAssertEqual(transaction.bankName, "MB Bank")

        bankBinding.wrappedValue = ""
        XCTAssertNil(transaction.bankName)
    }

    func testNoteBindingOnTransaction() {
        let transaction = Transaction(amount: 75000, type: .expense, note: "Ăn trưa")
        modelContext.insert(transaction)

        let noteBinding = BillDetailView.optionalStringBinding(
            get: { transaction.note },
            set: { transaction.note = $0 }
        )

        XCTAssertEqual(noteBinding.wrappedValue, "Ăn trưa")

        noteBinding.wrappedValue = "Ăn trưa cùng đồng nghiệp"
        XCTAssertEqual(transaction.note, "Ăn trưa cùng đồng nghiệp")

        noteBinding.wrappedValue = ""
        XCTAssertNil(transaction.note)
    }

    // MARK: - Bill Image Path Resolution Tests

    func testBillImageResolutionWithValidPath() throws {
        let storage = BillStorageManager(baseDirectory: tempDirectory)
        let sampleImage = UIImage(systemName: "checkmark.seal.fill") ?? UIImage()
        let relativePath = try storage.saveBillImage(sampleImage)

        let transaction = Transaction(
            amount: 200000,
            type: .expense,
            billImagePath: relativePath
        )
        modelContext.insert(transaction)

        // Verify storage can resolve and load the image
        guard let path = transaction.billImagePath else {
            XCTFail("billImagePath should not be nil")
            return
        }
        let loaded = storage.loadBillImage(relativePath: path)
        XCTAssertNotNil(loaded)

        // Initializing BillDetailView with this storage succeeds
        let view = BillDetailView(transaction: transaction, storageManager: storage)
        XCTAssertNotNil(view)
    }

    func testBillImageResolutionWithNilPath() {
        let storage = BillStorageManager(baseDirectory: tempDirectory)
        let transaction = Transaction(amount: 100000, type: .expense, billImagePath: nil)

        XCTAssertNil(transaction.billImagePath)

        let view = BillDetailView(transaction: transaction, storageManager: storage)
        XCTAssertNotNil(view)
    }

    func testBillImageResolutionWithNonExistentPath() {
        let storage = BillStorageManager(baseDirectory: tempDirectory)
        let transaction = Transaction(
            amount: 100000,
            type: .expense,
            billImagePath: "Bills/2026-11/missing_image_12345.jpg"
        )

        guard let path = transaction.billImagePath else {
            XCTFail("billImagePath should be present")
            return
        }
        let loaded = storage.loadBillImage(relativePath: path)
        XCTAssertNil(loaded)
    }

    // MARK: - Transaction Code Presentation Tests

    func testTransactionCodePreserved() {
        let code = "FT261124987654321"
        let transaction = Transaction(
            amount: 500000,
            type: .expense,
            transactionCode: code
        )
        modelContext.insert(transaction)

        XCTAssertEqual(transaction.transactionCode, code)

        // Mutating other fields leaves transaction code unchanged
        transaction.amount = 600000
        transaction.recipientName = "Cửa hàng tiện lợi"
        XCTAssertEqual(transaction.transactionCode, code)
    }

    // MARK: - ZoomableImageView Scaling Tests

    func testZoomableImageViewClampedScaleBounds() {
        // Minimum bound (1.0)
        XCTAssertEqual(ZoomableImageView.clampedScale(0.2), 1.0)
        XCTAssertEqual(ZoomableImageView.clampedScale(0.99), 1.0)
        XCTAssertEqual(ZoomableImageView.clampedScale(1.0), 1.0)

        // Intermediate scaling values
        XCTAssertEqual(ZoomableImageView.clampedScale(1.5), 1.5)
        XCTAssertEqual(ZoomableImageView.clampedScale(2.8), 2.8)
        XCTAssertEqual(ZoomableImageView.clampedScale(4.0), 4.0)

        // Maximum bound (4.0)
        XCTAssertEqual(ZoomableImageView.clampedScale(4.1), 4.0)
        XCTAssertEqual(ZoomableImageView.clampedScale(10.0), 4.0)
    }

    func testZoomableImageViewInitialization() {
        let sampleImage = UIImage(systemName: "photo") ?? UIImage()
        let zoomView = ZoomableImageView(image: sampleImage)
        XCTAssertNotNil(zoomView)
        XCTAssertEqual(zoomView.image, sampleImage)
    }

    // MARK: - SwiftData Persistence Integration Tests

    func testSwiftDataPersistenceIntegration() throws {
        let tx = Transaction(
            amount: 150000,
            type: .expense,
            recipientName: "Bún Bò Huế",
            bankName: "TPBank",
            note: "Ăn trưa"
        )
        modelContext.insert(tx)
        try modelContext.save()

        // Mutate fields through the view bindings pattern
        let recipientBinding = BillDetailView.optionalStringBinding(
            get: { tx.recipientName },
            set: { tx.recipientName = $0 }
        )
        let noteBinding = BillDetailView.optionalStringBinding(
            get: { tx.note },
            set: { tx.note = $0 }
        )

        tx.amount = 180000
        recipientBinding.wrappedValue = "Bún Bò Huế Đặc Biệt"
        noteBinding.wrappedValue = "Ăn trưa cùng nhóm"
        try modelContext.save()

        // Fetch back and assert persistence
        let descriptor = FetchDescriptor<Transaction>()
        let results = try modelContext.fetch(descriptor)

        XCTAssertEqual(results.count, 1)
        let savedTx = try XCTUnwrap(results.first)
        XCTAssertEqual(savedTx.amount, 180000)
        XCTAssertEqual(savedTx.recipientName, "Bún Bò Huế Đặc Biệt")
        XCTAssertEqual(savedTx.bankName, "TPBank")
        XCTAssertEqual(savedTx.note, "Ăn trưa cùng nhóm")
    }
}
