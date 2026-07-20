# GitHub Actions iOS Build

Sheldon Drive can be checked on GitHub-hosted macOS runners without owning a MacBook or Mac mini.

## What Works Now

- The workflow at `.github/workflows/ios-build.yml` runs on `macos-26`.
- It checks out the repo, reports the Xcode version, lists available iOS runtimes, and builds the app for a generic iOS Simulator destination.
- The workflow runs automatically on pushes and pull requests, and it can also be started manually from the GitHub Actions tab.

## Local Equivalent

On a Mac with Xcode:

```bash
./scripts/build-for-iphone13-promax.sh
```

To force a specific installed simulator:

```bash
DESTINATION='platform=iOS Simulator,name=iPhone 13 Pro Max' ./scripts/build-for-iphone13-promax.sh
```

## What Still Needs Apple Signing

GitHub Actions can compile the simulator app without code signing. Installing on a real iPhone or distributing through TestFlight still requires Apple signing assets:

- Apple development or distribution certificate.
- Provisioning profile for `com.oreo0727.hermes.sheldondrive`.
- GitHub repository secrets for those signing files.

Use `.github/workflows/testflight.yml` once the Apple account and signing assets are ready. The simulator workflow is intentionally unsigned so it stays free, repeatable, and safe.
