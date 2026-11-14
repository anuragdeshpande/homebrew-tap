# Homebrew Tap for Archipelago

Official Homebrew Cask tap for Archipelago — the Universal macOS Notch, Dynamic Island, and Pill surface engine.

## Install

```bash
brew tap anuragdeshpande/tap
brew trust anuragdeshpande/tap
brew install --cask archipelago
```

> **Note:** On Homebrew 7+, third-party taps require `brew trust anuragdeshpande/tap` once before loading casks. Because builds are currently unsigned, Homebrew automatically clears quarantine attributes during postflight (`xattr -cr /Applications/Archipelago.app`).

Or install directly after trusting:

```bash
brew install --cask anuragdeshpande/tap/archipelago
```

## Upgrade

```bash
brew upgrade --cask archipelago
```

Archipelago also includes built-in automatic updates via Sparkle (`Settings -> Updates`).

## Uninstall

```bash
brew uninstall --cask archipelago
```
