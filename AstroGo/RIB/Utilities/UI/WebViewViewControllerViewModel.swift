//
//  WebViewViewControllerViewModel.swift
//  FAVE
//
//  Created by Nazih on 08/02/2017.
//  Copyright © 2017 kfit. All rights reserved.
//

import RxSwift
import Alamofire
import RxCocoa
import WebKit


enum WebViewViewControllerTitleOption {
    case noTitle
    case webViewTitle
    case customTitle(String)
}

final class WebViewViewControllerViewModel: ViewModel {

    // Dependancy
    fileprivate let networkService: NetworkService
    fileprivate let locationService: LocationService
    fileprivate let cityProvider: CityProvider
    fileprivate let routerService: RouterService

    let urlRequest: Variable<URLRequest?>
    let userAgent: String
    let authorised: Bool

    let reloadSignal = PublishSubject<Void>()
    let titleOption: WebViewViewControllerTitleOption
    
    init(
        url: URL
        , titleOption: WebViewViewControllerTitleOption
        , shouldSetAsActive: Bool
        , authorised: Bool
        , webViewSpecialPage: WebViewSpecialPage = WebViewSpecialPage.none
        , networkService: NetworkService = networkServiceDefault
        , cityProvider: CityProvider = cityProviderDefault
        , routerService: RouterService = routerServiceDefault
        , locationService: LocationService = locationServiceDefault
        , assetProvider: AssetProvider = assetProviderDefault
        , refreshReservationState: PublishSubject<Void> = refreshReservationStateDefault
        , favoriteOutletModel: FavoriteOutletModel = favoriteOutletModelDefault
    ) {
        // Clear the cookies (Make a fresh webview)
        HTTPCookieStorage.shared.removeCookies(since: Date().addingTimeInterval(-86400.0))

        self.routerService = routerService
        self.cityProvider = cityProvider
        self.locationService = locationService
        self.networkService = networkService
        self.shouldSetAsActive = shouldSetAsActive
        self.urlRequest = Variable(nil)
        self.userAgent = networkService.webviewUserAgent
        self.authorised = authorised
        self.titleOption = titleOption
        
        
        super.init()

        request(url: url)
    }

    func request(urlRequest: URLRequest) {
        self.urlRequest.value = urlRequest
    }
}

extension WebViewViewControllerViewModel: WKNavigationDelegate {
    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        logger.log(error: error)
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        // Workaround bug where _blank page fail to open
        // http://swiftgazelle.com/2015/08/wkwebview-target_blank-quirks/
        webView.evaluateJavaScript(WebView.blankPageFixScript, completionHandler: { _, error in
            if let error = error {
                logger.log(error: error)
            }
        })
    }

    func webView(_: WKWebView, didFail _: WKNavigation, withError error: Error) {
        logger.log(error: error)
    }
    
    func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        logger.log(request: navigationAction.request, message: "WebView request")

        // Allow the webview to handle the first request used to initialise the WebViewControllerViewModle
        guard urlRequest.value?.url?.absoluteString != navigationAction.request.url?.absoluteString else {
            decisionHandler(.allow)
            return
        }

        guard var url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        url = routerService.cleanUp(url: url)

        // check if the url is deeplink url
        if url.absoluteString.hasPrefix("fave") {
            if !routerService.route(to: url) {
                UIApplication.shared.openURL(url)
            }
            decisionHandler(.cancel)
        } else if url.absoluteString.hasPrefix("http") {
            if !routerService.route(to: url) {
                UIApplication.shared.openURL(url)
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
