# Banking_DTT

Ứng dụng iOS (iOS 17+) quản lý chi tiêu cá nhân và tự động lưu biên lai (bill) chuyển khoản ngân hàng theo ngày.

## Tính năng chính
- **Lưu bill ngầm không cần mở app:** Tích hợp **App Intents** & **Apple Shortcuts** hỗ trợ cử chỉ gõ 2 lần mặt lưng (Back Tap) hoặc nút Action Button để chụp màn hình và lưu giao dịch tự động.
- **Nhận diện OCR 100% On-device:** Sử dụng **Apple Vision Framework (`VNRecognizeTextRequest`)** và bộ bóc tách Regex nhận diện các ngân hàng Việt Nam (Vietcombank, Techcombank, MB Bank, VPBank, ACB, BIDV, TPBank, MoMo...), hoàn toàn offline và bảo mật tuyệt đối.
- **Sổ thu chi theo ngày:** Giao diện **SwiftUI** nhóm giao dịch theo từng ngày kèm tổng kết thu/chi và ảnh bill gốc có thể phóng to/chỉnh sửa thông tin.
- **Lưu trữ tối ưu:** Thông tin giao dịch lưu trong **SwiftData**, ảnh bill nén JPEG lưu riêng trong App Sandbox (`Documents/Bills/YYYY-MM/`).

## Cấu trúc dự án
- `BankingApp/Models/` — Các SwiftData models (`Transaction`, `Category`, `TransactionType`)
- `BankingApp/Services/OCR/` — `VisionOCRService`, `TransactionRegexParser`, `ParsedBillResult`
- `BankingApp/Services/Storage/` — `BillStorageManager`
- `BankingApp/Intents/` — `SaveBillIntent`, `BankingShortcutsProvider`
- `BankingApp/Views/` — Các màn hình SwiftUI (`DailyTimelineView`, `BillDetailView`, `ZoomableImageView`, `ShortcutsSetupGuideView`)
- `BankingApp/Utilities/` — `CurrencyFormatter`
- `BankingAppTests/` — Bộ Unit Tests cho từng module
- `docs/superpowers/` — Tài liệu thiết kế kỹ thuật (Design Spec) và kế hoạch triển khai (Implementation Plan)

## Cách chạy trên máy Mac (Xcode)
1. Tạo một project iOS App mới trên Xcode (Interface: **SwiftUI**, Storage: **SwiftData**, Deployment Target: **iOS 17.0+**).
2. Kéo/thêm toàn bộ thư mục `BankingApp/` vào target chính và `BankingAppTests/` vào target test.
3. Build & Run trên iPhone thật để cài đặt phím tắt Back Tap theo hướng dẫn trong tab **Cài đặt** của ứng dụng.
