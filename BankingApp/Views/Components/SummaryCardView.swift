import SwiftUI

public struct SummaryCardView: View {
    public let totalExpense: Double
    public let totalIncome: Double

    public init(totalExpense: Double, totalIncome: Double) {
        self.totalExpense = totalExpense
        self.totalIncome = totalIncome
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tổng chi tháng này")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("-\(Self.formatCurrency(totalExpense))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
            }
            Spacer()
            Divider().frame(height: 30)
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Tổng thu tháng này")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("+\(Self.formatCurrency(totalIncome))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    public static func formatCurrency(_ value: Double) -> String {
        CurrencyFormatter.format(value)
    }
}

#Preview {
    SummaryCardView(totalExpense: 1250000, totalIncome: 5000000)
        .padding()
}
