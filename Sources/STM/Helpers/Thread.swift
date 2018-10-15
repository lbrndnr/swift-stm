//
//  Thread.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

private let currentBarrierKey = "ch.laurinbrandner.stm.current-barrier"

extension Thread {
    
    var barrier: Barrier? {
        get {
            return threadDictionary[currentBarrierKey] as? Barrier
        }
        set {
            threadDictionary[currentBarrierKey] = newValue
        }
    }
    
}
