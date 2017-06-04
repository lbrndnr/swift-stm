//
//  Reference.swift
//  SwiftSTM
//
//  Created by Laurin Brandner on 29.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation
import Atomics

precedencegroup ReferencePriorityPrecedence {
    lowerThan: ComparisonPrecedence
    higherThan: AssignmentPrecedence
}

public typealias TInt = Ref<Int>

public typealias Ref<V: Hashable> = Reference<V>

public final class Reference<V: Hashable> {
    
    fileprivate var value: V
    fileprivate var newValue: V?
    
    private var firstBarrierHash = AtomicInt(0)
    private var threadBarrier: Barrier? {
        return Thread.current.barrier
    }
    
    var conflicting = false
    
    // MARK: - Initialization
    
    public init(_ value: V) {
        self.value = value
    }
    
    // MARK: -
    
    private func log() {
        if firstBarrierHash.value == 0 {
            if !conflicting && firstBarrierHash.value != threadBarrier?.hashValue {
                conflicting = true
            }
        }
        else if let threadBarrier = threadBarrier {
            firstBarrierHash.CAS(current: 0, future: threadBarrier.hashValue)
        }
    }
    
    public func get() -> V {
        log()
        threadBarrier?.readReferences.update(with: self)
        
        return value
    }
    
    public func set(_ val: V) {
        log()
        threadBarrier?.writtenReferences.update(with: self)
        
        newValue = val
    }
    
    func commit() {
        guard let val = newValue else {
            return
        }
        
        value = val
        newValue = nil
        conflicting = false
        firstBarrierHash.store(0)
    }
    
    func rollback() {
        newValue = nil
        conflicting = false
        firstBarrierHash.store(0)
    }
    
}

extension Reference: Hashable {
    
    public var hashValue: Int {
        return value.hashValue
    }
    
}

public func ==<V: Equatable>(lhs: Reference<V>, rhs: Reference<V>) -> Bool {
    return lhs.value == rhs.value
}
