# iOS Expense Tracker & Bill Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây dựng ứng dụng iOS quản lý chi tiêu cá nhân bằng SwiftUI và SwiftData, tự động lưu biên lai chuyển khoản (bill) theo ngày qua cử chỉ Back Tap và Apple Vision OCR mà không cần mở ứng dụng.

**Architecture:** Ứng dụng gồm kiến trúc module hóa: tầng Data Model (SwiftData), OCR Parsing Engine (Apple Vision + Heuristic Regex), Bill File Storage (App Sandbox), App Intents Extension (xử lý ngầm qua Phím tắt Back Tap), và tầng giao diện SwiftUI (Daily Timeline & Zoomable Bill Viewer).

**Tech Stack:** iOS 17+, Swift 5.9+, SwiftUI, SwiftData, Apple Vision Framework (`VNRecognizeTextRequest`), App Intents Framework, PhotoKit.

## Global Constraints

- Platform: iOS 17.0+ (hỗ trợ SwiftData và App Intents mới nhất).
- Toàn bộ quá trình OCR và lưu trữ phải diễn ra 100% On-device (Offline), không gửi dữ liệu ra máy chủ bên thứ ba.
- Tránh phình to Database: File ảnh bill phải được lưu riêng biệt dưới định dạng JPEG/HEIC trong thư mục Sandbox `Documents/Bills/`, Database chỉ lưu đường dẫn tương đối.
- Tuân thủ quy tắc DRY, YAGNI và TDD: Mỗi module nghiệp vụ đều có Unit Test kiểm thử logic trước khi ghép nối giao diện.

---

### Task 1: Core Models & SwiftData Schema

**Files:**
- Create: `BankingApp/Models/TransactionType.swift`
- Create: `BankingApp/Models/Category.swift`
- Create: `BankingApp/Models/Transaction.swift`
- Test: `BankingAppTests/Models/TransactionModelTests.swift`

**Interfaces:**
- Consumes: None (Root Models).
- Produces: 
  - `enum TransactionType: String, Codable { case expense, income }`
  - `@Model class Category { var id: UUID; var name: String; var icon: String; var colorHex: String; var isDefault: Bool }`
  - `@Model class Transaction { var id: UUID; var amount: Double; var type: TransactionType; var date: Date; var recipientName: String?; var bankName: String?; var transactionCode: String?; var note: String?; var categoryId: UUID?; var billImagePath: String?; var rawOcrText: String?; var createdAt: Date }`

- [ ] **Step 1: Write test for Transaction and Category models initialization and SwiftData schema**

```swift
import XCTest
import SwiftData
@testable import BankingApp

final class TransactionModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Transaction.self, Category.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }

    func testCreateAndFetchTransaction() throws {
        let category = Category(name: "Ăn uống", icon: "fork.knife", colorHex: "#FF9500", isDefault: true)
        modelContext.insert(category)

        let tx = Transaction(
            amount: 150000,
            type: .expense,
            date: Date(),
            recipientName: "NGUYEN VAN A",
            bankName: "Techcombank",
            transactionCode: "FT2632891048",
            note: "An trua phuc long",
            categoryId: category.id,
            billImagePath: "Bills/2026-11/test.jpg",
            rawOcrText: "Chuyen tien thanh cong 150.000 VND"
        )
        modelContext.insert(tx)
        try modelContext.save()

        let descriptor = FetchDescriptor<Transaction>()
        let results = try modelContext.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.amount, 150000)
        XCTAssertEqual(results.first?.type, .expense)
        XCTAssertEqual(results.first?.recipientName, "NGUYEN VAN A")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme BankingApp -only-testing:BankingAppTests/TransactionModelTests`
Expected: FAIL (Cannot find `Transaction`, `Category`, `TransactionType` in scope).

- [ ] **Step 3: Implement Core Models**

Create `BankingApp/Models/TransactionType.swift`:
```swift
import Foundation

public enum TransactionType: String, Codable, CaseIterable {
    case expense = "expense"
    case income = "income"
}
```

Create `BankingApp/Models/Category.swift`:
```swift
import Foundation
import SwiftData

@Model
public final class Category {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var isDefault: Bool

    public init(id: UUID = UUID(), name: String, icon: String, colorHex: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isDefault = isDefault
    }
}
```

