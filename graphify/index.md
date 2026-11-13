# TScreen — bản đồ tri thức (MOC)

App menu bar macOS: nhấn phím tắt → chọn vùng màn hình → chụp → OCR → dịch → vẽ chữ dịch đè lên ảnh → hiện viewer.

## Note

- [[pipeline]] — luồng tổng từ phím tắt tới viewer, đo thời gian từng bước
- [[chup-man-hinh]] — overlay chọn vùng và chụp bằng ScreenCaptureKit
- [[ocr]] — Vision → danh sách `TextBlock`
- [[dich]] — protocol `Translator`, bốn engine Apple / Claude / OpenAI / Custom (tương thích OpenAI)
- [[ve-anh]] — lấy màu nền, màu chữ, co chữ, vẽ bản dịch
- [[viewer]] — cửa sổ ảnh không viền, thanh công cụ nổi, nhiều viewer cùng lúc
- [[cai-dat]] — Settings, UserDefaults, Keychain
- [[build-va-test]] — XcodeGen, lệnh build/test, ký app
