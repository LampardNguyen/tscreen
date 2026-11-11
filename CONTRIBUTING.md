# Contributing to TScreen

Thanks for your interest in improving TScreen. Bug reports, feature ideas and pull requests are all welcome.

## Reporting bugs and requesting features

Open an issue using the matching template. For bugs, include your macOS version, the translation engine in use, and the timing line from the viewer (stopwatch button) if the problem is about speed. Please do not include API keys or sensitive screenshots.

Security problems should not go in public issues; see [SECURITY.md](SECURITY.md).

## Development setup

You need macOS 26+, Xcode 27+ and XcodeGen.

```bash
brew install xcodegen
```

```bash
xcodegen generate
```

```bash
xcodebuild -scheme TScreen -destination 'platform=macOS' -derivedDataPath build test
```

The `.xcodeproj` is generated from `project.yml` and is git-ignored. Re-run `xcodegen generate` whenever you add or remove files, and change build settings in `project.yml`, not in Xcode.

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Keep the change focused: one fix or feature per pull request, and no unrelated refactoring or reformatting.
3. Add or update unit tests in `TScreenTests` for logic that can be tested without the screen (colour sampling, text fitting, response parsing, line joining).
4. Make sure the build and tests pass.
5. Describe what changed and how you checked it. For UI changes, add a screenshot.

## Code guidelines

- Swift, SwiftUI for views, AppKit where window-level control is needed.
- Prefer the simplest code that solves the problem; avoid speculative abstractions and options.
- Match the style of the surrounding code.
- A new translation engine should implement the `Translator` protocol in `TScreen/Translate`, be registered in `makeTranslator`, and get its options in `SettingsView`.
- Never log or commit API keys. Secrets belong in the Keychain.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
