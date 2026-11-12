# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## 2026-11-12

- Xoá nút phóng to / thu nhỏ khỏi thanh công cụ viewer (phím ⌘+ / ⌘− vẫn còn).
- Vẽ bốn dấu góc chữ L ở bốn góc viewer để biết có thể kéo đổi kích thước.
- Kéo ở bốn góc viewer để đổi kích thước, luôn giữ tỉ lệ ngang dọc; không resize theo một chiều.
- Thêm `CLAUDE.md` với rule làm việc cho project.
- Thêm `graphify/` gồm `index.md` và 8 note cho các chức năng hiện có.

## [Unreleased]

## [0.1.0]

### Added

- Menu bar app with a global hotkey and drag-to-select region capture
- OCR with Apple Vision, grouped into paragraphs
- Automatic source-language detection
- Translation engines: Apple Translation, Claude, OpenAI
- In-place rendering of translated text with sampled colours and fitted font size
- Borderless viewer with a floating toolbar (toggle, zoom, copy, save, pin)
- Settings window: hotkey, target language, engine, API keys, font
- Per-step timing display
- App icon
