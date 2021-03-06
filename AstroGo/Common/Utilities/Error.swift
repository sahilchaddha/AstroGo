//
//  DescribableError.swift
//
//  Created by Nazih Shoura.
//  Copyright © 2017 Nazih Shoura. All rights reserved.
//  See LICENSE.txt for license information
//

import Foundation

protocol DescribableError:
    Error
    , CustomDebugStringConvertible
    , CustomStringConvertible {}

protocol RecoverableError:
    Error
    , CustomDebugStringConvertible {}