Create `BankingApp/Models/Transaction.swift`:
```swift
import Foundation
import SwiftData

@Model
public final class Transaction {
    @Attribute(.unique) public var id: UUID
    public var amount: Double
    public var type: TransactionType
    public var date: Date
    public var recipientName: String?
    public var bankName: String?
    public var transactionCode: String?
    public var note: String?
    public var categoryId: UUID?
    public var billImagePath: String?
    public var rawOcrText: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        date: Date = Date(),
        recipientName: String? = nil,
        bankName: String? = nil,
        transactionCode: String? = nil,
        note: String? = nil,
        categoryId: UUID? = nil,
        billImagePath: String? = nil,
        rawOcrText: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.date = date
        self.recipientName = recipientName
        self.bankName = bankName
        self.transactionCode = transactionCode
        self.note = note
        self.categoryId = categoryId
        self.billImagePath = billImagePath
        self.rawOcrText = rawOcrText
        self.createdAt = createdAt
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme BankingApp -only-testing:BankingAppTests/TransactionModelTests`
Expected: PASS (All assertions succeed).

- [ ] **Step 5: Commit changes**

```bash
git add BankingApp/Models BankingAppTests/Models
git commit -m "feat(models): add SwiftData Transaction, Category, and TransactionType schemas"
```

---

### Task 2: OCR Parser Engine (Heuristic Regex & Banking Extraction)

**Files:**
- Create: `BankingApp/Services/OCR/ParsedBillResult.swift`
- Create: `BankingApp/Services/OCR/TransactionRegexParser.swift`
- Test: `BankingAppTests/Services/TransactionRegexParserTests.swift`

**Interfaces:**
- Consumes: `TransactionType`
- Produces: 
  - `struct ParsedBillResult { var amount: Double?; var type: TransactionType; var recipientName: String?; var bankName: String?; var transactionCode: String?; var note: String?; var rawText: String }`
  - `struct TransactionRegexParser { static func parse(rawText: String) -> ParsedBillResult }`

- [ ] **Step 1: Write unit tests for TransactionRegexParser with sample text from VCB, TCB, MB Bank**

```swift
import XCTest
@testable import BankingApp

final class TransactionRegexParserTests: XCTestCase {
    func testParseTechcombankExpenseBill() {
        let sampleOCR = """
        CHUYỂN TIỀN THÀNH CÔNG
        Techcombank
        150.000 VND
        Người nhận: NGUYEN VAN A
        Tài khoản nhận: 190348291048
        Nội dung: An trua phuc long
        Mã giao dịch: FT2632891048
        Thời gian: 24/11/2026 12:35
        """
        
        let result = TransactionRegexParser.parse(rawText: sampleOCR)
        XCTAssertEqual(result.amount, 150000)
        XCTAssertEqual(result.type, .expense)
        XCTAssertEqual(result.recipientName, "NGUYEN VAN A")
        XCTAssertEqual(result.bankName, "Techcombank")
        XCTAssertEqual(result.transactionCode, "FT2632891048")
        XCTAssertEqual(result.note, "An trua phuc long")
    }

    func testParseVietcombankIncomeBill() {
        let sampleOCR = """
        BIẾN ĐỘNG SỐ DƯ
        Vietcombank
        +500.000 VND
        Từ người gửi: LE THI B
        Nội dung: Hoan tien mua sach
        Mã GD: VCB98341209
        """

        let result = TransactionRegexParser.parse(rawText: sampleOCR)
        XCTAssertEqual(result.amount, 500000)
        XCTAssertEqual(result.type, .income)
        XCTAssertEqual(result.recipientName, "LE THI B")
        XCTAssertEqual(result.bankName, "Vietcombank")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme BankingApp -only-testing:BankingAppTests/TransactionRegexParserTests`
Expected: FAIL (Type `TransactionRegexParser` not found).

- [ ] **Step 3: Implement ParsedBillResult and TransactionRegexParser**

Create `BankingApp/Services/OCR/ParsedBillResult.swift`:
```swift
import Foundation

public struct ParsedBillResult {
    public var amount: Double?
    public var type: TransactionType
    public var recipientName: String?
    public var bankName: String?
    public var transactionCode: String?
    public var note: String?
    public var rawText: String

    public init(
        amount: Double? = nil,
        type: TransactionType = .expense,
        recipientName: String? = nil,
        bankName: String? = nil,
        transactionCode: String? = nil,
        note: String? = nil,
        rawText: String = ""
    ) {
        self.amount = amount
        self.type = type
        self.recipientName = recipientName
        self.bankName = bankName
        self.transactionCode = transactionCode
        self.note = note
        self.rawText = rawText
    }
}
```

Create `BankingApp/Services/OCR/TransactionRegexParser.swift`:
```swift
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme BankingApp -only-testing:BankingAppTests/TransactionRegexParserTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add BankingApp/Services/OCR BankingAppTests/Services
git commit -m "feat(ocr): add ParsedBillResult and TransactionRegexParser with regex extraction"
```

