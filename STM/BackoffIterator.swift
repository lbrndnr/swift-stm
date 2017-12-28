//
//  BackoffIterator.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

struct BackoffIterator: IteratorProtocol {
    
    private var power: Double = 0
    
    public mutating func next() -> TimeInterval? {
        defer {
            power += 1
        }
        
        return pow(2.0, power) / 1_000_000
    }
    
}
