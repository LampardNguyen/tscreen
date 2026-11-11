# TScreen

**Screenshot a region of your Mac screen and see it translated in place.**

TScreen is a small macOS menu bar app. Press a hotkey, drag over any part of the screen, and a floating viewer shows the same image with the text replaced by its translation.

[Tiếng Việt](README.vi.md)

## Features

- Global hotkey (default `⌃⇧T`) and drag-to-select region capture, across multiple displays
- On-device OCR with Apple Vision, grouped into paragraphs (tuned for horizontal Japanese and English)
- Automatic source-language detection
- Three translation engines, switchable in Settings:
  - **Apple Translation**: offline and free
  - **Claude** (Anthropic API)
  - **OpenAI** (Chat Completions API)
- Translated text is drawn over the original: background and text colours are sampled from the image, and the font size is fitted to the original box
- Borderless floating viewer with a separate toolbar: toggle original/translated, zoom, copy image, copy text, save PNG, pin on top
- Per-step timing (capture, OCR, translate, render) to see where time goes

## Requirements

- macOS 26 or later
- Xcode 27 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Build and run

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

The Xcode project is generated from `project.yml` and is not committed. Run `xcodegen generate` again after adding or removing source files.

## First-run setup

1. **Screen Recording permission.** macOS asks on the first capture. Grant it in System Settings → Privacy & Security → Screen & System Audio Recording, then relaunch the app. Because local builds are ad-hoc signed, macOS may ask again after a rebuild.
2. **Apple Translation languages.** Download the languages you need in System Settings → General → Language & Region → Translation Languages.
3. **Claude or OpenAI (optional).** Open Settings from the menu bar icon, pick the engine, and enter your API key and model. Keys are stored in the macOS Keychain.

## Usage

| Action | Shortcut |
|---|---|
| Capture and translate | `⌃⇧T` (configurable) |
| Cancel selection | `Esc` |
| Toggle original / translated | `Space` |
| Zoom in / out | `⌘+` / `⌘−` |
| Copy image | `⌘C` |
| Copy translated text | `⇧⌘C` |
| Save as PNG | `⌘S` |
| Close viewer | `Esc` or `⌘W` |

Drag the image to move the viewer. Pressing the capture hotkey again closes the current viewer first.

## Privacy

- Capture, OCR and Apple Translation run entirely on your Mac.
- With the Claude or OpenAI engine, the recognised **text** (not the image) is sent to that provider's API.
- TScreen has no analytics and no server of its own.

## How it works

```
hotkey → region overlay → ScreenCaptureKit → Vision OCR → language detection
       → translator (Apple / Claude / OpenAI) → Core Graphics + Core Text render → viewer
```

| Folder | Purpose |
|---|---|
| `TScreen/App` | Menu bar app and the pipeline coordinator |
| `TScreen/Capture` | Region selection overlay and screen capture |
| `TScreen/OCR` | Vision document recognition into text blocks |
| `TScreen/Translate` | `Translator` protocol and the three engines |
| `TScreen/Render` | Colour sampling, text fitting, image composition |
| `TScreen/Viewer` | Borderless viewer window and floating toolbar |
| `TScreen/Settings` | Settings window and Keychain helper |
| `TScreenTests` | Unit tests |

All text blocks from one capture are sent to the translator in a single batched request.

## Tests

```bash
xcodebuild -scheme TScreen -destination 'platform=macOS' -derivedDataPath build test
```

## Known limitations

- Vertical text is not handled.
- Text over gradients or photos is covered with a flat sampled colour, not inpainted.
- The app UI is currently in Vietnamese only.
- No signed or notarised release is provided yet; build from source.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md). To report a vulnerability, see [SECURITY.md](SECURITY.md).

## Acknowledgements

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus

## License

[MIT](LICENSE)