---

### Task 3: Bill Image Storage & Vision OCR Service

**Files:**
- Create: `BankingApp/Services/Storage/BillStorageManager.swift`
- Create: `BankingApp/Services/OCR/VisionOCRService.swift`
- Test: `BankingAppTests/Services/BillStorageManagerTests.swift`

**Interfaces:**
- Consumes: None (Uses UIKit `UIImage` and Vision `VNRecognizeTextRequest`).
- Produces:
  - `class BillStorageManager { static let shared; func saveBillImage(_ image: UIImage) throws -> String; func loadBillImage(relativePath: String) -> UIImage?; func deleteBillImage(relativePath: String) }`
  - `class VisionOCRService { static func recognizeText(from image: UIImage) async throws -> String }`

- [ ] **Step 1: Write test for BillStorageManager**

```swift
import XCTest
import UIKit
@testable import BankingApp

final class BillStorageManagerTests: XCTestCase {
    func testSaveAndRetrieveBillImage() throws {
        let storage = BillStorageManager(baseDirectory: FileManager.default.temporaryDirectory)
        let sampleImage = UIImage(systemName: "checkmark.seal.fill") ?? UIImage()
        
        let relativePath = try storage.saveBillImage(sampleImage)
        XCTAssertFalse(relativePath.isEmpty)
        
        let loaded = storage.loadBillImage(relativePath: relativePath)
        XCTAssertNotNil(loaded)
        
        storage.deleteBillImage(relativePath: relativePath)
        XCTAssertNil(storage.loadBillImage(relativePath: relativePath))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme BankingApp -only-testing:BankingAppTests/BillStorageManagerTests`
Expected: FAIL (`BillStorageManager` not found).

- [ ] **Step 3: Implement BillStorageManager and VisionOCRService**

Create `BankingApp/Services/Storage/BillStorageManager.swift`:
```swift
import Foundation
import UIKit

public final class BillStorageManager {
    public static let shared = BillStorageManager()
    private let baseDirectory: URL

    public init(baseDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
        self.baseDirectory = baseDirectory
    }

    public func saveBillImage(_ image: UIImage) throws -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let folderName = dateFormatter.string(from: Date())
        
        let folderURL = baseDirectory.appendingPathComponent("Bills").appendingPathComponent(folderName)
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        let fileName = "bill_\(UUID().uuidString).jpg"
        let fileURL = folderURL.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "BillStorageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        try data.write(to: fileURL)
        return "Bills/\(folderName)/\(fileName)"
    }

    public func loadBillImage(relativePath: String) -> UIImage? {
        let fileURL = baseDirectory.appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }

    public func deleteBillImage(relativePath: String) {
        let fileURL = baseDirectory.appendingPathComponent(relativePath)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
```

Create `BankingApp/Services/OCR/VisionOCRService.swift`:
```swift
import Foundation
import UIKit
import Vision

public final class VisionOCRService {
    public static func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "VisionOCRError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid CGImage"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["vi-VN", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme BankingApp -only-testing:BankingAppTests/BillStorageManagerTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add BankingApp/Services/Storage BankingApp/Services/OCR BankingAppTests/Services
git commit -m "feat(storage,ocr): implement BillStorageManager and on-device VisionOCRService"
```

---

### Task 4: App Intent & Background Shortcuts Handler

**Files:**
- Create: `BankingApp/Intents/SaveBillIntent.swift`
- Create: `BankingApp/Intents/BankingShortcutsProvider.swift`
- Test: `BankingAppTests/Intents/SaveBillIntentTests.swift`

**Interfaces:**
- Consumes: `VisionOCRService`, `TransactionRegexParser`, `BillStorageManager`, `Transaction`
- Produces: `struct SaveBillIntent: AppIntent` enabling background screenshot processing from Back Tap.

- [ ] **Step 1: Write unit test simulating SaveBillIntent execution**

