# AutherisKit

An "Add to Autheris" button for apps that offer two-factor authentication.

When a user turns on 2FA in your app, AutherisKit opens [Autheris](https://autheris.app) with the new code ready to save. If Autheris isn't installed, it hands the standard `otpauth://` link to whatever authenticator app is. If there's none, it tells you, so you can show the setup key instead.

Full guide: **https://autheris.app/developers**

## Is it safe to open Autheris from my app?

Yes. Autheris never adds a code just because a link arrived. Since 2.8 it shows the user what the link would add, waits behind App Lock if that's on, and only saves the code when they tap Import. So the label and account you pass are what the user reviews: make them recognisable.

## Requirements

- iOS 15, macOS 12 or visionOS 1, Swift 6
- The `autheris://add` link needs Autheris 2.10 or later. On older versions the button falls back to `otpauth://`.

## Install

In Xcode: File › Add Package Dependencies…, then enter `https://github.com/Nerdykidtech/AutherisKit`.

Or in `Package.swift`:

```swift
.package(url: "https://github.com/Nerdykidtech/AutherisKit", from: "1.0.0")
```

## Use

```swift
import AutherisKit

let setup = AutherisSetup(
    issuer: "My App",
    account: user.email,
    secret: totpSecretFromYourServer   // Base32
)

AddToAutherisButton(setup: setup) { result in
    switch result {
    case .openedAutheris, .openedOtherAuthenticator:
        break // now ask for a code to confirm
    case .noAuthenticator:
        showSetupKey = true
    case .invalidSetup(let problem):
        assertionFailure("\(problem)")
    }
}
```

Then ask the user to type a code from the app, and verify it on your server before turning 2FA on. That's the only proof the code was saved.

Need your own UI? `setup.autherisURL()` and `setup.otpauthURL()` give you the links, and `AutherisLauncher.open(_:with:onResult:)` does the fallback for any button.

## The link format

```
autheris://add?uri=<percent-encoded otpauth:// link>
```

`uri` is a standard [Key URI Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format) link, encoded so that only `A–Z a–z 0–9 - . _ ~` are left as-is. One code per link. You don't need AutherisKit to build it: any platform can, including a web page.

## Licence

MIT
