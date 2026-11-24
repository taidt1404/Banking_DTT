import Foundation

public struct TransactionRegexParser {
    private static let amountRegex: NSRegularExpression = {
        let pattern = #"([+-])?\s*(\d{1,3}(?:[.,]\d{3})*|\d+)\s*(?:VND|VNĐ|đ|d|dong|đồng)\b"#
        return try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }()

    public static func parse(rawText: String) -> ParsedBillResult {
        var result = ParsedBillResult(rawText: rawText)
        let lines = rawText.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // 1. Extract Amount and Scoped Sign (+ or - directly preceding amount)
        var amountSign: String? = nil
        if let match = amountRegex.firstMatch(in: rawText, range: NSRange(rawText.startIndex..., in: rawText)) {
            if match.range(at: 1).location != NSNotFound,
               let signRange = Range(match.range(at: 1), in: rawText) {
                amountSign = String(rawText[signRange])
            }
            if let range = Range(match.range(at: 2), in: rawText) {
                let amountStr = String(rawText[range])
                    .replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: "")
                result.amount = Double(amountStr)
            }
        }

        // 2. Determine Transaction Type
        let lowercasedText = rawText.lowercased()
        if amountSign == "+" {
            result.type = .income
        } else if amountSign == "-" {
            result.type = .expense
        } else {
            let incomeKeywords = [
                "nhận tiền", "nhan tien",
                "cộng tiền", "cong tien",
                "từ người gửi", "tu nguoi gui",
                "hoàn tiền", "hoan tien",
                "tiền vào", "tien vao"
            ]
            let expenseKeywords = [
                "chuyển tiền", "chuyen tien",
                "chuyển khoản", "chuyen khoan",
                "thanh toán", "thanh toan",
                "người nhận", "nguoi nhan",
                "người thụ hưởng", "nguoi thu huong",
                "trừ tiền", "tru tien",
                "tiền ra", "tien ra"
            ]

            let hasIncomeKeyword = incomeKeywords.contains { lowercasedText.contains($0) }
            let hasExpenseKeyword = expenseKeywords.contains { lowercasedText.contains($0) }

            if hasIncomeKeyword && !hasExpenseKeyword {
                result.type = .income
            } else {
                result.type = .expense
            }
        }

        // 3. Extract Bank Name
        let knownBanks = ["Techcombank", "Vietcombank", "MB Bank", "VPBank", "ACB", "BIDV", "Agribank", "TPBank", "MoMo", "ZaloPay", "VIB", "Sacombank"]
        for bank in knownBanks {
            if rawText.localizedCaseInsensitiveContains(bank) {
                result.bankName = bank
                break
            }
        }

        // 4. Extract Recipient / Sender Name
        result.recipientName = extractValue(from: lines, prefixes: [
            "người nhận:", "người thụ hưởng:", "tên người nhận:", "từ người gửi:", "đến:"
        ])

        // 5. Extract Note
        result.note = extractValue(from: lines, prefixes: [
            "nội dung:", "lời nhắn:", "ghi chú:"
        ])

        // 6. Extract Transaction Code
        result.transactionCode = extractValue(from: lines, prefixes: [
            "mã giao dịch:", "mã gd:", "ref no:"
        ])

        return result
    }

    /// Helper to extract value following any matching case-insensitive prefix from lines
    public static func extractValue(from lines: [String], prefixes: [String]) -> String? {
        for line in lines {
            let lower = line.lowercased()
            for prefix in prefixes {
                if lower.hasPrefix(prefix) {
                    let value = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !value.isEmpty {
                        return value
                    }
                }
            }
        }
        return nil
    }
}
