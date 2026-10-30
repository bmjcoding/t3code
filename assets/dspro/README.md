# DevSpace Pro macOS icon

`DevSpacePro.icon` is the editable, layered source. Open it in Apple's Icon Composer.
The DS artwork is vector paths, so no font installation is required. The background
uses Apple's `system-light` and `system-dark` fills, including the native charcoal
gradient. Glass highlights, translucency, shadows, and clear/tinted appearances
are rendered by Apple rather than painted into the artwork.

macOS release packaging points electron-builder at this `.icon` package. With
**full Xcode 26 or newer selected**, electron-builder compiles `Assets.car`, sets
`CFBundleIconName`, and generates the legacy ICNS before signing. The installed
app then follows the system's icon appearance. Changing the app's own theme does
not change the system icon appearance.

Development launchers and DMG volumes use the flattened dark fallback. The
standalone `DevSpacePro.icns` is also a fixed dark icon; applying it through Finder
cannot enable automatic appearance switching. The installed T3 application has
not been modified by these source changes.

To regenerate the six previews and fallback assets on macOS:

```sh
ICON_COMPOSER_TOOL="/Applications/Icon Composer.app/Contents/Executables/ictool" \
  swift assets/dspro/export.swift
```

The current exports were rendered with Apple's Icon Composer 1.2. The fallback
places its full-bleed dark rendition in the classic 824px body / 100px inset on a
1024px canvas, with a small shadow. It is a compatibility export, not the native
pre-Tahoe UI export used by the upstream T3 icon pipeline. Packaged adaptive
icons always come from the layered `.icon` source through Xcode.

Artwork changes belong in `DevSpacePro.icon/Assets/monogram.svg`; appearance and
material changes belong in `DevSpacePro.icon/icon.json`. Re-run the export command
after either changes. Other platform branding is independent of this macOS icon.

References: [Apple Icon Composer](https://developer.apple.com/icon-composer/) and
[electron-builder icon support](https://www.electron.build/v26/docs/features/icons-and-images/).

## Header logo

`header-logo.svg` is a transparent, outlined **DevSpace Pro** lockup for reuse. It uses
`currentColor`, so an inline SVG inherits its surrounding text color. The app's
shared sidebar header spells out **DevSpace Pro** using live theme colors and
the app's font. The desktop app icon retains the compact **DS** monogram.

## Native verification

The layered source was compiled with Xcode 27.0 and verified live in Finder on
macOS 26.6.2 using a separate signed test app. Light, dark, clear light/dark,
tinted light/dark, automatic switching, and custom tint hue/strength changes
rendered correctly without restarting the test app. This was not a full T3
release build; direct Dock verification is still pending.

For an Xcodes CLI installation, select its developer directory when building:

```sh
DEVELOPER_DIR=/Applications/Xcode-27.0.0.app/Contents/Developer \
  vp run dist:desktop:dmg:arm64
```
