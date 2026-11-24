# Thiết Kế Kỹ Thuật: Ứng Dụng Quản Lý Chi Tiêu & Lưu Trữ Bill Giao Dịch (iOS)

- **Ngày tạo:** 2026-11-24
- **Nền tảng:** iOS (iPhone)
- **Đối tượng:** Cá nhân sử dụng
- **Trạng thái:** Bản thiết kế đã phê duyệt (Approved)

---

## 1. Tổng Quan & Mục Tiêu

Ứng dụng giúp tự động hóa việc ghi nhận chi tiêu và lưu trữ biên lai (bill) giao dịch ngân hàng phát sinh trong ngày:
- **Tự động lưu ngầm không cần mở app:** Khi chuyển khoản hoặc nhận tiền, người dùng chỉ cần **gõ 2 lần vào mặt lưng iPhone (Back Tap)** (hoặc dùng nút Action Button). Điện thoại tự động chụp màn hình, chạy tiến trình ngầm nhận diện OCR, bóc tách dữ liệu và lưu ảnh bill vào ứng dụng.
- **Quản lý theo ngày:** Hiển thị sổ thu chi phân theo từng ngày (Hôm nay, Hôm qua...), mỗi giao dịch gắn liền với ảnh bill gốc để đối soát khi cần.
- **Bảo mật & Riêng tư tuyệt đối 100%:** Xử lý OCR và lưu trữ dữ liệu hoàn toàn ngoại tuyến (On-device/Offline), không gửi ảnh hay dữ liệu tài khoản ra bất kỳ máy chủ bên thứ ba nào.

---

## 2. Công Nghệ & Kiến Trúc (Tech Stack)

| Thành phần | Công nghệ lựa chọn | Mục đích & Lý do |
| :--- | :--- | :--- |
| **Giao diện (UI)** | **SwiftUI** | Giao diện hiện đại, mượt mà chuẩn iOS, hỗ trợ dark mode tự động. |
| **Cơ sở dữ liệu** | **SwiftData** (hoặc SQLite) | Lưu trữ thông tin giao dịch cục bộ, hiệu năng cao, tích hợp sâu với SwiftUI. |
| **Nhận diện chữ (OCR)** | **Apple Vision Framework** (`VNRecognizeTextRequest`) | Chạy trên Apple Neural Engine cục bộ, nhận diện tiếng Việt và số cực nhanh (0.2s), bảo mật 100%. |
| **Kích hoạt ngầm** | **App Intents Framework** | Cung cấp Action cho **Apple Shortcuts**, cho phép app chạy ngầm bóc tách ảnh và lưu dữ liệu mà không cần bật app. |
| **Xử lý ảnh & Thư viện** | **PhotoKit** (`PHPhotoLibrary`) | Quản lý album ảnh, hỗ trợ quét bù các ảnh bill có sẵn trong máy. |
| **Lưu trữ file ảnh** | **App Sandbox File System** | Lưu ảnh bill dạng file JPEG/HEIC trong thư mục `Documents/Bills/` để database không bị phình to. |

---

## 3. Quy Trình Hoạt Động (Data Flow)

### 3.1. Luồng Gõ Mặt Lưng (Back Tap - Luồng chính)
1. **Người dùng:** Chuyển khoản hoặc nhận tiền xong, màn hình hiện thông báo/bill -> Gõ 2 lần vào lưng iPhone.
2. **Apple Shortcuts:** Nhận tín hiệu Back Tap -> Chụp màn hình hiện tại -> Chuyển ảnh cho **App Intent** của ứng dụng.
3. **Background Intent Execution:**
   - App nhận ảnh dưới dạng `UIImage`.
   - Gọi Apple Vision Framework `VNRecognizeTextRequest` để lấy toàn bộ chuỗi ký tự trên màn hình.
   - Chạy bộ bóc tách thông minh (`TransactionRegexParser`):
     - **Số tiền:** Lấy số tiền và định dạng (ví dụ: `150.000 VND`).
     - **Loại giao dịch:** Nhận diện là Chi tiêu (tiền ra) hoặc Thu nhập (tiền vào) dựa trên các từ khóa (Chuyển thành công, Người nhận vs. Nhận tiền, Biến động số dư).
     - **Người nhận / Thụ hưởng:** Trích xuất tên người nhận/ngân hàng.
     - **Thời gian:** Ngày giờ giao dịch (hoặc lấy giờ hiện tại).
     - **Nội dung:** Lời nhắn chuyển khoản.
   - Lưu ảnh vào `Documents/Bills/YYYY-MM/bill_<id>.jpg`.
   - Tạo bản ghi `Transaction` và lưu vào SwiftData.
4. **Thông báo hoàn tất:** Hiển thị thông báo banner trên đỉnh màn hình: *"Đã lưu bill: [Số tiền] - [Người nhận]"*.

### 3.2. Luồng Mở App Tự Quét Bù (Fallback Flow)
- Khi người dùng mở app chính, `PhotoKitSyncService` sẽ kiểm tra trong album Screenshots xem có ảnh bill nào mới chụp trong vòng 10 phút gần nhất mà chưa từng được lưu không.
- Nếu có, hiển thị 1 dialog nhanh: *"Phát hiện bill mới, bạn có muốn lưu?"* để người dùng bấm lưu trong 1 chạm.

---

## 4. Mô Hình Dữ Liệu (Data Model)

