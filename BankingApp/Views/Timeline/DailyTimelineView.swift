import SwiftUI
import SwiftData

public struct DailyTimelineView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var selectedTransaction: Transaction?

    public init() {}

    private var groupedTransactions: [(Date, [Transaction])] {
        Self.groupTransactions(transactions)
    }

    private var totalExpense: Double {
        Self.calculateTotals(from: transactions).expense
    }

    private var totalIncome: Double {
        Self.calculateTotals(from: transactions).income
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    SummaryCardView(totalExpense: totalExpense, totalIncome: totalIncome)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                ForEach(groupedTransactions, id: \.0) { date, items in
                    Section(header: Text(formatSectionDate(date))) {
                        ForEach(items) { tx in
                            TransactionRowView(transaction: tx) {
                                selectedTransaction = tx
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Sổ Chi Tiêu")
            .sheet(item: $selectedTransaction) { tx in
                BillDetailView(transaction: tx)
            }
        }
    }

    private func formatSectionDate(_ date: Date) -> String {
        Self.formatSectionDate(date)
    }

    // MARK: - Business Logic Helpers

    public static func groupTransactions(_ transactions: [Transaction], calendar: Calendar = .current) -> [(Date, [Transaction])] {
        let grouped = Dictionary(grouping: transactions) { tx in
            calendar.startOfDay(for: tx.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    public static func formatSectionDate(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Hôm nay (\(date.formatted(.dateTime.day().month())))" }
        if calendar.isDateInYesterday(date) { return "Hôm qua (\(date.formatted(.dateTime.day().month())))" }
        return date.formatted(.dateTime.day().month().year())
    }

    public static func calculateTotals(from transactions: [Transaction]) -> (expense: Double, income: Double) {
        let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        return (expense, income)
    }
}

#Preview {
    DailyTimelineView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
