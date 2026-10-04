import Foundation
import Testing
@testable import AutherisKit

struct AutherisSetupTests {
    let setup = AutherisSetup(issuer: "My App", account: "alice@example.com", secret: "jbsw y3dp-ehpk 3pxp")

    @Test func otpauthLinkIsStandard() throws {
        #expect(try setup.otpauthURL().absoluteString
            == "otpauth://totp/My%20App:alice%40example.com?secret=JBSWY3DPEHPK3PXP&issuer=My%20App")
    }

    @Test func nonDefaultParametersAreIncluded() throws {
        var setup = setup
        setup.algorithm = .sha256
        setup.digits = 8
        setup.period = 60
        #expect(try setup.otpauthURL().absoluteString.hasSuffix("&algorithm=SHA256&digits=8&period=60"))
    }

    /// The format Autheris parses: the whole otpauth link in one `uri` item.
    @Test func autherisLinkWrapsTheOTPAuthLink() throws {
        let url = try setup.autherisURL()
        #expect(url.scheme == "autheris")
        #expect(url.host == "add")
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(items.count == 1)
        #expect(items.first?.value == (try setup.otpauthURL().absoluteString))
    }

    /// Autheris's own test suite decodes this exact string; keep the two in step.
    @Test func autherisLinkMatchesTheAppsContractTest() throws {
        #expect(try setup.autherisURL().absoluteString == "autheris://add?uri=otpauth%3A%2F%2Ftotp%2FMy%2520App%3Aalice%2540example.com%3Fsecret%3DJBSWY3DPEHPK3PXP%26issuer%3DMy%2520App")
    }

    @Test func reservedCharactersInNamesSurvive() throws {
        let setup = AutherisSetup(issuer: "A&B=C?", account: "x:y", secret: "JBSWY3DPEHPK3PXP")
        let inner = try #require(URLComponents(url: try setup.autherisURL(), resolvingAgainstBaseURL: false)?.queryItems?.first?.value)
        let items = try #require(URLComponents(string: inner)?.queryItems)
        #expect(items.first { $0.name == "issuer" }?.value == "A&B=C?")
        #expect(items.first { $0.name == "secret" }?.value == "JBSWY3DPEHPK3PXP")
    }

    @Test func invalidSetupsAreRejected() {
        #expect(throws: AutherisSetup.Problem.emptyIssuer) {
            try AutherisSetup(issuer: " ", account: "", secret: "JBSWY3DPEHPK3PXP").validate()
        }
        #expect(throws: AutherisSetup.Problem.invalidSecret) {
            try AutherisSetup(issuer: "X", account: "", secret: "not base32 at all!!").validate()
        }
        #expect(throws: AutherisSetup.Problem.invalidSecret) {
            try AutherisSetup(issuer: "X", account: "", secret: "JBSWY3DP").validate()
        }
        #expect(throws: AutherisSetup.Problem.unsupportedDigits(4)) {
            try AutherisSetup(issuer: "X", account: "", secret: "JBSWY3DPEHPK3PXP", digits: 4).validate()
        }
    }
}