### 4.1. Thực thể `Transaction`
```swift
@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Double               // Số tiền giao dịch (luôn dương)
    var type: TransactionType        // .expense (chi tiêu) hoặc .income (thu nhập)
    var date: Date                   // Ngày giờ giao dịch
    var recipientName: String?       // Tên người nhận hoặc người gửi
    var bankName: String?            // Tên ngân hàng (Techcombank, Vietcombank, v.v.)
    var transactionCode: String?     // Mã giao dịch ngân hàng (nếu có)
    var note: String?                // Lời nhắn / nội dung chuyển tiền
    var categoryId: UUID?            // Danh mục chi tiêu (Ăn uống, Đi lại, Mua sắm...)
    var billImagePath: String?       // Đường dẫn file ảnh chụp bill trong App Sandbox
    var rawOcrText: String?          // Văn bản thô OCR được (phục vụ tìm kiếm)
    var createdAt: Date              // Thời điểm tạo bản ghi
}

enum TransactionType: String, Codable {
    case expense // Chi tiêu (Tiền ra)
    case income  // Thu nhập (Tiền vào)
}
```

### 4.2. Thực thể `Category`
```swift
@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String                 // Tên danh mục (Ăn uống, Tiền nhà, Mua sắm...)
    var icon: String                 // Tên icon SF Symbol hoặc Emoji
    var colorHex: String             // Mã màu nhận diện
    var isDefault: Bool
}
```

---

## 5. Quy Tắc Bóc Tách Dữ Liệu (OCR Parsing Rules)

Bộ bóc tách sử dụng biểu thức chính quy (Regex) và từ khóa mẫu nhận diện các ngân hàng phổ biến tại Việt Nam (Vietcombank, Techcombank, MB Bank, VPBank, ACB, BIDV, Agribank, TPBank, MoMo...):

1. **Nhận diện số tiền:**
   - Pattern: `(?:[+-]?\s*)(\d{1,3}(?:[.,]\d{3})*|\d+)\s*(?:VND|VNĐ|đ|d)`
   - Chuẩn hóa: Loại bỏ dấu chấm/phẩy phân cách hàng nghìn để chuyển về kiểu số thực `Double`.
2. **Nhận diện chiều giao dịch:**
   - **Expense (Chi):** Chứa các từ khóa: *"Chuyển tiền thành công"*, *"Giao dịch thành công"*, *"Người thụ hưởng"*, *"Tài khoản nhận"*, *"Đến tài khoản"*, *"Số tiền chuyển"*.
   - **Income (Thu):** Chứa các từ khóa: *"Nhận tiền thành công"*, *"Biến động số dư"*, *"Cộng tiền"*, *"Từ tài khoản"*, ký hiệu `+`.
3. **Nhận diện người nhận / Ngân hàng:**
   - Regex tìm chuỗi văn bản theo sau các cụm từ: `Người nhận:`, `Tên người thụ hưởng:`, `Đến:`, `Tài khoản đích:`.

---

## 6. Giao Diện Người Dùng & Các Màn Hình

1. **Màn hình chính (Daily Timeline):**
   - Header hiển thị tổng kết tài chính tháng hiện tại (Tổng chi, Tổng thu) và hôm nay.
   - Danh sách giao dịch gom nhóm theo từng ngày: Mỗi ngày hiển thị danh sách các mục chi tiêu kèm số tiền, tên người nhận, danh mục và biểu tượng **BILL thu nhỏ**.
   - Bấm vào biểu tượng BILL hoặc dòng giao dịch để mở màn hình xem chi tiết.
2. **Màn hình Xem chi tiết & Phóng to Bill:**
   - Hiển thị ảnh chụp màn hình bill gốc có thể zoom in/zoom out.
   - Các trường thông tin (Số tiền, Danh mục, Người nhận, Ghi chú) cho phép chỉnh sửa nhanh nếu OCR đọc nhầm.
   - Nút chia sẻ ảnh bill hoặc xuất báo cáo.
3. **Màn hình Hướng dẫn Phím tắt (Shortcuts Guide):**
   - Hướng dẫn cài đặt cử chỉ Back Tap (Gõ 2 lần mặt lưng) tích hợp với Shortcuts của máy.

---

## 7. Xử Lý Ngoại Lệ & Độ Tin Cậy (Error Handling)

- **Ảnh chụp không phải là bill ngân hàng:** Nếu bộ OCR không tìm thấy số tiền hoặc từ khóa ngân hàng hợp lệ, app sẽ không tự động tạo giao dịch rác mà gửi thông báo: *"Không nhận diện được bill giao dịch trong ảnh vừa chụp"*.
- **Tránh trùng lặp bill (Duplicate Detection):** Lưu mã hash của ảnh hoặc kết hợp `[Số tiền + Ngày giờ + Mã giao dịch]` để không lưu trùng khi người dùng gõ mặt lưng nhiều lần cho cùng 1 bill.
- **Người dùng xóa ảnh trong Thư viện ảnh:** Ảnh bill được sao chép riêng vào thư mục nội bộ của app, đảm bảo ảnh gốc trong thư viện có bị xóa thì chứng từ trong app vẫn còn nguyên vẹn.

---

## 8. Kế Hoạch Triển Khai (Next Steps)
- Khởi tạo dự án iOS Xcode với SwiftUI & SwiftData.
- Xây dựng tầng Core Model & Database.
- Xây dựng module OCR Engine với Apple Vision & Regex Parser.
- Tạo App Intent & Phím tắt Shortcuts cho tính năng Back Tap.
- Xây dựng giao diện Timeline, xem ảnh bill và hoàn thiện kiểm thử.
