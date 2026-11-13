import AppKit
import ScreenCaptureKit

enum CaptureError: LocalizedError {
    case noPermission
    var errorDescription: String? {
        "Chưa có quyền Screen Recording. Hãy bật TScreen trong System Settings → Privacy & Security → Screen & System Audio Recording rồi mở lại app."
    }
}

enum ScreenCapturer {
    /// Chụp nguyên một màn hình (độ phân giải Retina). Gọi trước khi mở overlay để "đóng băng"
    /// màn hình, giữ lại các popup/tooltip đang hiện do hover.
    static func capture(_ screen: NSScreen) async throws -> CGImage {
        guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
            throw CaptureError.noPermission
        }
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let f = screen.frame
        let rect = CGRect(x: f.minX, y: primaryHeight - f.maxY, width: f.width, height: f.height)
        return try await SCScreenshotManager.captureImage(in: rect)
    }

    /// Cắt `local` (toạ độ trong màn hình, gốc dưới-trái, đơn vị point) từ ảnh chụp cả màn hình.
    static func crop(_ image: CGImage, screenSize: CGSize, local: CGRect) -> CGImage? {
        let scale = CGFloat(image.width) / screenSize.width
        let rect = CGRect(x: local.minX * scale, y: (screenSize.height - local.maxY) * scale,
                          width: local.width * scale, height: local.height * scale).integral
        return image.cropping(to: rect)
    }
}
