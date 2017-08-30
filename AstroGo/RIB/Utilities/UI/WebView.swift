//
//  WebView.swift
//  FAVE
//
//  Created by Nazih on 05/02/2017.
//  Copyright © 2017 kfit. All rights reserved.
//

import Foundation
import WebKit
import RxSwift
import RxCocoa

protocol WebViewType {
}

class WebView: WKWebView, WebViewType {
    static let disableZoomingScript = "var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);"

    static let blankPageFixScript = "var allLinks=document.getElementsByTagName('a');if(allLinks){var i;for(i=0;i<allLinks.length;i++){var link=allLinks[i];var target=link.getAttribute('target');if(target&&target=='_blank'){link.setAttribute('target','_self')}}}"

    static let getDefaultUserAgentScript = "navigator.userAgent;"

    /// Generates script to create given cookies
    static func cookiesInjectionScript(forCookies cookies: [HTTPCookie]) -> String {
        var result = ""
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss zzz"

        for cookie in cookies {
            result += "document.cookie='\(cookie.name)=\(cookie.value); domain=\(cookie.domain); path=\(cookie.path); "
            if let date = cookie.expiresDate {
                result += "expires=\(dateFormatter.string(from: date)); "
            }
            if cookie.isSecure {
                result += "secure; "
            }
            result += "'; "
        }
        return result
    }

    static let scaleToFitScript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
}

extension Reactive where Base: WKWebView {
    /**
     Reactive wrapper for `title` property
     */
    public var title: Observable<String?> {
        return observe(String.self, "title")
    }

    /**
     Reactive wrapper for `loading` property.
     */
    public var loading: Observable<Bool> {
        return observe(Bool.self, "loading")
            .map { $0 ?? false }
    }

    /**
     Reactive wrapper for `estimatedProgress` property.
     */
    public var estimatedProgress: Observable<Double> {
        return observe(Double.self, "estimatedProgress")
            .map { $0 ?? 0.0 }
    }

    /**
     Reactive wrapper for `url` property.
     */
    public var url: Observable<URL?> {
        return observe(URL.self, "URL")
    }

    /**
     Reactive wrapper for `canGoBack` property.
     */
    public var canGoBack: Observable<Bool> {
        return observe(Bool.self, "canGoBack")
            .map { $0 ?? false }
    }

    /**
     Reactive wrapper for `canGoForward` property.
     */
    public var canGoForward: Observable<Bool> {
        return observe(Bool.self, "canGoForward")
            .map { $0 ?? false }
    }
}
