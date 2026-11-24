import XCTest
import SwiftData
@testable import BankingApp

final class TimelineGroupingTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Transaction.self, Category.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    // Step 1 from Task Brief: Unit test for grouping transactions by Calendar day
    func testGroupTransactionsByDate() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let tx1 = Transaction(amount: 100000, type: .expense, date: today)
        let tx2 = Transaction(amount: 50000, type: .expense, date: today)
        let tx3 = Transaction(amount: 200000, type: .income, date: yesterday)

        let grouped = Dictionary(grouping: [tx1, tx2, tx3]) { tx in
            calendar.startOfDay(for: tx.date)
        }

        XCTAssertEqual(grouped.keys.count, 2)
        XCTAssertEqual(grouped[calendar.startOfDay(for: today)]?.count, 2)
        XCTAssertEqual(grouped[calendar.startOfDay(for: yesterday)]?.count, 1)
    }

    // Test DailyTimelineView.groupTransactions sorts sections descending (most recent date first)
    func testDailyTimelineGroupTransactionsSortedDescending() {
        let calendar = Calendar.current
        let now = Date()
        guard let today = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: now)),
              let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) else {
            XCTFail("Failed to compute test dates")
            return
        }

        let tx1 = Transaction(amount: 100000, type: .expense, date: twoDaysAgo)
        let tx2 = Transaction(amount: 50000, type: .expense, date: today)
        let tx3 = Transaction(amount: 200000, type: .income, date: yesterday)
        let tx4 = Transaction(amount: 75000, type: .expense, date: today)

        let groupedSections = DailyTimelineView.groupTransactions([tx1, tx2, tx3, tx4], calendar: calendar)

        XCTAssertEqual(groupedSections.count, 3)
        // Most recent first: today > yesterday > twoDaysAgo
        XCTAssertEqual(groupedSections[0].0, today)
        XCTAssertEqual(groupedSections[0].1.count, 2)

        XCTAssertEqual(groupedSections[1].0, yesterday)
        XCTAssertEqual(groupedSections[1].1.count, 1)

        XCTAssertEqual(groupedSections[2].0, twoDaysAgo)
        XCTAssertEqual(groupedSections[2].1.count, 1)
    }

    // Test total expense and income calculations
    func testDailyTimelineCalculateTotals() {
        let tx1 = Transaction(amount: 150000, type: .expense)
        let tx2 = Transaction(amount: 350000, type: .expense)
        let tx3 = Transaction(amount: 2000000, type: .income)
        let tx4 = Transaction(amount: 500000, type: .income)

        let totals = DailyTimelineView.calculateTotals(from: [tx1, tx2, tx3, tx4])
        XCTAssertEqual(totals.expense, 500000)
        XCTAssertEqual(totals.income, 2500000)

        let emptyTotals = DailyTimelineView.calculateTotals(from: [])
        XCTAssertEqual(emptyTotals.expense, 0)
        XCTAssertEqual(emptyTotals.income, 0)
    }

    // Test section date formatting for Today, Yesterday, and past dates
    func testDailyTimelineFormatSectionDate() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let pastDate = calendar.date(byAdding: .day, value: -10, to: today)!

        let todayStr = DailyTimelineView.formatSectionDate(today, calendar: calendar)
        XCTAssertTrue(todayStr.hasPrefix("Hôm nay ("))

        let yesterdayStr = DailyTimelineView.formatSectionDate(yesterday, calendar: calendar)
        XCTAssertTrue(yesterdayStr.hasPrefix("Hôm qua ("))

        let pastStr = DailyTimelineView.formatSectionDate(pastDate, calendar: calendar)
        XCTAssertFalse(pastStr.hasPrefix("Hôm nay"))
        XCTAssertFalse(pastStr.hasPrefix("Hôm qua"))
    }

    // Test SummaryCardView currency formatting
    func testSummaryCardViewCurrencyFormatting() {
        let formatted = SummaryCardView.formatCurrency(150000)
        XCTAssertTrue(formatted.contains("150") || formatted.contains("₫") || formatted.contains("VND") || formatted.contains("đ"))
    }

    // Test SwiftData persistence integration with grouping
    func testSwiftDataPersistenceWithGrouping() throws {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let tx1 = Transaction(amount: 80000, type: .expense, date: today, recipientName: "Bánh mì")
        let tx2 = Transaction(amount: 45000, type: .expense, date: yesterday, recipientName: "Cà phê")
        modelContext.insert(tx1)
        modelContext.insert(tx2)
        try modelContext.save()

        let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let fetched = try modelContext.fetch(descriptor)

        XCTAssertEqual(fetched.count, 2)
        let grouped = DailyTimelineView.groupTransactions(fetched, calendar: calendar)
        XCTAssertEqual(grouped.count, 2)
        XCTAssertEqual(grouped[0].1.first?.recipientName, "Bánh mì")
        XCTAssertEqual(grouped[1].1.first?.recipientName, "Cà phê")
    }
}
