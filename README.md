#GuruMeditation
[![Swift](https://img.shields.io/badge/swift-3-orange.svg?style=flat)](#)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/badge/platform-ios-lightgrey.svg?style=flat)](#)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://opensource.org/licenses/MIT)

[Nostalgic](https://en.wikipedia.org/wiki/Guru_Meditation) error screen for iOS.

<img src="Doc/error_screen.gif" width="320" alt="error"/>
<img src="Doc/warning_screen.gif" width="320" alt="error"/>

## Installation

### Carthage


To install Carthage, run (using Homebrew):

	$ brew update
	$ brew install carthage	

Then add the following line to your `Cartfile`:

	github "alexdrone/GuruMeditation" "master"    


#### CocoaPods
TODO

#### Manually
All the source code is in a single file.

#Usage

```swift

import GuruMeditation

...

// Simple warning message.
Guru.warning("Your error message goes here.")

// Completion when the error screen get dismissed.
Guru.warning("Your error message goes here.") {
	//do something.
}

// Includes the stack trace in the warning screen.
Guru.warning("Your error message goes here.", includeStack: true)

// Crashes the application after the user tap the screen.
Guru.error("Error message.")


``` 