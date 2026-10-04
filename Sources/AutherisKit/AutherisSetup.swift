import Foundation

/// One two-factor code your app wants the user to add to an authenticator.
///
/// Build it from the values your server generated when the user turned on
/// two-factor authentication, then hand it to `AddToAutherisButton` or open
/// `autherisURL` yourself.
///
/// Autheris never adds a code from a link on its own. Since 2.8 it shows what the
/// link would add — waiting behind App Lock if that is on — and adds it only when
/// the user taps Import. So a link can't plant a code without the user seeing it,
/// but it does mean the label and account you set here are what the user reviews:
/// make them recognisable.
public struct AutherisSetup: Hashable, Sendable {
    public enum Algorithm: String, Hashable, Sendable {
        case sha1 = "SHA1", sha256 = "SHA256", sha512 = "SHA512"
    }

    /// Your service's name, as the user knows it. Shown as the code's title.
    public var issuer: String
    /// Who the code is for, usually an email address or username.
    public var account: String
    /// The shared secret, Base32-encoded. Spaces, dashes, lowercase and `=`
    /// padding are tidied away.
    public var secret: String
    public var algorithm: Algorithm
    public var digits: Int
    public var period: Int

    public init(
        issuer: String,
        account: String,
        secret: String,
        algorithm: Algorithm = .sha1,
        digits: Int = 6,
        period: Int = 30
    ) {
        self.issuer = issuer
        self.account = account
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
    }

    /// Why a setup can't be turned into a link.
    public enum Problem: Error, Equatable, Sendable {
        case emptyIssuer
        case invalidSecret
        case unsupportedDigits(Int)
        case unsupportedPeriod(Int)
    }

    /// The secret as it goes into the link: uppercase Base32, no separators.
    var normalizedSecret: String {
        secret.uppercased().filter { !" -=".contains($0) }
    }

    /// Checks the setup against what authenticator apps accept, so a mistake
    /// shows up in your app rather than as an error in Autheris.
    public func validate() throws(Problem) {
        if issuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { throw .emptyIssuer }
        let secret = normalizedSecret
        let base32 = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        // 16 characters is 80 bits, the RFC 4226 minimum.
        guard secret.count >= 16, secret.allSatisfy(base32.contains) else { throw .invalidSecret }
        guard (6...8).contains(digits) else { throw .unsupportedDigits(digits) }
        guard (1...300).contains(period) else { throw .unsupportedPeriod(period) }
    }

    /// The standard `otpauth://totp/…` setup link, which any authenticator app
    /// reads. Also what to put in a QR code for users on another device.
    public func otpauthURL() throws(Problem) -> URL {
        try validate()
        let issuer = Self.encode(issuer)
        let label = account.isEmpty ? issuer : "\(issuer):\(Self.encode(account))"
        var query = [
            "secret=\(normalizedSecret)",
            "issuer=\(issuer)",
        ]
        if algorithm != .sha1 { query.append("algorithm=\(algorithm.rawValue)") }
        if digits != 6 { query.append("digits=\(digits)") }
        if period != 30 { query.append("period=\(period)") }
        // Every part is already percent-encoded, so this can't fail.
        return URL(string: "otpauth://totp/\(label)?\(query.joined(separator: "&"))")!
    }

    /// `autheris://add?uri=<otpauth link>`, which opens Autheris specifically.
    ///
    /// A bare `otpauth://` link goes to whichever authenticator iOS picks for the
    /// scheme; this one always goes to Autheris. Needs Autheris 2.10 or later.
    public func autherisURL() throws(Problem) -> URL {
        let inner = try otpauthURL().absoluteString
        return URL(string: "autheris://add?uri=\(Self.encode(inner))")!
    }

    /// Percent-encodes everything but RFC 3986's unreserved characters, so `&`,
    /// `=`, `:` and `?` in a name or in the nested link survive the trip.
    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    static func encode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: unreserved) ?? string
    }
}
