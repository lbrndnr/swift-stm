//
//  Signature.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation
import Atomics
import AtomicLinkedList

private var IDCounter = AtomicUInt64()

struct Signature: Identifiable {
    
    weak var reference: Referenceable?
    var ID: UInt64
    
    init() {
        ID = IDCounter.increment()
    }
    
}

extension Signature: Equatable {
    
    static func == (lhs: Signature, rhs: Signature) -> Bool {
        return lhs.ID == rhs.ID
    }
    
}
