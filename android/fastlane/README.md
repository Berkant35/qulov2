fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android version_info

```sh
[bundle exec] fastlane android version_info
```

pubspec.yaml'dan surum bilgisini oku

### android build_aab

```sh
[bundle exec] fastlane android build_aab
```

AAB uret (release, prod API)

### android sync_changelogs

```sh
[bundle exec] fastlane android sync_changelogs
```

Release notlarini testflight_release_notes.json'dan changelogs/'a uret

### android internal

```sh
[bundle exec] fastlane android internal
```

Internal test track'e yukle (varsayilan gunluk akis)

### android production_draft

```sh
[bundle exec] fastlane android production_draft
```

Production'a taslak olarak YENI aab yukle (henuz hicbir track'te yoksa)

### android promote_to_production

```sh
[bundle exec] fastlane android promote_to_production
```

internal'daki mevcut build'i production'a TASLAK olarak terfi ettir

### android notes_only

```sh
[bundle exec] fastlane android notes_only
```

Sadece release notlarini guncelle (yeni build yuklemeden)

### android ship_internal

```sh
[bundle exec] fastlane android ship_internal
```

Tam akis: notlari uret -> AAB build -> internal track

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
