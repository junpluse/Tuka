# Tuka
Reactive P2P messaging in Swift

## Requirements

- Xcode 8.0+
- iOS 9.0+
- Swift 3.0+

## Installation

### Carthage

To integrate `Tuka` into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your `Cartfile`:

```ogdl
github "junpluse/Tuka" "master"
```

### Git submodule

1. Add the Tuka repository as a submodule of your application’s repository.
2. Run `git submodule update --init --recursive` from within the `Tuka` folder.
3. Drag and drop `Tuka.xcodeproj`, `Carthage/Checkouts/ReactiveSwift/ReactiveSwift.xcodeproj` and `Carthage/Checkouts/Result/Result.xcodeproj` into your application’s Xcode project or workspace.
4. On the **General** tab of your application target’s settings, add `Tuka.framework`, `ReactiveSwift.framework` and `Result.framework` to the “Embedded Binaries” section.

## License

Tuka is released under the MIT license. See LICENSE for details.
