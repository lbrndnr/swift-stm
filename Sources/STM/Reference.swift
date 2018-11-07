//
//  Reference.swift
//  STM
//
//  Created by Laurin Brandner on 29.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//
import Foundation
import Atomics
import AtomicLinkedList

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
    
    private var reads = AtomicLinkedList<Barrier>()
    private var writes = AtomicLinkedList<Barrier>()
    
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

        let ticket = reads.append(barrier)
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

        writes.enqueue(barrier)
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
        writes.remove(barrier)
        reads.remove(barrier)
    }
    
    func reset() {
        guard let barrier = currentBarrier else {
            abort()
        }
        
        reads.remove(barrier)
    }
    
}
