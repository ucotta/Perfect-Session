//
//  MySQLSessionConnector.swift
//  ElInstante
//
//  Created by Ubaldo Cotta on 21/10/16.
//
//
import PerfectLib
import Foundation
import MySQL

public class SessionMySQLConnector {
	private let host:String
	private let user:String
	private let pass:String
	private let scheme:String
	private let db:String


	public init(host:String, user:String, pass:String, scheme:String, db:String) {
		self.host = host
		self.user = user
		self.pass = pass
		self.scheme = scheme
		self.db = db

		guard let mysql = getConnection() else {
			return
		}

		defer {
			mysql.close()
		}

		// Test connection selecting the database.
		guard mysql.selectDatabase(named: scheme) else {
			Log.critical(message: "Session: There was an error connecting to the database: \(mysql.errorCode()) \(mysql.errorMessage())")
			return
		}
	}

	public func getConnection() -> MySQL? {
		let mysql = MySQL()

		guard mysql.connect(host: host, user: user, password: pass, db: scheme) else {
			Log.critical(message: "Session: There was not possible to connect to MySQL: " + mysql.errorMessage())
			return nil
		}
		return mysql;

	}


	public func dbGetCookieData(_ key: String) -> String? {
		let helper = MySQLHelper(host: host, user: user, pass: pass, scheme: scheme, db: db)

		do {
			try helper.checkConnection()
			if let res = try helper.queryRow("SELECT data FROM \(db) WHERE cookie = ? LIMIT 1", args: key) {
				return res[0] as! String
			}
		} catch {
			print("error!")
		}

		return nil
	}

	public func dbUpdateCookieData(_ cookieId:String, cookieData:String, expireOn:Date) {
		let helper = MySQLHelper(host: host, user: user, pass: pass, scheme: scheme, db: db)

		do {
			try helper.checkConnection()
			try helper.execute("INSERT INTO \(db) (cookie, expire, data) VALUES (?, ?, ?) " +
				"ON DUPLICATE KEY UPDATE expire = values(expire), data = values(data)", args: cookieId, expireOn, cookieData)
		} catch {
			print("error!")
		}
	}

	public func dbDeleteCookie(_ cookieId:String) {
		let helper = MySQLHelper(host: host, user: user, pass: pass, scheme: scheme, db: db)

		do {
			try helper.checkConnection()
			try helper.execute("DELETE data FROM \(db) WHERE cookie = ? LIMIT 1", args: cookieId)
		} catch {
			print("error!")
		}
	}
}
