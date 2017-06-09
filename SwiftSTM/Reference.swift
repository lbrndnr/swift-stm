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
    
    @discardableResult func commit() -> Bool
    @discardableResult func rollback() -> Bool
    
    func verifyReadAccess(from barrier: Barrier) -> Bool
    func verifyWriteAccess(from barrier: Barrier) -> Bool
    
}

public typealias Ref<V> = Reference<V>

public final class Reference<V> : Referenceable {
    
    var signature = Signature()
    
    fileprivate var value: V
    fileprivate var newValue: V?
    
    private var blocked = AtomicBool(false)
    private var writingBarrierHash = AtomicInt(0)
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
        guard let currentBarrier = currentBarrier else {
            throw TransactionError.noBarrier
        }
        
        if blocked.load() {
            throw TransactionError.collision
        }
        
        let hash = writingBarrierHash.load()
        if hash != currentBarrier.hashValue && hash != 0 {
            throw TransactionError.collision
        }
        
        currentBarrier.markAsRead(signature: signature)
        
        return newValue ?? value
    }
    
    public func set(_ val: V) throws {
        guard let currentBarrier = currentBarrier else {
            throw TransactionError.noBarrier
        }
        
        if blocked.load() {
            throw TransactionError.collision
        }
        
        if writingBarrierHash.load() != currentBarrier.hashValue && !writingBarrierHash.CAS(current: 0, future: currentBarrier.hashValue) {
            throw TransactionError.collision
        }
        
        currentBarrier.markAsWritten(signature: signature)
        
        newValue = val
    }
    
    func verifyReadAccess(from barrier: Barrier) -> Bool {
        return blocked.CAS(current: false, future: true) && writingBarrierHash.load() == 0
    }
    
    func verifyWriteAccess(from barrier: Barrier) -> Bool {
        return blocked.CAS(current: false, future: true) && writingBarrierHash.load() == barrier.hashValue
    }
    
    @discardableResult func commit() -> Bool {
        guard let val = newValue,
          let barrier = currentBarrier, writingBarrierHash.load() == barrier.hashValue else {
            return false
        }
        
        value = val
        newValue = nil
        writingBarrierHash.store(0)
        blocked.store(false)
        
        return true
    }
    
    @discardableResult func rollback() -> Bool {
        guard let barrier = currentBarrier, writingBarrierHash.load() == barrier.hashValue else {
            return false
        }
//        print("rollback \(self) on \(String(describing: currentBarrier?.hashValue))")
        
        newValue = nil
        writingBarrierHash.store(0)
        blocked.store(false)
        
        return true
    }
    
}

extension Reference: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Reference(value: \(value), info:\(debugInfo ?? ""))"
    }
}
