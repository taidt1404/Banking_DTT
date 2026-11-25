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

## Cách cài trực tiếp trên iPhone bằng SideStore (Không cần máy tính sau lần đầu)
Repo tự động xuất file `BankingDTT-unsigned.ipa` tại mục **Releases** sau mỗi lần build:
1. **Cài SideStore lần đầu từ Windows (1 lần duy nhất):**
   - Trên Windows: cài **iTunes** (bản tải trực tiếp từ apple.com, không dùng bản Microsoft Store) và tải công cụ **iloader** từ trang chủ [docs.sidestore.io](https://docs.sidestore.io).
   - Trên iPhone: tải **LocalDevVPN** từ App Store, mở lên và bấm **Connect**.
   - Cắm cáp iPhone vào Windows → mở **iloader**, đăng nhập Apple ID → chọn **Install SideStore**.
   - Trên iPhone: vào **Cài đặt → Cài đặt chung → Quản lý VPN & Thiết bị → Tin cậy** Apple ID, bật **Chế độ nhà phát triển (Developer Mode)** trong *Quyền riêng tư & Bảo mật*, rồi mở SideStore bấm làm mới (`7 DAYS`) lần đầu khi đang bật LocalDevVPN + Wi-Fi.
2. **Tải và cài `BankingDTT` trực tiếp ngay trên iPhone:**
   - Mở Safari trên iPhone vào link tải trực tiếp: `https://github.com/taidt1404/Banking_DTT/releases/latest/download/BankingDTT-unsigned.ipa`
   - Sau khi tải về mục **Tệp (Files)**, mở **SideStore** (đảm bảo đã bật **LocalDevVPN** + **Wi-Fi**) → tab **My Apps** → bấm dấu **`+`** → chọn file `BankingDTT-unsigned.ipa` vừa tải để cài đặt!

## Cách cài đặt Phím tắt Gõ Mặt Lưng (Back Tap)
1. Mở ứng dụng **Phím tắt (Shortcuts)** trên iPhone → tạo Phím tắt mới (ví dụ: `"Chụp & Lưu Bill"`) gồm 2 bước:
   - **Chụp ảnh màn hình** (*Take Screenshot*)
   - **Lưu Bill Ngân Hàng** (chọn từ app `Banking DTT`, truyền đầu vào là ảnh vừa chụp).
2. Vào **Cài đặt iPhone → Trợ năng → Cảm ứng → Chạm vào mặt lưng → Chạm 2 lần** → chọn phím tắt vừa tạo.

## Cách chạy trực tiếp trên máy Mac (Xcode)
1. Cài `xcodegen` (`brew install xcodegen`) và chạy `xcodegen generate` tại thư mục gốc để sinh `BankingDTT.xcodeproj`.
2. Mở `BankingDTT.xcodeproj` bằng Xcode → chọn Apple ID cá nhân ở mục **Signing & Capabilities** → bấm **Run (`Cmd + R`)** lên iPhone.
