//
//  DeepLinkBuildable.swift
//  AstroGo
//
//  Created by Nazih on 30/08/2017.
//  Copyright © 2017 Astro. All rights reserved.
//

import Foundation

protocol DeepLinkBuildable {
    associatedtype ObjectType
    static func build(deepLink: String, params: [String: Any]) -> ObjectType?
}
