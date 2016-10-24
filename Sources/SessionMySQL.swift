//
//  SessionMySQL.swift
//  ElInstante
//
//  Created by Ubaldo Cotta on 20/10/16.
//
//

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
//import MySQL



public class MySQLSession: SessionProtocol {
	public var cookieIDName: String

	public var domain:String?
	public var expiration: PerfectHTTP.HTTPCookie.Expiration? = .relativeSeconds(60*30)
	public var path:String? = "/"
	public var secure:Bool? = true
	public var httpOnly: Bool? = true
	public var sameSite: PerfectHTTP.HTTPCookie.SameSite? = .strict

	private let connector: SessionMySQLConnector

	public required init(cookieName cookieIDName: String = "perfectCookieSession", host:String, user:String, pass:String, scheme:String, db:String) {
		self.cookieIDName = cookieIDName

		if cookieIDName == "perfectCookieSession" {
			// Dont help intruders to identify your application, use custom session id.
			Log.warning(message: "MySQLSession started with cookieIdName = 'perfectCookieSession' use a custom one.")
		} else {
			Log.debug(message: "MySQLSession started with cookieIDName \(cookieIDName)")
		}
		connector = SessionMySQLConnector(host: host, user: user, pass: pass, scheme: scheme, db: db)

		//connector.dbUpdateCookieData("juan", cookieData: "juan", expireOn: Date())
		//connector.dbUpdateCookieData("juan", cookieData: "juan2", expireOn: Date())
		//var res = connector.dbGetCookieData("juan")
		//connector.dbDeleteCookie("juan")

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
	public func start(_ request: HTTPRequest, response: HTTPResponse, expiration: PerfectHTTP.HTTPCookie.Expiration?) -> Session {
		return Session(sessionManager: self, expiration: .session)
	}

	public func save(_ session: Session, response: HTTPResponse) { }

	public func destroy(_ response: HTTPResponse, cookieID: String) {
		// pass
	}


}



