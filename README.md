# BinerMention AIO

BinerMention is a dark, blue-accented social network inspired by the interaction patterns of X. The repository is organized into three independent applications:

- `web/` — web client
- `android/` — Flutter Android client source
- `PHP-API/` — PHP API intended for deployment at `https://binercraft.ir/mention-api-pub/`

## Android build

The GitHub Actions workflow at `.github/workflows/android-apk.yml` creates a Flutter Android scaffold, injects the tracked Flutter source, builds a release APK, and uploads it as an Actions artifact. The initial build is unsigned for testing; configure signing secrets before distributing a production release.

## Backend

Set the API base URL to `https://binercraft.ir/mention-api-pub`. Deploy the contents of `PHP-API/` to the matching cPanel document root. Review `PHP-API/README.md` before deployment and configure database credentials outside version control.

## Current status

This repository was empty when bootstrapping began. The first milestone establishes the project layout and Android UI foundation. Features requiring persistent accounts, posts, media, follows, and notifications need the deployed API and database configured.

## Android interaction updates

- Multi-part Threads can be composed from the post composer (up to 10 segments); each continuation is stored as a reply to the root post so the complete sequence is available from the root's replies.
- Like and repost actions now confirm the requested active state from the API before finalizing the UI state.
- The selected accent color is reactive across the app shell, feed, profile and shared UI components; Material primary/secondary colors use the saved accent preference.
