import SwiftUI

public struct TransactionRowView: View {
    public let transaction: Transaction
    public let onSelect: () -> Void

    public init(transaction: Transaction, onSelect: @escaping () -> Void) {
        self.transaction = transaction
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: transaction.type == .expense ? "arrow.down.right.circle.fill" : "arrow.up.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(transaction.type == .expense ? .orange : .green)

                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.recipientName ?? "Chuyển tiền")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(transaction.date.formatted(date: .omitted, time: .shortened)) • \(transaction.bankName ?? "Ngân hàng")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Self.formatAmount(transaction.amount, type: transaction.type))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(transaction.type == .expense ? .red : .green)
                    
                    if let path = transaction.billImagePath, !path.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "doc.text.fill")
                            Text("BILL")
                        }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.indigo)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.indigo.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    /// Formats transaction amount with sign prefix and standard Vietnamese currency grouping
    public static func formatAmount(_ amount: Double, type: TransactionType) -> String {
        let sign = type == .expense ? "-" : "+"
        return "\(sign)\(CurrencyFormatter.format(amount))"
    }
}

#Preview {
    TransactionRowView(
        transaction: Transaction(
            amount: 120000,
            type: .expense,
            recipientName: "PHUC LONG TEA",
            bankName: "Techcombank",
            billImagePath: "Bills/sample.jpg"
        ),
        onSelect: {}
    )
    .padding()
}
