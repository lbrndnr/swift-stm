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
    
    func commit(from barrier: Barrier) throws
    @discardableResult func rollback(from barrier: Barrier) -> Bool
    @discardableResult func reset(from barrier: Barrier) -> Bool
    
    func verifyReadAccess(from barrier: Barrier) throws
    func verifyWriteAccess(from barrier: Barrier) throws
    
}

public typealias Ref<V> = Reference<V>

public final class Reference<V> : Referenceable {
    
    var signature = Signature()
    
    fileprivate var value: V
    fileprivate var newValue: V?
    
    private var readingBarrierCount = AtomicInt(0)
    private var writingBarrierHash = AtomicInt(0)
    private var freezingBarrierHash = AtomicInt(0)
    
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
            //print("\(self) collided on \(hash) with \(barrier.hashValue)")
            throw TransactionError.collision
        }
        
        guard freezingBarrierHash.load() == 0 else {
            throw TransactionError.collision
        }
        
        if !barrier.isReading(signature: signature) && !barrier.isWriting(signature: signature) {
            markAsRead()
        }
        
        //print("mark \(self) as read on \(barrier.hashValue)")
        barrier.markAsRead(using: signature)
        
        return newValue ?? value
    }
    
    public func set(_ val: V) throws {
        guard let barrier = currentBarrier else {
            throw TransactionError.noBarrier
        }
        
        guard writingBarrierHash.load() == barrier.hashValue || writingBarrierHash.CAS(current: 0, future: barrier.hashValue) else {
            //print("\(self) collided on \(writingBarrierHash.load()) with \(barrier.hashValue)")
            throw TransactionError.collision
        }
        
        guard freezingBarrierHash.load() == 0 else {
            throw TransactionError.collision
        }
        
        let onlyBarrierReading = (readingBarrierCount.load() == 0 || (readingBarrierCount.load() == 1 && barrier.isReading(signature: signature)))
        guard onlyBarrierReading else {
            throw TransactionError.collision
        }
        
        //print("mark \(self) as written on \(barrier.hashValue)")
        unmarkAsRead(by: barrier)
        barrier.markAsWritten(using: signature)
        
        newValue = val
    }
    
    func verifyReadAccess(from barrier: Barrier) throws {
        guard freezingBarrierHash.CAS(current: 0, future: barrier.hashValue) else {
            throw TransactionError.collision
        }
        
        guard writingBarrierHash.load() == 0 else {
            freezingBarrierHash.store(0)
            throw TransactionError.collision
        }
    }
    
    func verifyWriteAccess(from barrier: Barrier) throws {
        guard freezingBarrierHash.CAS(current: 0, future: barrier.hashValue) else {
            throw TransactionError.collision
        }
        
        guard writingBarrierHash.load() == barrier.hashValue else {
            freezingBarrierHash.store(0)
            throw TransactionError.collision
        }
    }
    
    func commit(from barrier: Barrier) throws {
        guard freezingBarrierHash.load() == barrier.hashValue else {
            print("ups what")
            throw TransactionError.unfrozen
        }
        
        value = newValue ?? value
        newValue = nil
        writingBarrierHash.store(0)
        freezingBarrierHash.store(0)
        
        //print("commit \(self) on \(barrier.hashValue)")
    }
    
    @discardableResult func rollback(from barrier: Barrier) -> Bool {
        let hash = freezingBarrierHash.load()
        guard hash == barrier.hashValue || hash == 0 else {
            return false
        }
        
        newValue = nil
        writingBarrierHash.store(0)
        freezingBarrierHash.store(0)
        
        //print("rollback \(self) on \(barrier.hashValue)")
        
        return true
    }
    
    @discardableResult func reset(from barrier: Barrier) -> Bool {
        unmarkAsRead(by: barrier)
        return freezingBarrierHash.CAS(current: barrier.hashValue, future: 0)
        
        //print("reset \(self) on \(barrier.hashValue)")
    }
    
    func markAsRead() {
        readingBarrierCount.increment()
    }
    
    func unmarkAsRead(by barrier: Barrier) {
        if barrier.isReading(signature: signature) {
            readingBarrierCount.decrement()
            if readingBarrierCount.load() < 0 {
                readingBarrierCount.store(0)
            }
        }
    }
    
}

extension Reference: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Reference(value: \(value), info:\(debugInfo ?? ""))"
    }
}
