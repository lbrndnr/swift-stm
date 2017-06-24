//
//  Reference.swift
//  SwiftSTM
//
//  Created by Laurin Brandner on 29.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation
import Atomics

protocol Referenceable: AnyObject {
    
    func commit()
    func rollback()
    
    func freeze()
    func reset(unfreeze: Bool)
    
    var debugInfo: Any? { get }
    
}

public typealias Ref<V> = Reference<V>

public final class Reference<V> : Referenceable {
    
    var signature = Signature()
    
    fileprivate var value: V
    fileprivate var newValue: V?
    
    private var readingBarrierCount = AtomicInt(0)
    private var writingBarrierHash = AtomicInt(0)
    private var degree = AtomicInt(0)
    
    private var currentBarrier: Barrier? {
        return Thread.current.barrier
    }
    
    public var debugInfo: Any?
    
    // MARK: - Initialization
    
    public init(_ value: V) {
        self.value = value
        self.signature.reference = self
    }
    
    // MARK: -
    
    public func get() throws -> V {
        guard let barrier = currentBarrier else {
            throw TransactionError.noBarrier
        }
        
        let hash = writingBarrierHash.load()
        guard hash == barrier.hashValue || hash == 0 else {
            throw TransactionError.collision
        }
        
        if !barrier.isReading(signature: signature) && !barrier.isWriting(signature: signature) {
            markAsRead()
        }
        barrier.markAsRead(using: signature)
        
        return newValue ?? value
    }
    
    public func set(_ val: V) throws {
        guard let barrier = currentBarrier else {
            throw TransactionError.noBarrier
        }
        
        guard degree.load() == 0 else {
            throw TransactionError.collision
        }
        
        guard writingBarrierHash.load() == barrier.hashValue || writingBarrierHash.CAS(current: 0, future: barrier.hashValue) else {
            throw TransactionError.collision
        }
        
        unmarkAsRead(by: barrier)
        barrier.markAsWritten(using: signature)
        
        guard readingBarrierCount.load() == 0 else {
            throw TransactionError.collision
        }
        
        newValue = val
    }
    
    func commit() {
        value = newValue ?? value
        newValue = nil
        
        writingBarrierHash.store(0)
    }
    
    func rollback() {
        newValue = nil
        writingBarrierHash.store(0)
    }
    
    func freeze() {
        degree.decrement()
    }
    
    func reset(unfreeze: Bool) {
        guard let barrier = currentBarrier else {
            return
        }
        
        unmarkAsRead(by: barrier)
        if unfreeze {
            degree.increment()
        }
    }
    
    func markAsRead() {
        readingBarrierCount.increment()
    }
    
    func unmarkAsRead(by barrier: Barrier) {
        if barrier.isReading(signature: signature) {
            readingBarrierCount.decrement()
        }
    }
    
}

extension Reference: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Reference(value: \(value), info:\(debugInfo ?? ""))"
    }
}
