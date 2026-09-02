fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios version_info

```sh
[bundle exec] fastlane ios version_info
```

pubspec.yaml'dan surum bilgisini oku

### ios preflight

```sh
[bundle exec] fastlane ios preflight
```

Surum App Store Connect'te build kabul ediyor mu — BUILD ALMADAN ONCE

### ios build_ipa

```sh
[bundle exec] fastlane ios build_ipa
```

IPA uret (release, prod API)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

IPA'yi TestFlight'a yukle

### ios notes

```sh
[bundle exec] fastlane ios notes
```

TestFlight 'What to Test' notlarini 16 dilde yaz

### ios whatsnew

```sh
[bundle exec] fastlane ios whatsnew
```

App Store 'Yenilikler' metnini tum lokalizasyonlara yaz

### ios ship_beta

```sh
[bundle exec] fastlane ios ship_beta
```

Tam akis: preflight -> IPA build -> TestFlight -> 16 dil not

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
