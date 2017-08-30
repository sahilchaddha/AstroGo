//
//  View.swift
//  AstroGo
//
//  Created by Nazih on 30/08/2017.
//  Copyright © 2017 Astro. All rights reserved.
//

import RxSwift

protocol ViewType: HasDisposeBag, ResusableView {}

#if os(iOS)
    import UIKit
    typealias OSView = UIView
#endif

#if os(macOS)
    import Cocoa
    typealias OSView = NSView
#endif

class View: OSView, ViewType {
    var disposeBag = DisposeBag()
}

