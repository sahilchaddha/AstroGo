//
//  Network.swift
//
//  Created by Nazih Shoura.
//  Copyright © 2017 Nazih Shoura. All rights reserved.
//  See LICENSE.txt for license information
//

import Foundation
import WebKit
import Alamofire
import RxOptional

protocol NetworkServiceType: SubjectLabelable {
    /**
     Default session configuration object. The manager is configured with
     ```
     HTTPAdditionalHeaders = ["User-Agent": DefaultAPI.userAgent]
     ```
     */
    var managerWithDefaultConfiguration: SessionManager { get }
    
    /**
     The userAgent that the sessions are configured with.
     ```
     HTTPAdditionalHeaders = ["User-Agent": DefaultAPI.userAgent]
     ```
     */
    var userAgent: String { get }
    
    /**
     Creates an URLRequestConvertible.
     
     - parameter url: The URL to be requested
     - parameter method: Alamofire method object
     - parameter parameters: A dictionary of query paramerters to be encoded in the URL
     - parameter encoding: The kind of encoding used to encode the query parameters
     - parameter header: A dictionary containing headers to be added in the request
     - returns: An instance of `URLRequestConvertible`
     
     */
    func urlRequestConvertible(
        forURL url: URL
        , method: HTTPMethod
        , parameters: [String: AnyObject]?
        , encoding: ParameterEncoding
        , headers: [String: String]?
        ) -> URLRequestConvertible
}

final class NetworkService: NetworkServiceType {
    
    let managerWithDefaultConfiguration: SessionManager
    
    let userAgent: String
    
    init() {
        
        // User-Agent Header; see https://tools.ietf.org/html/rfc7231#section-5.5.3
        // Example: `iOS Example/1.0 (org.alamofire.iOS-Example; build:1; iOS 10.0.0)`
        let userAgent: String = {
            guard let info = Bundle.main.infoDictionary else {
                return "Unknown"
            }
            
            let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
            let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
            let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
            let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"
            let deviceModel = UIDevice.current.model
            
            let osNameVersion: String = {
                let version = ProcessInfo.processInfo.operatingSystemVersion
                let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
                
                let osName: String = {
                    #if os(iOS)
                        return "iOS"
                    #elseif os(watchOS)
                        return "watchOS"
                    #elseif os(tvOS)
                        return "tvOS"
                    #elseif os(macOS)
                        return "OS X"
                    #elseif os(Linux)
                        return "Linux"
                    #else
                        return "Unknown"
                    #endif
                }()
                
                return "\(osName) \(versionString)"
            }()
            
            return "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); device model:\(deviceModel) \(osNameVersion))"
        }()
        
        self.userAgent = userAgent
        
        managerWithDefaultConfiguration = {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["User-Agent": userAgent]
            return SessionManager(configuration: configuration)
        }()
    }
    
    func urlRequestConvertible(
        forURL url: URL
        , method: HTTPMethod
        , parameters: [String: AnyObject]? = nil
        , encoding: ParameterEncoding = URLEncoding.default
        , headers: [String: String]? = nil
        ) -> URLRequestConvertible {
        
        var urlRequest = Foundation.URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        if let headers = headers {
            for (headerField, headerValue) in headers {
                urlRequest.setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }
        
        if let parameters = parameters
            , parameters.isNotEmpty {
            do {
                urlRequest = try encoding.encode(urlRequest, with: parameters)
            } catch {
                fatalError("Make sure the paramters can be encoded!\nReceived parameters: \(parameters)")
            }
        }
        
        #if DEBUG
            urlRequest.cachePolicy = Foundation.URLRequest.CachePolicy.reloadIgnoringCacheData
        #endif
        
        return urlRequest
    }
}

extension NetworkService {
    fileprivate static func cache(cookie: String) {
        UserDefaults.standard
            .set(cookie, forKey: "")
    }
    
    fileprivate static func loadCacheForCookies() -> String? {
        if let cookie = UserDefaults.standard.object(forKey: "") as? String {
            return cookie
        }
        
        NetworkService.clearCacheForCookies()
        return nil
    }
    
    fileprivate static func clearCacheForCookies() {
        UserDefaults.standard
            .set(nil, forKey: "")
    }
}

