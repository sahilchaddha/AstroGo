//
//  WebViewViewController.swift
//  FAVE
//
//  Created by Nazih on 08/02/2017.
//  Copyright © 2017 kfit. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Alamofire
import WebKit

final class WebViewViewController: ViewController, Scrollable {

    fileprivate var isWebViewFrameSetted: Bool = false
    fileprivate var webView: WebView!
    fileprivate let refreshControl = UIRefreshControl()

    // MARK: - ViewModel
    var viewModel: WebViewViewControllerViewModel!

    // MARK: - IBOutlet
    @IBOutlet fileprivate weak var webViewContainer: View!
    var placeHolderView: UIView!

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
        bind()
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        if !isWebViewFrameSetted {
            isWebViewFrameSetted = true
            webView.frame = view.bounds
        }
      
        if viewModel.shouldSetAsActive {
            viewModel.setAsActive()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    private func configureWebView() {
        let userContentController = WKUserContentController()

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = userContentController

        webView = WebView(frame: .zero, configuration: webConfiguration)
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.configuration.suppressesIncrementalRendering = true
        webView.configuration.allowsInlineMediaPlayback = true
        webView.navigationDelegate = viewModel
        view.addSubview(webView)
        
        webView.scrollView.addSubview(refreshControl)
        webView.customUserAgent = viewModel.userAgent
        webView.backgroundColor = UIColor.white
        webViewContainer.backgroundColor = UIColor.white
        webView.scrollView.setContentOffset(.zero, animated: false)
        
        placeHolderView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.width, height: UIScreen.main.height))
        let imageView = UIImageView(frame: placeHolderView.bounds)
        imageView.image = viewModel.placeHolderImage
        placeHolderView.addSubview(imageView)
        view.addSubview(placeHolderView)
    }

    private func setup() {
        endEditingWhenTapOnBackground(true)
    }

    func scrollToTop() {
        webView.scrollView.scrollToTop()
    }
}

// MARK: - ViewModelBinldable
extension WebViewViewController: HasViewModel {
    fileprivate func bind() {
        switch viewModel.titleOption {
        case .webViewTitle:
            webView.rx
                .title
                .map { (title: String?) -> String in
                    guard let title = title, title.isNotEmpty else { return "Fave" }
                    return title
                }
                .bind(to: rx.title)
                .disposed(by: disposeBag)

        case .noTitle:
            self.title = ""
        case let .customTitle(title):
            self.title = title
        }

        viewModel
            .urlRequest
            .asDriver()
            .filterNil()
            .driveNext { [weak self] (urlRequest: URLRequest) in
                self?.refresh()
            }
            .disposed(by: disposeBag)

        refreshControl
            .rx.controlEvent(UIControlEvents.valueChanged)
            .subscribeNext { [weak self] in
                // Don't show the place holder view while refreshing
                self?.placeHolderView.isHidden = true
                self?.refresh()
                self?.refreshControl.endRefreshing()
            }
            .disposed(by: disposeBag)

        viewModel
            .reloadSignal
            .subscribeNext { [weak self] () in
                self?.refresh()
            }
            .disposed(by: disposeBag)

        webView.rx
            .loading
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribeNext { [weak self] (isLoading: Bool) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = isLoading
                if isLoading {
                    self?.view.startUIActivityIndicator()
                }
                else {
                    self?.view.stopUIActivityIndicator()
                }
                
                // Show and hide place holder view first time using
                if isLoading == true {
                    self?.placeHolderView.alpha = 1.0
                }
                else {
                    UIView.animate(withDuration: 0.5, animations: {
                        self?.placeHolderView.alpha = 0.0
                    })
                }
            }
            .disposed(by: disposeBag)
    }
}

extension WebViewViewController: Refreshable {
    func refresh() {
        if let urlRequest = viewModel.urlRequest.value {
            _ = webView.load(urlRequest)
        }
    }
}

// MARK: - Buildable
extension WebViewViewController: Buildable {
    class func build(_ builder: WebViewViewControllerViewModel) -> WebViewViewController {
        let storyboard = UIStoryboard(name: "WebView", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: WebViewViewController.subjectLabel) as! WebViewViewController
        vc.viewModel = builder
        vc.setPrivateViewModel(builder)
        return vc
    }
}
