import Foundation
import PerfectHTTP
import PerfectLib

public protocol SessionProtocol {
	var cookieIDName:String { get set }
	var domain:String? { get set }
	var expiration: PerfectHTTP.HTTPCookie.Expiration? { get set}
	var path:String? { get set }
	var secure:Bool? { get set }
	var httpOnly: Bool? { get set }
	var sameSite: PerfectHTTP.HTTPCookie.SameSite? { get set }

	//init(cookieName cookieIDName: String)

	func setCookieAttributes(domain:String?, expiration: PerfectHTTP.HTTPCookie.Expiration?, path:String?, secure:Bool?, httpOnly: Bool?, sameSite: PerfectHTTP.HTTPCookie.SameSite? )

	func start(_ request:HTTPRequest, response:HTTPResponse, expiration: PerfectHTTP.HTTPCookie.Expiration?) -> Session
	func save(_ session:Session, response: HTTPResponse)
	func destroy(_ response:HTTPResponse, cookieID: String)
}

extension SessionProtocol {
	func createCookie(cookieID:String, newExpiration: PerfectHTTP.HTTPCookie.Expiration?) -> PerfectHTTP.HTTPCookie {
		return PerfectHTTP.HTTPCookie(
			name: cookieIDName,
			value: cookieID,
			domain: domain,
			expires: newExpiration ?? expiration,
			path: path,
			secure: secure,
			httpOnly: httpOnly,
			sameSite: sameSite
		)
	}

	func checkSecurity(secure:Bool? = nil, httpOnly: Bool? = nil, sameSite: PerfectHTTP.HTTPCookie.SameSite? = nil) {
		if let val = secure {
			if !val {
				Log.error(message: "Do you want to use a cookie session without SSL?, really?, hackers are welcome!\n\t Please, you MUST read this: https://www.owasp.org/index.php/SecureFlag")
			}
		}

		if let val = httpOnly {
			if !val {
				Log.warning(message: "Do you really want to allow access to session cookie from Javascript?, allowing this you disable the first countermeasure against XSS attack.\n - Please, read: https://www.owasp.org/index.php/HttpOnly#Mitigating_the_Most_Common_XSS_attack_using_HttpOnly")
			}
		}

		if let val = sameSite {
			if val == .lax {
				Log.warning(message: "Same site cookie disables third-party usage of your cookies, this help you to prevent CSRF attacks but you have disabled this funtionality.\n\tPlease, read: https://www.owasp.org/index.php/SameSite")
			}
		}


	}

}

public class Session {
	private let sessionManager: SessionProtocol
	private let expiration:PerfectHTTP.HTTPCookie.Expiration

	private let dateFormatter = DateFormatterRFC2616()
	private let cookieID:String

	private var data = Dictionary<String, Any>()
	private var timeExpires:Date = Date()

	public init(sessionManager:SessionProtocol, expiration:PerfectHTTP.HTTPCookie.Expiration) {
		self.sessionManager = sessionManager
		self.cookieID = tokenGenerator(length: 64)
		self.expiration = expiration

		updateExpirationDate()

	}

	private func updateExpirationDate() {
		// Calculate expiration date used in cookie.
		switch expiration {
		case .session:
			timeExpires = Date(timeIntervalSince1970:  Date().timeIntervalSince1970 + 30 * 60)

		case .relativeSeconds(let seconds):
			timeExpires = Date(timeIntervalSince1970:  Date().timeIntervalSince1970 + Double(seconds))

		case .absoluteSeconds(let seconds):
			timeExpires = Date(timeIntervalSince1970: Double(seconds * 1000))

		case .absoluteDate(let date):
			timeExpires = dateFormatter.date(from: date)!
		}
	}

	public func getNewExpireDate() -> PerfectHTTP.HTTPCookie.Expiration {
		// Updae expiration date and return it in RFC2616 format.
		self.updateExpirationDate()
		return .absoluteDate(dateFormatter.string(from: timeExpires))
	}

	public func isExpired() -> Bool {
		// The expire date must be in the future.
		return timeExpires.timeIntervalSinceNow < 0
	}

	public func getCookieID() -> String {
		return self.cookieID
	}

	public func get(_ key:String) -> Any? {
		return data[key]
	}
	public func set(_ key:String, value:Any) {
		data[key] = value

	}
	public func unset(_ key:String) {
		data.removeValue(forKey: key)

	}

	public func save(response: HTTPResponse) {
		sessionManager.save(self, response: response)
	}

	public func destroy(response: HTTPResponse) {
		sessionManager.destroy(response, cookieID: cookieID)
	}
	/*
	func toJSON() throws -> String {
	return try data.jsonEncodedString()
	}

	func fromJSON(_ jsonData:String) throws {
	//data = try jsonData.jsonDecode()
	}
	*/
}
