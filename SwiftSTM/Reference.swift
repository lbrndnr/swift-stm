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
    
    @discardableResult func commit(from barrier: Barrier) -> Bool
    @discardableResult func rollback(from barrier: Barrier) -> Bool
    
    func verifyReadAccess(from barrier: Barrier) -> Bool
    func verifyWriteAccess(from barrier: Barrier) -> Bool
    
}

public typealias Ref<V> = Reference<V>

public final class Reference<V> : Referenceable {
    
    var signature = Signature()
    
    fileprivate var value: V
    fileprivate var newValue: V?
    
    private var readingBarrierCount = AtomicInt(0)
    private var writingBarrierHash = AtomicInt(0)
    private var blockingBarrierHash = AtomicInt(0)
    
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
        
        guard blockingBarrierHash.load() == 0 else {
            throw TransactionError.collision
        }
        
        let hash = writingBarrierHash.load()
        guard hash == barrier.hashValue || hash == 0 else {
            //print("\(self) collided on \(hash) with \(barrier.hashValue)")
            throw TransactionError.collision
        }
        
        //print("mark \(self) as read on \(barrier.hashValue)")
        if !barrier.isReading(signature: signature) {
            incrementReadingBarrierCount()
        }
        barrier.markAsRead(using: signature)
        
        return newValue ?? value
    }
    
    public func set(_ val: V) throws {        
        guard let barrier = currentBarrier else {
            throw TransactionError.noBarrier
        }
        
        guard blockingBarrierHash.load() == 0 else {
            throw TransactionError.collision
        }
        
        guard writingBarrierHash.load() == barrier.hashValue || writingBarrierHash.CAS(current: 0, future: barrier.hashValue) else {
            //print("\(self) collided on \(writingBarrierHash.load()) with \(barrier.hashValue)")
            throw TransactionError.collision
        }
        
        let onlyBarrierReading = (readingBarrierCount.load() == 0) || (readingBarrierCount.load() == 1 && barrier.isReading(signature: signature))
        guard onlyBarrierReading else {
            throw TransactionError.collision
        }
        
        //print("mark \(self) as written on \(barrier.hashValue)")
        let readBefore = barrier.markAsWritten(using: signature)
        if readBefore {
            decrementReadingBarrierCount()
        }
        
        newValue = val
    }
    
    func verifyReadAccess(from barrier: Barrier) -> Bool {
        return writingBarrierHash.load() == 0 && blockingBarrierHash.CAS(current: 0, future: barrier.hashValue)
    }
    
    func verifyWriteAccess(from barrier: Barrier) -> Bool {
        return writingBarrierHash.load() == barrier.hashValue && blockingBarrierHash.CAS(current: 0, future: barrier.hashValue)
    }
    
    @discardableResult func commit(from barrier: Barrier) -> Bool {
        guard blockingBarrierHash.load() == barrier.hashValue else {
            return false
        }
        
        guard writingBarrierHash.load() == barrier.hashValue else {
            print("wtf")
            return false
        }
        
        value = newValue ?? value
        newValue = nil
        writingBarrierHash.store(0)
        decrementReadingBarrierCount()
        blockingBarrierHash.store(0)
        
        //print("commit \(self) on \(barrier.hashValue)")
        
        return true
    }
    
    @discardableResult func rollback(from barrier: Barrier) -> Bool {
        let hash = blockingBarrierHash.load()
        guard hash == barrier.hashValue || hash == 0 else {
            return false
        }
        
        newValue = nil
        writingBarrierHash.store(0)
        decrementReadingBarrierCount()
        blockingBarrierHash.store(0)
        
        //print("rollback \(self) on \(barrier.hashValue)")
        
        return true
    }
    
    private func incrementReadingBarrierCount() {
        readingBarrierCount.increment()
    }
    
    private func decrementReadingBarrierCount() {
        readingBarrierCount.decrement()
        if readingBarrierCount.load() < 0 {
            readingBarrierCount.store(0)
        }
    }
    
}

extension Reference: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Reference(value: \(value), info:\(debugInfo ?? ""))"
    }
}
