# BrHx Wake Pilot for macOS

**BrHx Wake Pilot** là ứng dụng menu bar native dành cho macOS 13 trở lên. Tên ngắn hiển thị trên menu bar là **Wake Pilot**.

## Chức năng

- Hiển thị icon và trạng thái trên macOS menu bar.
- Bật/tắt nhanh mà không cần mở Terminal.
- Chống system idle sleep bằng IOKit power assertion.
- Tùy chọn giữ màn hình sáng.
- Tùy chọn phát presence heartbeat sau khi máy thực sự idle.
- Chọn chu kỳ 1, 2, 3, 4, 5, 10 hoặc 15 phút.
- Lịch hoạt động tùy chọn theo giờ bắt đầu/kết thúc, bao gồm cả lịch qua đêm.
- Hỗ trợ tiếng Việt (mặc định), English và 日本語; có thể đổi ngay trong Settings.
- Settings window.
- Launch at Login bằng `SMAppService`.

## Cài đặt nhanh

Yêu cầu Xcode Command Line Tools hoặc Xcode:

```bash
xcode-select --install
```

Sau đó:

```bash
cd StayActiveMenuBar
chmod +x *.sh
./install.sh
```

Ứng dụng được cài tại:

```text
~/Applications/BrHxWakePilot.app
```

## Cấp quyền Accessibility

Khi bật **Giữ trạng thái chat hoạt động**, macOS sẽ hỏi quyền Accessibility.

Có thể mở thủ công tại:

```text
System Settings
→ Privacy & Security
→ Accessibility
→ BrHx Wake Pilot
```

Sau khi cấp quyền, bấm lại icon menu bar để ứng dụng cập nhật trạng thái.

## Lịch hoạt động

Mặc định, Wake Pilot hoạt động liên tục khi công tắc **Bật Wake Pilot** được bật. Nếu cần giới hạn thời gian, vào **Cài đặt… → Lịch hoạt động**, bật **Chỉ hoạt động theo khung giờ** rồi chọn giờ bắt đầu và kết thúc.

- Khung giờ có thể qua đêm, ví dụ `22:00–06:00`.
- Giờ kết thúc không được tính: lịch `09:00–18:00` sẽ dừng đúng lúc `18:00`.
- Nếu hai giờ giống nhau, lịch được hiểu là cả ngày; tắt tùy chọn lịch để quay lại chế độ luôn hoạt động.

## Build nhưng chưa cài

```bash
./build-app.sh
open dist/BrHxWakePilot.app
```

## Mở source trong Xcode

```bash
open Package.swift
```

## Gỡ cài đặt

Trước tiên tắt **Mở Wake Pilot khi đăng nhập** trong Settings, sau đó:

```bash
./uninstall.sh
```

## Cơ chế kỹ thuật

- `MenuBarExtra` và `Settings` của SwiftUI.
- `IOPMAssertionCreateWithName` để ngăn idle sleep.
- `CGEvent` phát một lần nhấn Shift khi thời gian idle vượt ngưỡng.
- `SMAppService.mainApp` để đăng ký Launch at Login.
- `LSUIElement=true`, vì vậy app không tạo icon thường trực trên Dock.

## Nâng cấp từ StayActive

Phiên bản này dùng Bundle ID mới `com.bravohex.wakepilot`. Lần mở đầu, Wake Pilot tự sao chép các cài đặt hoạt động từ `com.bravohex.StayActive` nếu bạn chưa có cài đặt mới.

Launch at Login không thể được chuyển tự động giữa hai main app có Bundle ID khác nhau. Script cài đặt giữ lại `~/Applications/StayActive.app`; hãy mở app cũ, tắt Launch at Login, rồi mới xóa app cũ.

## Giới hạn

- Presence heartbeat không đảm bảo Teams, Slack hoặc mọi ứng dụng chat luôn hiển thị Online.
- Tính năng presence cần Accessibility.
- App không vượt qua lock screen, MDM hoặc chính sách bảo mật của tổ chức.
- Bản build mặc định ký ad-hoc và phù hợp cho sử dụng cục bộ trên máy của bạn.

## Ký bản phân phối

Bản build ad-hoc không vượt qua Gatekeeper trên máy khác và chữ ký có thể thay đổi sau mỗi lần build. Để giữ quyền Accessibility ổn định và phân phối an toàn, dùng chứng chỉ Developer ID Application:

```bash
BRHX_WAKE_PILOT_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
    ./build-app.sh
```

Trước khi phát hành, app vẫn cần được notarize và staple bằng quy trình của Apple.
