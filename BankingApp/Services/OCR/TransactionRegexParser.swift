import Foundation

public struct TransactionRegexParser {
    public static func parse(rawText: String) -> ParsedBillResult {
        var result = ParsedBillResult(rawText: rawText)
        let lines = rawText.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // 1. Determine Transaction Type
        let lowercasedText = rawText.lowercased()
        if lowercasedText.contains("nhận tiền") || lowercasedText.contains("biến động số dư") || rawText.contains("+") || lowercasedText.contains("cộng tiền") {
            result.type = .income
        } else {
            result.type = .expense
        }

        // 2. Extract Amount
        let amountPattern = #"(?:[+-]?\s*)(\d{1,3}(?:[.,]\d{3})*|\d+)\s*(?:VND|VNĐ|đ|d|dong)\b"#
        if let regex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: rawText, range: NSRange(rawText.startIndex..., in: rawText)) {
            if let range = Range(match.range(at: 1), in: rawText) {
                let amountStr = String(rawText[range])
                    .replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: "")
                result.amount = Double(amountStr)
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
        let recipientPrefixes = ["người nhận:", "người thụ hưởng:", "tên người nhận:", "từ người gửi:", "đến:"]
        for line in lines {
            let lower = line.lowercased()
            for prefix in recipientPrefixes {
                if lower.hasPrefix(prefix) {
                    let name = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        result.recipientName = name
                        break
                    }
                }
            }
            if result.recipientName != nil { break }
        }

        // 5. Extract Note
        let notePrefixes = ["nội dung:", "lời nhắn:", "ghi chú:"]
        for line in lines {
            let lower = line.lowercased()
            for prefix in notePrefixes {
                if lower.hasPrefix(prefix) {
                    let note = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !note.isEmpty {
                        result.note = note
                        break
                    }
                }
            }
            if result.note != nil { break }
        }

        // 6. Extract Transaction Code
        let codePrefixes = ["mã giao dịch:", "mã gd:", "ref no:"]
        for line in lines {
            let lower = line.lowercased()
            for prefix in codePrefixes {
                if lower.hasPrefix(prefix) {
                    let code = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !code.isEmpty {
                        result.transactionCode = code
                        break
                    }
                }
            }
            if result.transactionCode != nil { break }
        }

        return result
    }
}
