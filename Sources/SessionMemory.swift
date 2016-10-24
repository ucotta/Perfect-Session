//
//  memorySession.swift
//
//  Created by Ubaldo Cotta on 20/10/16.
//
//  MemorySession.swift
//
//  This module create a session array and locks it every time that access to it.
//  Clean all expired cookies every minute, this action is launched when the minute changes
//  and a call to save, start or destroy happend


import Foundation
import PerfectHTTP
import PerfectLib

public class MemorySession: SessionProtocol {
	public var cookieIDName: String
	private let locker: String = "lock"
	private var sessions: [String: Session]
	private var currentMinute:Date

	public var domain:String?
	public var expiration: PerfectHTTP.HTTPCookie.Expiration? = .relativeSeconds(60*30)
	public var path:String? = "/"
	public var secure:Bool? = true
	public var httpOnly: Bool? = true
	public var sameSite: PerfectHTTP.HTTPCookie.SameSite? = .strict


	public required init(cookieName cookieIDName: String = "perfectCookieSession") {
		sessions = [:]
		self.cookieIDName = cookieIDName
		currentMinute = Date()
		if cookieIDName == "perfectCookieSession" {
			// Dont help intruders to identify your application, use custom session id.
			Log.warning(message: "MemorySession started with cookieIdName = 'perfectCookieSession' use a custom one.")
		} else {
			Log.debug(message: "MemorySession started with cookieIDName \(cookieIDName)")
		}
	}

	public func setCookieAttributes(domain:String? = nil, expiration: PerfectHTTP.HTTPCookie.Expiration? = nil, path:String? = nil,
	                                secure:Bool? = nil, httpOnly: Bool? = nil, sameSite: PerfectHTTP.HTTPCookie.SameSite? = nil) {
		self.domain = domain ?? self.domain
		self.expiration = expiration ?? self.expiration
		self.path = path ?? self.path
		self.secure = secure ?? self.secure
		self.httpOnly = httpOnly ?? self.httpOnly
		self.sameSite = sameSite ?? self.sameSite

		checkSecurity(secure: secure, httpOnly: httpOnly, sameSite: sameSite)
	}

	public func start(_ request:HTTPRequest, response:HTTPResponse, expiration: PerfectHTTP.HTTPCookie.Expiration?) -> Session {
		var session:Session? = nil

		// Check for a previous cookie
		if let cookieID = request.cookie(key: cookieIDName) {
			synchronize(sessions) {
				session = sessions[cookieID]
				//Log.debug(message: "MemorySession recupered cookie \(cookieID) ")
			}
		}

		// if not was registered create a new one
		if session == nil {
			// Create a new session.

			session = Session(sessionManager: self, expiration: expiration ?? self.expiration!)

			synchronize(sessions) {
				sessions[(session?.getCookieID())!] = session
				//Log.debug(message: "MemorySession created cookie \(session?.getCookieID()) ")
			}
			response.addCookie(createCookie(cookieID: session!.getCookieID(), newExpiration: session?.getNewExpireDate()))
		}
		expireSessions()
		return session!
	}

	public func save(_ session:Session, response: HTTPResponse) {
		// Set a new cookie with same cookieId and new expiration date.
		response.addCookie(createCookie(cookieID: session.getCookieID(), newExpiration: session.getNewExpireDate()))
		//Log.debug(message: "MemorySession updated cookie \(session.getCookieID()) ")

		// now clean all expired cookies.
		expireSessions()
	}

	public func destroy(_ response:HTTPResponse, cookieID: String) {
		synchronize(sessions) {
			sessions.removeValue(forKey: cookieID)
			//Log.debug(message: "MemorySession destroyed cookie \(cookieID) ")
		}
		expireSessions()
		//     Set-Cookie: token=deleted; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT
	}

	private func expireSessions() {
		synchronize(sessions) {
			//Log.debug(message: "Check date expiration: \(currentMinute)")
			if currentMinute.timeIntervalSinceNow < -1.0 {
				// We check every 60 seconds.
				currentMinute = Date()
				//Log.debug(message: "MemorySession start expireSession for \(sessions.count) sessions")

				let keys = sessions.keys
				for key in keys {
					//Log.debug(message: "MemorySession check for expired cookie \(key) ")
					if let session = sessions[key] {
						if session.isExpired() {
							sessions.removeValue(forKey: key)
							//Log.debug(message: "MemorySession expired cookie \(key) \(sessions.count)")
						}
					}
				}
				//Log.debug(message: "MemorySession end expireSession")
			}
		}
	}
}



