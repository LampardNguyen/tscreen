# Security Policy

## Supported versions

Only the latest version on the `main` branch receives security fixes.

## Reporting a vulnerability

Please do **not** open a public issue for security problems.

Report privately through GitHub: open the repository's **Security** tab and choose **Report a vulnerability**. Include what you found, how to reproduce it, and the impact you expect.

You can expect an acknowledgement within a week. Once a fix is available, the issue will be disclosed in the changelog, with credit to you if you wish.

## What TScreen handles

- **Screen contents.** Captured images are kept in memory only, unless you save them yourself.
- **API keys.** Claude and OpenAI keys are stored in the macOS Keychain, never in files or logs.
- **Network.** The app only makes network requests when the Claude or OpenAI engine is selected, and it sends only the recognised text to `api.anthropic.com` or `api.openai.com`.
