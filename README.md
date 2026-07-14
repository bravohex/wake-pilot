# StayActive Menu Bar for macOS

Ứng dụng menu bar native dành cho macOS 13 trở lên.

## Chức năng

- Hiển thị icon và trạng thái trên macOS menu bar.
- Bật/tắt nhanh mà không cần mở Terminal.
- Chống system idle sleep bằng IOKit power assertion.
- Tùy chọn giữ màn hình sáng.
- Tùy chọn phát presence heartbeat sau khi máy thực sự idle.
- Chọn chu kỳ 1, 2, 3, 4, 5, 10 hoặc 15 phút.
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
~/Applications/StayActive.app
```

## Cấp quyền Accessibility

Khi bật **Giữ trạng thái chat hoạt động**, macOS sẽ hỏi quyền Accessibility.

Có thể mở thủ công tại:

```text
System Settings
→ Privacy & Security
→ Accessibility
→ StayActive
```

Sau khi cấp quyền, bấm lại icon menu bar để ứng dụng cập nhật trạng thái.

## Build nhưng chưa cài

```bash
./build-app.sh
open dist/StayActive.app
```

## Mở source trong Xcode

```bash
open Package.swift
```

## Gỡ cài đặt

Trước tiên tắt **Mở StayActive khi đăng nhập** trong Settings, sau đó:

```bash
./uninstall.sh
```

## Cơ chế kỹ thuật

- `MenuBarExtra` và `Settings` của SwiftUI.
- `IOPMAssertionCreateWithName` để ngăn idle sleep.
- `CGEvent` phát một lần nhấn Shift khi thời gian idle vượt ngưỡng.
- `SMAppService.mainApp` để đăng ký Launch at Login.
- `LSUIElement=true`, vì vậy app không tạo icon thường trực trên Dock.

## Giới hạn

- Presence heartbeat không đảm bảo Teams, Slack hoặc mọi ứng dụng chat luôn hiển thị Online.
- Tính năng presence cần Accessibility.
- App không vượt qua lock screen, MDM hoặc chính sách bảo mật của tổ chức.
- Bản build mặc định ký ad-hoc và phù hợp cho sử dụng cục bộ trên máy của bạn.

## Ký bản phân phối

Bản build ad-hoc không vượt qua Gatekeeper trên máy khác và chữ ký có thể thay đổi sau mỗi lần build. Để giữ quyền Accessibility ổn định và phân phối an toàn, dùng chứng chỉ Developer ID Application:

```bash
STAYACTIVE_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
    ./build-app.sh
```

Trước khi phát hành, app vẫn cần được notarize và staple bằng quy trình của Apple.
