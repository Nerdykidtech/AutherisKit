import SwiftUI

/// What happened when the user tapped `AddToAutherisButton`.
public enum AutherisOpenResult: Equatable, Sendable {
    /// Autheris opened and is showing the code for the user to review.
    case openedAutheris
    /// Autheris isn't installed, so the plain `otpauth://` link went to another
    /// authenticator app.
    case openedOtherAuthenticator
    /// No app on the device takes setup links. Show the setup key or a QR code.
    case noAuthenticator
    /// The setup was invalid; nothing was opened.
    case invalidSetup(AutherisSetup.Problem)
}

/// A ready-made "Add to Autheris" button.
///
/// It opens Autheris with the code, falls back to any other authenticator app if
/// Autheris isn't installed, and tells you through `onResult` if neither worked,
/// so you can show the setup key instead. Always ask the user to type a code back
/// before you turn on two-factor authentication: that's the only proof the code
/// was actually saved.
public struct AddToAutherisButton: View {
    private let setup: AutherisSetup
    private let onResult: @MainActor (AutherisOpenResult) -> Void

    @Environment(\.openURL) private var openURL

    public init(
        setup: AutherisSetup,
        onResult: @escaping @MainActor (AutherisOpenResult) -> Void = { _ in }
    ) {
        self.setup = setup
        self.onResult = onResult
    }

    public var body: some View {
        Button {
            AutherisLauncher.open(setup, with: openURL, onResult: onResult)
        } label: {
            Label {
                Text("Add to Autheris")
            } icon: {
                Image(systemName: "lock.shield.fill")
            }
        }
        .accessibilityHint(Text("Opens Autheris to review and save this code"))
    }
}

/// The open-and-fall-back logic behind the button, for apps with their own UI.
public enum AutherisLauncher {
    @MainActor
    public static func open(
        _ setup: AutherisSetup,
        with openURL: OpenURLAction,
        onResult: @escaping @MainActor (AutherisOpenResult) -> Void = { _ in }
    ) {
        let autheris: URL
        let otpauth: URL
        do {
            autheris = try setup.autherisURL()
            otpauth = try setup.otpauthURL()
        } catch {
            onResult(.invalidSetup(error))
            return
        }
        openURL(autheris) { accepted in
            if accepted { return onResult(.openedAutheris) }
            openURL(otpauth) { accepted in
                onResult(accepted ? .openedOtherAuthenticator : .noAuthenticator)
            }
        }
    }
}
