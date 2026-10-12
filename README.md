# Focus Up

Focus Up is a native macOS menu-bar app that keeps one app in focus by blurring everything else.

> [!NOTE]
> Early development. See [PLAN.md](PLAN.md) for the roadmap and [CONTEXT.md](CONTEXT.md) for the vocabulary used throughout the code.

## Requirements

- macOS 27 or later
- Xcode 27 to build

## Building

```sh
open FocusUp.xcodeproj
```

The app target is a thin AppKit/SwiftUI layer. All the focus and overlay logic lives in the `FocusCore` package, which can be tested on its own:

```sh
swift test --package-path Packages/FocusCore
swift format lint --strict --recursive FocusUp Packages
```

New source files only need to be added to the `FocusUp/` folder; the project uses a synchronised folder, so there's no need to edit the project file.

## Licence

[MIT](LICENSE)
