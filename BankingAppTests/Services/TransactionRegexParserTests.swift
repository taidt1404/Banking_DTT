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
        XCTAssertEqual(result.transactionCode, "VCB98341209")
        XCTAssertEqual(result.note, "Hoan tien mua sach")
    }

    func testParseMBBankExpenseBill() {
        let sampleOCR = """
        GIAO DỊCH THÀNH CÔNG
        MB Bank
        2.500.000 đ
        Người thụ hưởng: TRAN VAN C
        Nội dung: Thanh toan tien phong
        Mã GD: MB123456789
        """

        let result = TransactionRegexParser.parse(rawText: sampleOCR)
        XCTAssertEqual(result.amount, 2500000)
        XCTAssertEqual(result.type, .expense)
        XCTAssertEqual(result.recipientName, "TRAN VAN C")
        XCTAssertEqual(result.bankName, "MB Bank")
        XCTAssertEqual(result.transactionCode, "MB123456789")
        XCTAssertEqual(result.note, "Thanh toan tien phong")
    }

    func testParseEmptyOrUnrecognizedText() {
        let sampleOCR = "Unrecognized document text"
        let result = TransactionRegexParser.parse(rawText: sampleOCR)
        XCTAssertNil(result.amount)
        XCTAssertEqual(result.type, .expense)
        XCTAssertNil(result.recipientName)
        XCTAssertNil(result.bankName)
        XCTAssertNil(result.transactionCode)
        XCTAssertNil(result.note)
        XCTAssertEqual(result.rawText, sampleOCR)
    }
}
