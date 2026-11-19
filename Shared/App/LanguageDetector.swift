import Foundation
import NaturalLanguage

/// Nhận diện ngôn ngữ nguồn của đoạn text OCR (dùng chung macOS/iOS).
func detectLanguage(_ text: String) -> Locale.Language? {
    NLLanguageRecognizer.dominantLanguage(for: text).map { Locale.Language(identifier: $0.rawValue) }
}