```swift
import XCTest
import UIKit
import SwiftData
@testable import BankingApp

final class SaveBillIntentTests: XCTestCase {
    func testProcessBillImageToTransaction() async throws {
        let rawOCR = """
        CHUYỂN TIỀN THÀNH CÔNG
        Techcombank
        120.000 VND
        Người nhận: PHUC LONG TEA
        Nội dung: Tra sua
        """
        let parsed = TransactionRegexParser.parse(rawText: rawOCR)
        XCTAssertEqual(parsed.amount, 120000)
        XCTAssertEqual(parsed.recipientName, "PHUC LONG TEA")
        
        let tx = Transaction(
            amount: parsed.amount ?? 0,
            type: parsed.type,
            recipientName: parsed.recipientName,
            bankName: parsed.bankName,
            note: parsed.note
        )
        XCTAssertEqual(tx.amount, 120000)
    }
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `xcodebuild test -scheme BankingApp -only-testing:BankingAppTests/SaveBillIntentTests`
Expected: PASS.

- [ ] **Step 3: Implement SaveBillIntent and BankingShortcutsProvider**

Create `BankingApp/Intents/SaveBillIntent.swift`:
```swift
import AppIntents
import UIKit
import SwiftData

public struct SaveBillIntent: AppIntent {
    public static var title: LocalizedStringResource = "Lưu Bill Ngân Hàng"
    public static var description = IntentDescription("Tự động quét OCR và lưu bill chuyển khoản vào app chi tiêu")

    @Parameter(title: "Ảnh chụp màn hình", description: "Ảnh chụp bill chuyển khoản cần lưu")
    public var screenshot: IntentFile

    public init() {}

    public init(screenshot: IntentFile) {
        self.screenshot = screenshot
    }

    public func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        guard let data = screenshot.data, let image = UIImage(data: data) else {
            return .result(dialog: "Không đọc được dữ liệu ảnh chụp màn hình.")
        }

        // 1. OCR on-device
        let ocrText = try await VisionOCRService.recognizeText(from: image)
        guard !ocrText.isEmpty else {
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
}
```

Create `BankingApp/Intents/BankingShortcutsProvider.swift`:
```swift
import AppIntents

public struct BankingShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SaveBillIntent(),
            phrases: [
                "Lưu bill với \(.applicationName)",
                "Quét bill \(.applicationName)"
            ],
            shortTitle: "Lưu Bill Ngân Hàng",
            systemImageName: "doc.text.viewfinder"
        )
    }
}
```

- [ ] **Step 4: Commit changes**

```bash
git add BankingApp/Intents BankingAppTests/Intents
git commit -m "feat(intents): implement SaveBillIntent and BankingShortcutsProvider for Back Tap trigger"
```

---

### Task 5: SwiftUI Daily Timeline View & Grouping Logic

**Files:**
- Create: `BankingApp/Views/Components/SummaryCardView.swift`
- Create: `BankingApp/Views/Components/TransactionRowView.swift`
- Create: `BankingApp/Views/Timeline/DailyTimelineView.swift`
- Test: `BankingAppTests/Views/TimelineGroupingTests.swift`

**Interfaces:**
- Consumes: `Transaction`, `TransactionType`, `BillStorageManager`
- Produces: `DailyTimelineView` displaying transactions grouped by day with income/expense summaries.

- [ ] **Step 1: Write unit test for grouping transactions by Calendar day**

```swift
import XCTest
@testable import BankingApp

