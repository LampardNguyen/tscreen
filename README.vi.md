# TScreen

**Chụp một vùng màn hình Mac và xem ngay bản dịch nằm đúng trên ảnh.**

TScreen là một app nhỏ chạy trên thanh menu của macOS. Nhấn phím tắt, kéo chọn một vùng bất kỳ, và một cửa sổ nổi sẽ hiện lại tấm ảnh đó với chữ đã được thay bằng bản dịch.

[English](README.md)

## Tính năng

- Phím tắt toàn cục (mặc định `⌃⇧T`), kéo để chọn vùng, hỗ trợ nhiều màn hình
- OCR chạy trên máy bằng Apple Vision, gom dòng thành đoạn (tối ưu cho tiếng Nhật và tiếng Anh chữ ngang)
- Tự nhận diện ngôn ngữ nguồn
- Ba engine dịch, đổi trong Cài đặt:
  - **Apple Translation**: offline, miễn phí
  - **Claude** (Anthropic API)
  - **OpenAI** (Chat Completions API)
- Chữ dịch được vẽ đè lên chữ gốc: màu nền và màu chữ lấy từ ảnh, cỡ chữ tự co cho vừa khung
- Viewer không viền kèm thanh công cụ riêng: xem gốc/dịch, phóng to thu nhỏ, sao chép ảnh, sao chép chữ, lưu PNG, ghim trên cùng
- Đo thời gian từng bước (chụp, OCR, dịch, vẽ)

## Yêu cầu

- macOS 26 trở lên
- Xcode 27 trở lên
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Build và chạy

```bash
brew install xcodegen
```

```bash
xcodegen generate
```

```bash
xcodebuild -scheme TScreen -destination 'platform=macOS' -derivedDataPath build build
```

```bash
open build/Build/Products/Debug/TScreen.app
```

Project Xcode được sinh từ `project.yml` và không được commit. Sau khi thêm hoặc xoá file nguồn, chạy lại `xcodegen generate`.

## Thiết lập lần đầu

1. **Quyền Screen Recording.** macOS sẽ hỏi ở lần chụp đầu tiên. Cấp quyền trong System Settings → Privacy & Security → Screen & System Audio Recording rồi mở lại app. Bản build cục bộ được ký ad-hoc nên macOS có thể hỏi lại sau mỗi lần build.
2. **Gói ngôn ngữ Apple Translation.** Tải các ngôn ngữ cần dùng trong System Settings → General → Language & Region → Translation Languages.
3. **Claude hoặc OpenAI (tuỳ chọn).** Mở Cài đặt từ icon trên thanh menu, chọn engine, nhập API key và model. Key được lưu trong Keychain của macOS.

## Cách dùng

| Thao tác | Phím tắt |
|---|---|
| Chụp và dịch | `⌃⇧T` (đổi được) |
| Huỷ chọn vùng | `Esc` |
| Xem ảnh gốc / bản dịch | `Space` |
| Phóng to / thu nhỏ | `⌘+` / `⌘−` |
| Sao chép ảnh | `⌘C` |
| Sao chép chữ dịch | `⇧⌘C` |
| Lưu PNG | `⌘S` |
| Đóng viewer | `Esc` hoặc `⌘W` |

Kéo tấm ảnh để di chuyển viewer. Nhấn phím tắt chụp lần nữa sẽ đóng viewer hiện tại trước.

## Quyền riêng tư

- Chụp, OCR và Apple Translation chạy hoàn toàn trên máy bạn.
- Với engine Claude hoặc OpenAI, phần **chữ** đã nhận diện (không phải ảnh) được gửi tới API của nhà cung cấp đó.
- TScreen không có analytics và không có máy chủ riêng.

## Hạn chế hiện tại

- Chưa xử lý chữ dọc.
- Chữ nằm trên nền gradient hoặc ảnh được che bằng một màu phẳng, chưa inpaint.
- Giao diện app hiện chỉ có tiếng Việt.
- Chưa có bản phát hành đã ký và notarize; cần build từ mã nguồn.

## Đóng góp

Xem [CONTRIBUTING.md](CONTRIBUTING.md), [Code of Conduct](CODE_OF_CONDUCT.md) và [SECURITY.md](SECURITY.md).

## Giấy phép

[MIT](LICENSE)
