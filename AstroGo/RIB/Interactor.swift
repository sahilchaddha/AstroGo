//
//  Interactor.swift
//  AstroGo
//
//  Created by Nazih on 30/08/2017.
//  Copyright © 2017 Astro. All rights reserved.
//

import Foundation

protocol RootInteractor {
    
    func handleDeepLink(params : [AnyHashable:Any])
}

enum Action {
    
    case willChange
    case didChanged
}

struct Event {
    
    var context : AnyObject?
    var action : Action
    
    init(action : Action, context : AnyObject?) {
        
        self.action = action
        self.context = context
    }
}

protocol EventListener {
    
    func eventChanged(forEvent event : Event)
}

class Interactor {
    
    var eventListeners : [EventListener]?
    
    func setEventListener(listener : EventListener) {
        
        if (self.eventListeners == nil) {
            
            self.eventListeners = []
        }
        
        self.eventListeners?.append(listener)
    }
    
    func postEvent(event : Event) {
        
        if let eventListeners = self.eventListeners {
            for listener in eventListeners {
                
                listener.eventChanged(forEvent: event)
            }
        }
    }
}
