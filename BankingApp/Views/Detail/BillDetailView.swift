import SwiftUI
import SwiftData
import UIKit

public struct BillDetailView: View {
    @Bindable public var transaction: Transaction
    private let storageManager: BillStorageManager
    @Environment(\.dismiss) private var dismiss

    public init(transaction: Transaction, storageManager: BillStorageManager = .shared) {
        self.transaction = transaction
        self.storageManager = storageManager
    }

    /// Helper binding generator for optional string properties on Transaction
    public static func optionalStringBinding(
        get: @escaping () -> String?,
        set: @escaping (String?) -> Void
    ) -> Binding<String> {
        Binding(
            get: { get() ?? "" },
            set: { newValue in
                set(newValue.isEmpty ? nil : newValue)
            }
        )
    }

    public var body: some View {
        NavigationStack {
            Form {
                if let path = transaction.billImagePath,
                   !path.isEmpty,
                   let image = storageManager.loadBillImage(relativePath: path) {
                    Section("Biên lai gốc (Chạm và phóng to)") {
                        ZoomableImageView(image: image)
                            .frame(maxHeight: 320)
                            .listRowInsets(EdgeInsets())
                    }
                }

                Section("Thông tin giao dịch") {
                    HStack {
                        Text("Số tiền")
                        Spacer()
                        TextField("Số tiền", value: $transaction.amount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Người nhận/gửi")
                        Spacer()
                        TextField("Tên", text: Self.optionalStringBinding(
                            get: { transaction.recipientName },
                            set: { transaction.recipientName = $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Ngân hàng")
                        Spacer()
                        TextField("Ngân hàng", text: Self.optionalStringBinding(
                            get: { transaction.bankName },
                            set: { transaction.bankName = $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Nội dung")
                        Spacer()
                        TextField("Ghi chú", text: Self.optionalStringBinding(
                            get: { transaction.note },
                            set: { transaction.note = $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                    }
                }

                if let code = transaction.transactionCode, !code.isEmpty {
                    Section("Mã tham chiếu ngân hàng") {
                        Text(code)
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Chi tiết Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Transaction.self, configurations: config)
    let sample = Transaction(
        amount: 350000,
        type: .expense,
        recipientName: "Highlands Coffee",
        bankName: "Techcombank",
        transactionCode: "FT261124123456",
        note: "Cà phê gặp khách hàng"
    )
    container.mainContext.insert(sample)

    return BillDetailView(transaction: sample)
        .modelContainer(container)
}
