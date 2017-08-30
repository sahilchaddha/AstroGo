//
//  ViewController.swift
//  AstroGo
//
//  Created by Nazih on 30/08/2017.
//  Copyright © 2017 Astro. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import UIKit

protocol ViewControllerlType: HasDisposeBag {
}

class ViewController: UIViewController, ViewControllerlType {
    
    #if TRACE_RESOURCES
    private let startResourceCount = Resources.total
    #endif
    
    var disposeBag = DisposeBag()
    var _showNavigationBar: Bool!
    var _hideNavigationBar: Bool!
    var _navigationBarTranslucent: Bool!
    var _statusBarStyle: UIStatusBarStyle!
    
    /// Track the ViewController activities
    let networkActivityIndicator = ActivityIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNavigationObservable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigationBarTranslucent = self._navigationBarTranslucent {
            if navigationBarTranslucent {
                navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                navigationController?.navigationBar.shadowImage = UIImage()
                navigationController?.navigationBar.isTranslucent = true
                navigationController?.view.backgroundColor = .clear
            } else {
                navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
                navigationController?.navigationBar.shadowImage = nil
                navigationController?.navigationBar.isTranslucent = false
            }
        }
        
        if let statusBarStyle = self._statusBarStyle {
            UIApplication.shared.statusBarStyle = statusBarStyle
        }
        
        if let showNavigationBar = self._showNavigationBar {
            if showNavigationBar {
                navigationController?.setNavigationBarHidden(false, animated: true)
                navigationController?.navigationBar.tintColor = UIColor.black
            }
        }
        
        if let hideNavigationBar = self._hideNavigationBar {
            if hideNavigationBar {
                navigationController?.setNavigationBarHidden(true, animated: true)
            }
        }
        
        logger.log(viewControllerFlow: .willAppear, viewController: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.log(viewControllerFlow: .didAppear, viewController: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        logger.log(viewControllerFlow: .willDisappear, viewController: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logger.log(viewControllerFlow: .didDisappear, viewController: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        #if TRACE_RESOURCES
            logger.log(initiation: self, resourcesCount: Resources.total)
        #else
            logger.log(initiation: self, resourcesCount: nil)
        #endif
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        #if TRACE_RESOURCES
            logger.log(initiation: self, resourcesCount: Resources.total)
        #else
            logger.log(initiation: self, resourcesCount: nil)
        #endif
    }
    
    func activateCloseButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "close_icon"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(closeButtonDidTap))
        navigationController?.navigationBar.tintColor = UIColor.black
    }
    
    @objc private func closeButtonDidTap() {
        dismiss(animated: true, completion: nil)
    }
    
    // TODO: Replace `title: String? = nil` with `title: String` and make all ViewControllers use only this method to set the title
    func showNavigationBar(translucent: Bool, statusBarStyle: UIStatusBarStyle, backButtonText: String, title: String? = nil) {
        _showNavigationBar = true
        _navigationBarTranslucent = translucent
        _statusBarStyle = statusBarStyle
        if let title = title { self.title = title }
        
        // Fuck navigation controller. Yeah, they show "Back" if you give it an empty string
        var backButtonText = backButtonText
        if backButtonText == "" { backButtonText = " " }
        navigationItem.backBarButtonItem?.title = backButtonText
        navigationController?.navigationBar.backItem?.title = backButtonText
        navigationItem.backBarButtonItem = UIBarButtonItem(title: backButtonText, style: .plain, target: nil, action: nil)
    }
    
    func hideNavigationBar(backButtonText: String, statusBarStyle: UIStatusBarStyle) {
        _hideNavigationBar = true
        _statusBarStyle = statusBarStyle
        navigationItem.backBarButtonItem?.title = backButtonText
        navigationController?.navigationBar.backItem?.title = backButtonText
        navigationItem.backBarButtonItem = UIBarButtonItem(title: backButtonText, style: .plain, target: nil, action: nil)
    }
    
    //    self.navigationController?.navigationBar.shadowImage = nil
    //    self.navigationController?.isNavigationBarHidden = true
    //    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    //    self.navigationController?.navigationBar.shadowImage = UIImage()
    //    self.navigationController?.navigationBar.isTranslucent = true
    //    self.navigationController?.isNavigationBarHidden = true
    //    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    //    self.navigationController?.navigationBar.shadowImage = UIImage()
    //    self.navigationController?.navigationBar.isTranslucent = true
    //    UIApplication.shared.statusBarStyle = .lightContent
    
    deinit {
        
        #if TRACE_RESOURCES
            logger.log(deinitiation: self, resourcesCount: Resources.total)
        #else
            logger.log(deinitiation: self, resourcesCount: nil)
        #endif
        NotificationCenter.default.removeObserver(self)
        
        #if TRACE_RESOURCES
            
            /*
             !!! This cleanup logic is adapted for example app use case. !!!
             
             It is being used to detect memory leaks during pre release tests.
             
             !!! In case you want to have some resource leak detection logic, the simplest
             method is just printing out `RxSwift.Resources.total` periodically to output. !!!
             
             /* add somewhere in
             func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
             */
             _ = Observable<Int>.interval(1, scheduler: MainScheduler.instance)
             .subscribe(onNext: { _ in
             print("Resource count \(RxSwift.Resources.total)")
             })
             
             Most efficient way to test for memory leaks is:
             * navigate to your screen and use it
             * navigate back
             * observe initial resource count
             * navigate second time to your screen and use it
             * navigate back
             * observe final resource count
             
             In case there is a difference in resource count between initial and final resource counts, there might be a memory
             leak somewhere.
             
             The reason why 2 navigations are suggested is because first navigation forces loading of lazy resources.
             */
            
            let numberOfResourcesThatShouldRemain = startResourceCount
            let mainQueue = DispatchQueue.main
            /*
             This first `dispatch_async` is here to compensate for CoreAnimation delay after
             changing view controller hierarchy. This time is usually ~100ms on simulator and less on device.
             
             If somebody knows more about why this delay happens, you can make a PR with explanation here.
             */
            let when = DispatchTime.now() + DispatchTimeInterval.milliseconds(UIApplication.isInUITest ? 1000 : 10)
            
            mainQueue.asyncAfter(deadline: when) {
                
                /*
                 Some small additional period to clean things up. In case there were async operations fired,
                 they can't be cleaned up momentarily.
                 */
                // If this fails for you while testing, and you've been clicking fast, it's ok, just click slower,
                // this is a debug build with resource tracing turned on.
                //
                // If this crashes when you've been clicking slowly, then it would be interesting to find out why.
                // ¯\_(ツ)_/¯
                //                assert(Resources.total <= numberOfResourcesThatShouldRemain, "Resources weren't cleaned properly, \(Resources.total) remained, \(numberOfResourcesThatShouldRemain) expected")
            }
        #endif
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
