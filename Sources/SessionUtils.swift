//
//  sessionUtil.swift
//  ElInstante
//
//  Created by Ubaldo Cotta on 20/10/16.
//
//
import Foundation
import PerfectHTTP

#if os(Linux)
	import Glibc
#endif

func tokenGenerator(withBase base: UInt32 = 62, length: Int) -> String {
	let base62chars = [Character]("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".characters)
	var code = ""
	for _ in 0..<length {
		#if os(Linux)
			let x = Int(random() / 62)
		#else
			let x = Int(arc4random_uniform(min(base, 62)))
		#endif
		code.append(base62chars[x])
	}
	return code
}

public class DateFormatterRFC2616: DateFormatter {
	public override init() {
		// We need the cookie dates in English and GMT
		// example:  Thu, 20-Oct-2016 04:32:47 GMT
		super.init()
		dateFormat = "E, dd-MMM-YYY HH:mm:ss z"
		locale = Locale(identifier: "en-US")
		timeZone = TimeZone(abbreviation: "GMT")

	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}


func synchronize(_ lockObj: Any, closure: ()->()){
	objc_sync_enter(lockObj)
	closure()
	objc_sync_exit(lockObj)
}


public extension HTTPRequest {
	public func cookie(key:String) -> String? {
		if let value = self.cookies.first(where: { (k,v) -> Bool in k == key}) {
			return value.1
		}
		return nil
	}
}


func setJSSafeCookie(_ response: HTTPResponse, domain: String?) -> String {
	let cookieID:String = tokenGenerator(length: 128)
	let cookieFinal = HTTPCookie(
		name: "perfectCheck",
		value: cookieID,
		domain: domain ,
		expires: .session,
		path: "/",
		secure: false,
		httpOnly: false,
		sameSite: .strict
	)
	response.addCookie(cookieFinal)
	return cookieID
}
