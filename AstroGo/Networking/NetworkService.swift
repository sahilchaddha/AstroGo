//
//  NetworkService.swift
//  AstroGo
//
//  Created by Nazih on 30/08/2017.
//  Copyright © 2017 Astro. All rights reserved.
//

import Foundation
import Alamofire

protocol NetworkService {
    /**
     Default session configuration object. The manager is configured with
     ```
     HTTPAdditionalHeaders = ["User-Agent": DefaultAPI.userAgent]
     ```
     
     - author: Nazih Shoura
     */
    var managerWithDefaultConfiguration: SessionManager { get }
    
    /**
     A session configuration object that allows HTTP and HTTPS uploads or downloads to be performed in the background. Identifier is "com.kfit.KFIT"
     ```
     HTTPAdditionalHeaders = ["User-Agent": DefaultAPI.userAgent]
     ```
     
     - author: Nazih Shoura
     */
    var managerWithBackgroundConfiguration: SessionManager { get }
    
    /**
     A session configuration that uses no persistent storage for caches, cookies, or credentials. The manager is configured with
     ```
     HTTPAdditionalHeaders = ["User-Agent": DefaultAPI.userAgent]
     ```
     
     - author: Nazih Shoura
     */
    var managerWithEphemeralConfiguration: SessionManager { get }
    
    /**
     The userAgent that the sessions are configured with.
     ```
     HTTPAdditionalHeaders = ["User-Agent": DefaultAPI.userAgent]
     ```
     
     - author: Nazih Shoura
     */
    var userAgent: String { get }
    
    /**
     Creates a NSMutableURLRequest using all necessary parameters.
     
     - author: Nazih Shoura
     
     - parameter method: Alamofire method object
     - parameter URLString: An object adopting `URLStringConvertible`
     - parameter parameters: A dictionary containing all necessary options
     - parameter encoding: The kind of encoding used to process parameters
     - parameter header: A dictionary containing all the addional headers
     - returns: An instance of `NSMutableURLRequest`
     */
    func URLRequest(
        method: HTTPMethod
        , url: URL
        , parameters: [String:AnyObject]?
        , encoding: ParameterEncoding
        , headers: [String:String]?)
        throws -> URLRequestConvertible
    
    func setCookiesFromResponse(_ response: HTTPURLResponse)
    
    static var cookie: String? { get }
    
    var sessionExist: Bool { get }
}

final class NetworkServiceDefault: Service, NetworkService {
    
    let managerWithDefaultConfiguration: SessionManager
    
    let managerWithBackgroundConfiguration: SessionManager
    
    let managerWithEphemeralConfiguration: SessionManager
    
    let userAgent: String
    
    static var cookie: String?
    
    init() {
        
        let userAgent: String = {
            let infoDict = Bundle.main.infoDictionary
            let appVersion = infoDict!["CFBundleShortVersionString"]!
            let buildNumber = infoDict!["CFBundleVersion"]!
            let currentDeviceModel = UIDevice.current.model
            let currentDeviceSystemVersion = UIDevice.current.systemVersion
            let userAgent = "AstroGo-Global/v\(appVersion)-\(buildNumber) (\(currentDeviceModel);iOS \(currentDeviceSystemVersion))"
            
            return userAgent
        }()
        
        self.userAgent = userAgent
        
        managerWithEphemeralConfiguration = {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpAdditionalHeaders = ["User-Agent": userAgent]
            return SessionManager(configuration: configuration)
        }()
        
        managerWithBackgroundConfiguration = {
            let configuration = URLSessionConfiguration.background(withIdentifier: "com.Astro.AstroGo")
            configuration.httpAdditionalHeaders = ["User-Agent": userAgent]
            return SessionManager(configuration: configuration)
        }()
        
        managerWithDefaultConfiguration = {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["User-Agent": userAgent]
            return SessionManager(configuration: configuration)
        }()
        
        super.init()
        
        loadSession()
        
        app.logoutSignal.subscribeNext {
            _ in
            NetworkServiceDefault.clearCacheForCookies()
            }.addDisposableTo(disposeBag)
    }
    
    // A dummy struct to confirm to Alamofire 4 stupid update that requirs `URLRequestConvertible` as a parameter for `request` instead of URLRequest
    private struct URLRequestConvertibleDummyStruct: URLRequestConvertible {
        let urlRequest: URLRequest
        init(urlRequest: URLRequest) {
            self.urlRequest = urlRequest
        }
        func asURLRequest() throws -> URLRequest {
            return self.urlRequest
        }
    }
    
    func URLRequest(
        method: HTTPMethod
        , url: URL
        , parameters: [String:AnyObject]? = nil
        , encoding: ParameterEncoding = URLEncoding.default
        , headers: [String:String]? = nil)
        throws -> URLRequestConvertible {
            var urlRequest = Foundation.URLRequest(url: url)
            urlRequest.httpMethod = method.rawValue
            urlRequest.httpShouldHandleCookies = false
            
            if let headers = headers {
                for (headerField, headerValue) in headers {
                    urlRequest.setValue(headerValue, forHTTPHeaderField: headerField)
                }
            }
            
            if let cookie = NetworkServiceDefault.cookie {
                urlRequest.setValue(cookie, forHTTPHeaderField: "Cookie")
            }
            
            if let parameters = parameters {
                urlRequest = try encoding.encode(urlRequest, with: parameters)
            }
            
            #if DEBUG
                urlRequest.cachePolicy = Foundation.URLRequest.CachePolicy.reloadIgnoringCacheData
            #endif
            
            logger.log(request: urlRequest, parameters: parameters, headers: headers, cookie: NetworkServiceDefault.cookie)
            
            return URLRequestConvertibleDummyStruct(urlRequest: urlRequest)
    }
    
    func setCookiesFromResponse(_ response: HTTPURLResponse) {
        if let headerFields = response.allHeaderFields as? [String:String]
        {
            guard let cookie = headerFields["Set-Cookie"] else {
                return
            }
            
            NetworkServiceDefault.cookie = cookie
            NetworkServiceDefault.cache(cookie)
        }
    }
    
    var sessionExist: Bool {
        guard let cookie = UserDefaults.standard
            .object(forKey: literal.Cookie) as? String
            , !cookie.isEmpty
            else {
                return false
        }
        
        return true
    }
    
    func loadSession() {
        NetworkServiceDefault.cookie = NetworkServiceDefault.loadCacheForCookies()
    }
}

extension NetworkServiceDefault {
    static func cache(_ cookie: String) {
        UserDefaults.standard
            .set(cookie, forKey: literal.Cookie)
    }
    
    static func loadCacheForCookies() -> String? {
        guard let cookie = UserDefaults.standard.object(forKey: literal.Cookie) as? String else {
            NetworkServiceDefault.clearCacheForCookies()
            return nil
        }
        
        return cookie
    }
    
    static func clearCacheForCookies() {
        UserDefaults.standard
            .set(nil, forKey: literal.Cookie)
        NetworkServiceDefault.cookie = nil
    }
}
