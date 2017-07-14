![Swift 2.2](https://img.shields.io/badge/Swift-3.0.1-brightgreen.svg?style=plastic)

# Notifying Collection

This project is in its infancy, more documentation will come as it is developed. The goal is an array-like class with a (reactive) signal that sends change notifications with details about what changed. That was pretty easy. The hard part is allowing for nested updates. For example, You could have a collection of Widgets and in addition to being notified when that array is modified, you also get forwarded signals from the widget's parts collection.

This is currently targeted for macOS, but there is and will be no reason it should not work on iOS. We're just not adding support until the macOS version is solid.

## Dependencies

This project requires macOS Sierra. Development is being done with Xcode 9.0b3.

* [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift): the foundation for this project

* [Result](https://github.com/antitypical/Result): used by ReactiveSwift

* [Quick](https://github.com/Quick/Quick) and [Nimble](https://github.com/Quick/Nimble): required to run the unit tests

## Installation Instructions

Run `carthage bootstrap --no-use-binaries --platform Mac` in the project directory. 

## License

ISC License (similar to MIT/2-clause BSD but simplified). See the [LICENSE](LICENSE.md).
