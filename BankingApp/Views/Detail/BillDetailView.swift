import SwiftUI

/// Placeholder stub for Task 6: SwiftUI Bill Detail & Zoomable Viewer.
public struct BillDetailView: View {
    public var transaction: Transaction
    @Environment(\.dismiss) private var dismiss

    public init(transaction: Transaction) {
        self.transaction = transaction
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(transaction.recipientName ?? "Chi tiết giao dịch")
                    .font(.headline)
                Text("\(Int(transaction.amount)) đ")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .navigationTitle("Chi tiết")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    BillDetailView(
        transaction: Transaction(
            amount: 150000,
            type: .expense,
            recipientName: "Cà phê Highlands"
        )
    )
}
