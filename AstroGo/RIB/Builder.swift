//
//  Builder.swift
//  AstroGo
//
//  Created by Nazih on 30/08/2017.
//  Copyright © 2017 Astro. All rights reserved.
//

protocol BuilderProtocol {
    func build() -> Riblet
}

class Builder : BuilderProtocol  {
    
    func build() -> Riblet {
        
        abort()
    }
    
    func build(parentInteractor : Interactor) -> Riblet {
        
        abort()
    }
    
}
