import AppIntents
import UIKit
import SwiftData

public struct SaveBillIntent: AppIntent {
    public static var title: LocalizedStringResource = "Lưu Bill Ngân Hàng"
    public static var description = IntentDescription("Tự động quét OCR và lưu bill chuyển khoản vào app chi tiêu")
    public static var openAppWhenRun: Bool = false

    @Parameter(title: "Ảnh chụp màn hình", description: "Ảnh chụp bill chuyển khoản cần lưu")
    public var screenshot: IntentFile

    public init() {}

    public init(screenshot: IntentFile) {
        self.screenshot = screenshot
    }

    public func perform() async throws -> some ProvidesDialog {
        guard let data = screenshot.data, let image = UIImage(data: data) else {
            return .result(dialog: "Không đọc được dữ liệu ảnh chụp màn hình.")
        }

        // 1. OCR on-device
        let ocrText = try await VisionOCRService.recognizeText(from: image)
        guard !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .result(dialog: "Không tìm thấy nội dung văn bản trên bill.")
        }

        // 2. Parse details
        let parsed = TransactionRegexParser.parse(rawText: ocrText)
        guard let amount = parsed.amount, amount > 0 else {
            return .result(dialog: "Không tìm thấy số tiền hợp lệ trên bill vừa chụp.")
        }

        // 3. Save Image to Sandbox
        let relativePath = try BillStorageManager.shared.saveBillImage(image)

        // 4. Save to SwiftData
        let schema = Schema([Transaction.self, Category.self])
        let container = try ModelContainer(for: schema)
        let context = ModelContext(container)

        let transaction = Transaction(
            amount: amount,
            type: parsed.type,
            date: Date(),
            recipientName: parsed.recipientName,
            bankName: parsed.bankName,
            transactionCode: parsed.transactionCode,
            note: parsed.note,
            billImagePath: relativePath,
            rawOcrText: ocrText
        )
        context.insert(transaction)
        try context.save()

        let formattedAmount = String(format: "%.0f đ", amount)
        let targetName = parsed.recipientName ?? "giao dịch"
        return .result(dialog: "Đã lưu bill \(formattedAmount) (\(targetName))")
    }

    /// Helper to format the completion dialog message for display or logging
    public static func formatSuccessDialog(amount: Double, recipientName: String?) -> String {
        let formattedAmount = String(format: "%.0f đ", amount)
        let targetName = recipientName ?? "giao dịch"
        return "Đã lưu bill \(formattedAmount) (\(targetName))"
    }
}
