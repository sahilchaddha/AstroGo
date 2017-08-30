//
//  Riblet.swift
//  AstroGo
//
//  Created by Nazih on 30/08/2017.
//  Copyright © 2017 Astro. All rights reserved.
//

import Foundation
import UIKit

class Riblet : Equatable {
    
    var router : Router
    var interactor : Interactor
    var builder : Builder
    
    var viewController : UIViewController?
    
    init(router : Router, interactor : Interactor, builder : Builder) {
        
        self.router = router
        self.interactor = interactor
        self.builder = builder
    }
}

func ==(lhs: Riblet, rhs: Riblet) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
