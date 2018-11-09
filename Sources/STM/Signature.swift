//
//  Signature.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation
import Atomics

private var IDCounter = AtomicUInt64()

struct Signature {
    
    weak var reference: Referenceable?
    var ID: UInt64
    
    init() {
        ID = IDCounter.increment()
    }
    
}

extension Signature: Hashable {
    
    var hashValue: Int {
        return ID.hashValue
    }
    
}

func ==(lhs: Signature, rhs: Signature) -> Bool {
    return lhs.ID == rhs.ID
}