final class TimelineGroupingTests: XCTestCase {
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
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `xcodebuild test -scheme BankingApp -only-testing:BankingAppTests/TimelineGroupingTests`
Expected: PASS.

- [ ] **Step 3: Implement SummaryCardView, TransactionRowView, and DailyTimelineView**

Create `BankingApp/Views/Components/SummaryCardView.swift`:
```swift
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
                Text("-\(formatCurrency(totalExpense))")
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
                Text("+\(formatCurrency(totalIncome))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value)) đ"
    }
}
```

Create `BankingApp/Views/Components/TransactionRowView.swift`:
```swift
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
                    Text("\(transaction.type == .expense ? "-" : "+")\(Int(transaction.amount)) đ")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(transaction.type == .expense ? .red : .green)
                    
                    if transaction.billImagePath != nil {
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
}
```

Create `BankingApp/Views/Timeline/DailyTimelineView.swift`:
```swift
import SwiftUI
import SwiftData

public struct DailyTimelineView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var selectedTransaction: Transaction?

    public init() {}

    private var groupedTransactions: [(Date, [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { tx in
            calendar.startOfDay(for: tx.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
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
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Hôm nay (\(date.formatted(.dateTime.day().month())))" }
        if calendar.isDateInYesterday(date) { return "Hôm qua (\(date.formatted(.dateTime.day().month())))" }
        return date.formatted(.dateTime.day().month().year())
    }
}
```

- [ ] **Step 4: Commit changes**

```bash
git add BankingApp/Views
git commit -m "feat(ui): implement SummaryCardView, TransactionRowView, and DailyTimelineView"
```

---

### Task 6: SwiftUI Bill Detail & Zoomable Viewer

**Files:**
- Create: `BankingApp/Views/Detail/ZoomableImageView.swift`
- Create: `BankingApp/Views/Detail/BillDetailView.swift`

**Interfaces:**
- Consumes: `Transaction`, `BillStorageManager`
- Produces: `BillDetailView` providing full-resolution bill inspection, zoom/pan gesture, and inline transaction metadata editing.

- [ ] **Step 1: Implement ZoomableImageView and BillDetailView**

Create `BankingApp/Views/Detail/ZoomableImageView.swift`:
```swift
import SwiftUI

public struct ZoomableImageView: View {
    public let image: UIImage
    @State private var scale: CGFloat = 1.0

    public init(image: UIImage) {
        self.image = image
    }

    public var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in scale = max(1.0, min(value, 4.0)) }
                    .onEnded { _ in withAnimation { scale = 1.0 } }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
    }
}
```

Create `BankingApp/Views/Detail/BillDetailView.swift`:
```swift
import SwiftUI

public struct BillDetailView: View {
    @Bindable public var transaction: Transaction
    @Environment(\.dismiss) private var dismiss

    public init(transaction: Transaction) {
        self.transaction = transaction
    }

    public var body: some View {
        NavigationStack {
            Form {
                if let path = transaction.billImagePath,
                   let image = BillStorageManager.shared.loadBillImage(relativePath: path) {
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
                        TextField("Tên", text: Binding(
                            get: { transaction.recipientName ?? "" },
                            set: { transaction.recipientName = $0.isEmpty ? nil : $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Ngân hàng")
                        Spacer()
                        TextField("Ngân hàng", text: Binding(
                            get: { transaction.bankName ?? "" },
                            set: { transaction.bankName = $0.isEmpty ? nil : $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Nội dung")
                        Spacer()
                        TextField("Ghi chú", text: Binding(
                            get: { transaction.note ?? "" },
                            set: { transaction.note = $0.isEmpty ? nil : $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                    }
                }

                if let code = transaction.transactionCode {
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
                    Button("Xong") { dismiss() }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit changes**

```bash
git add BankingApp/Views/Detail
git commit -m "feat(ui): implement ZoomableImageView and BillDetailView with editable metadata"
```

---

### Task 7: Shortcuts Setup Guide View

**Files:**
- Create: `BankingApp/Views/Settings/ShortcutsSetupGuideView.swift`
- Create: `BankingApp/BankingApp.swift` (App Entry Point)

**Interfaces:**
- Consumes: None (Onboarding & Settings).
- Produces: `ShortcutsSetupGuideView` showing 3-step instructions for configuring Back Tap on iPhone.

- [ ] **Step 1: Implement ShortcutsSetupGuideView and App Entry Point**

Create `BankingApp/Views/Settings/ShortcutsSetupGuideView.swift`:
```swift
import SwiftUI

public struct ShortcutsSetupGuideView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.system(size: 64))
                .foregroundStyle(.indigo)
                .padding(.top, 20)

            VStack(spacing: 8) {
                Text("Cài đặt Gõ Mặt Lưng (Back Tap)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Lưu bill tự động chỉ với 2 lần gõ vào lưng máy mà không cần mở app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 16) {
                GuideStepRow(
                    step: "1",
                    title: "Mở Cài Đặt iPhone",
                    subtitle: "Vào Cài đặt > Trợ năng > Cảm ứng."
                )
                GuideStepRow(
                    step: "2",
                    title: "Chọn Chạm vào mặt lưng",
                    subtitle: "Cuộn xuống dưới cùng và chọn Chạm 2 lần (Double Tap)."
                )
                GuideStepRow(
                    step: "3",
                    title: "Gán Phím Tắt",
                    subtitle: "Cuộn đến mục Phím tắt và chọn 'Lưu Bill Ngân Hàng'."
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
        .padding()
        .navigationTitle("Hướng dẫn Phím Tắt")
    }
}

private struct GuideStepRow: View {
    let step: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.indigo)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

Create `BankingApp/BankingApp.swift`:
```swift
import SwiftUI
import SwiftData

@main
struct BankingApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView {
                DailyTimelineView()
                    .tabItem {
                        Label("Sổ ngày", systemImage: "calendar")
                    }

                NavigationStack {
                    ShortcutsSetupGuideView()
                }
                .tabItem {
                    Label("Cài đặt", systemImage: "gearshape")
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
```

- [ ] **Step 2: Commit changes**

```bash
git add BankingApp/Views/Settings BankingApp/BankingApp.swift
git commit -m "feat(app): add ShortcutsSetupGuideView and BankingApp main entry point"
```
