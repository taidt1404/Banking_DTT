import XCTest
import SwiftData
import SwiftUI
@testable import BankingApp

final class ShortcutsSetupGuideViewTests: XCTestCase {
    var inMemoryContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        inMemoryContainer = BankingApp.createModelContainer(inMemory: true)
        modelContext = ModelContext(inMemoryContainer)
    }

    override func tearDownWithError() throws {
        inMemoryContainer = nil
        modelContext = nil
    }

    // MARK: - ShortcutsSetupGuideView & GuideStep Tests

    func testShortcutsSetupGuideViewInitialization() {
        let view = ShortcutsSetupGuideView()
        XCTAssertNotNil(view)
    }

    func testSetupStepsCount() {
        XCTAssertEqual(ShortcutsSetupGuideView.steps.count, 3)
    }

    func testSetupStep1Content() {
        guard ShortcutsSetupGuideView.steps.count >= 1 else {
            XCTFail("Missing step 1")
            return
        }
        let step1 = ShortcutsSetupGuideView.steps[0]
        XCTAssertEqual(step1.step, "1")
        XCTAssertEqual(step1.title, "Mở Cài Đặt iPhone")
        XCTAssertTrue(step1.subtitle.contains("Cài đặt > Trợ năng > Cảm ứng"))
    }

    func testSetupStep2Content() {
        guard ShortcutsSetupGuideView.steps.count >= 2 else {
            XCTFail("Missing step 2")
            return
        }
        let step2 = ShortcutsSetupGuideView.steps[1]
        XCTAssertEqual(step2.step, "2")
        XCTAssertEqual(step2.title, "Chọn Chạm vào mặt lưng")
        XCTAssertTrue(step2.subtitle.contains("Chạm 2 lần (Double Tap)"))
    }

    func testSetupStep3Content() {
        guard ShortcutsSetupGuideView.steps.count >= 3 else {
            XCTFail("Missing step 3")
            return
        }
        let step3 = ShortcutsSetupGuideView.steps[2]
        XCTAssertEqual(step3.step, "3")
        XCTAssertEqual(step3.title, "Gán Phím Tắt")
        XCTAssertTrue(step3.subtitle.contains("Lưu Bill Ngân Hàng"))
    }

    func testGuideStepEquatableAndIdentifiable() {
        let stepA = GuideStep(step: "1", title: "Title 1", subtitle: "Subtitle 1")
        let stepB = GuideStep(step: "1", title: "Title 1", subtitle: "Subtitle 1")
        let stepC = GuideStep(step: "2", title: "Title 2", subtitle: "Subtitle 2")

        XCTAssertEqual(stepA, stepB)
        XCTAssertNotEqual(stepA, stepC)
        XCTAssertEqual(stepA.id, "1")
        XCTAssertEqual(stepC.id, "2")
    }

    func testGuideStepRowInitialization() {
        let row = GuideStepRow(step: "1", title: "Test", subtitle: "Test Subtitle")
        XCTAssertEqual(row.step, "1")
        XCTAssertEqual(row.title, "Test")
        XCTAssertEqual(row.subtitle, "Test Subtitle")
    }

    // MARK: - BankingApp & ModelContainer Tests

    func testBankingAppCreateModelContainerSchemaRegistration() throws {
        XCTAssertNotNil(inMemoryContainer)
        let schema = inMemoryContainer.schema
        let entityNames = schema.entities.map { $0.name }

        XCTAssertTrue(entityNames.contains("Transaction"))
        XCTAssertTrue(entityNames.contains("Category"))
    }

    func testBankingAppModelContainerPersistenceRoundtrip() throws {
        let testCategory = Category(name: "Ăn uống", icon: "fork.knife", colorHex: "#FF9500", isDefault: true)
        modelContext.insert(testCategory)

        let testTransaction = Transaction(
            amount: 75000,
            type: .expense,
            recipientName: "Phở Gia Truyền",
            bankName: "Vietcombank",
            categoryId: testCategory.id
        )
        modelContext.insert(testTransaction)
        try modelContext.save()

        let fetchedTransactions = try modelContext.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(fetchedTransactions.count, 1)
        XCTAssertEqual(fetchedTransactions.first?.amount, 75000)
        XCTAssertEqual(fetchedTransactions.first?.recipientName, "Phở Gia Truyền")
        XCTAssertEqual(fetchedTransactions.first?.bankName, "Vietcombank")

        let fetchedCategories = try modelContext.fetch(FetchDescriptor<Category>())
        XCTAssertEqual(fetchedCategories.count, 1)
        XCTAssertEqual(fetchedCategories.first?.name, "Ăn uống")
    }

    func testBankingAppInitializationWithCustomContainer() {
        let app = BankingApp(modelContainer: inMemoryContainer)
        XCTAssertNotNil(app.sharedModelContainer)
    }
}
