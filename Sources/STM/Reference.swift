//
//  Reference.swift
//  STM
//
//  Created by Laurin Brandner on 29.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//
import Foundation
import Atomics

protocol Referenceable: AnyObject {
    
    func commit()
    func rollback()
    func reset()
    
}

public typealias Ref<V> = Reference<V>

public final class Reference<V> : Referenceable {
    
    var signature = Signature()
    
    fileprivate var value: V
    fileprivate var newValue: V?
    
    private var currentBarrier: Barrier? {
        return Thread.current.barrier
    }
    
    private var reads = AccessQueue()
    private var writes = AccessQueue()
    
    // MARK: - Initialization
    
    public init(_ v: V) {
        value = v
        signature.reference = self
    }
    
    // MARK: -
    
    public func get() -> V {
        guard let barrier = currentBarrier else {
            abort()
        }
        
        if let blockingBarrier = writes.contains(notEqual: barrier) {
            barrier.wait(for: blockingBarrier, conflict: signature)
            return value
        }
        
        reads.append(barrier: barrier)
        barrier.markAsRead(using: signature)
        
        return newValue ?? value
    }
    
    public func set(_ val: V) {
        guard let barrier = currentBarrier else {
            abort()
        }

        if let blockingBarrier = reads.contains(notEqual: barrier) {
            barrier.wait(for: blockingBarrier, conflict: signature)
            return
        }
        if let blockingBarrier = writes.contains(notEqual: barrier) {
            barrier.wait(for: blockingBarrier, conflict: signature)
            return
        }

        writes.append(barrier: barrier)
        barrier.markAsWritten(using: signature)
        
        newValue = val
    }
    
    func commit() {
        value = newValue ?? value
        rollback()
    }
    
    func rollback() {
        guard let barrier = currentBarrier else {
            abort()
        }
        
        if barrier.isWriting(signature) {
            newValue = nil
        }
        writes.remove(barrier: barrier)
        reads.remove(barrier: barrier)
    }
    
    func reset() {
        guard let barrier = currentBarrier else {
            abort()
        }
        
        reads.remove(barrier: barrier)
    }
    
}
