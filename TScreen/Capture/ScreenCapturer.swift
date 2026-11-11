import AppKit
import ScreenCaptureKit

enum CaptureError: LocalizedError {
    case noPermission
    var errorDescription: String? {
        "Chưa có quyền Screen Recording. Hãy bật TScreen trong System Settings → Privacy & Security → Screen & System Audio Recording rồi mở lại app."
    }
}

enum ScreenCapturer {
    /// `region` theo toạ độ màn hình AppKit (gốc dưới-trái của màn hình chính).
    static func capture(_ region: CGRect) async throws -> CGImage {
        guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
            throw CaptureError.noPermission
        }
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let rect = CGRect(x: region.minX, y: primaryHeight - region.maxY, width: region.width, height: region.height)
        return try await SCScreenshotManager.captureImage(in: rect)
    }
}
