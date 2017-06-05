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
    
}

public typealias Ref<V: Any> = Reference<V>

public final class Reference<V> : Referenceable {
    
    var signature = Signature()
    
    fileprivate var value: V
    fileprivate var newValue: V?
    
    private var firstBarrierHash = AtomicInt(0)
    private var threadBarrier: Barrier? {
        return Thread.current.barrier
    }
    
    public var debugInfo: Any?
    
    // MARK: - Initialization
    
    public init(_ value: V) {
        self.value = value
        self.signature.reference = self
    }
    
    // MARK: -
    
    private func log() throws {
        guard let threadBarrier = threadBarrier else {
            throw TransactionError.noBarrier
        }
        
        if firstBarrierHash.load() != threadBarrier.hashValue && !firstBarrierHash.CAS(current: 0, future: threadBarrier.hashValue) {
            throw TransactionError.conflict
        }
    }
    
    public func get() throws -> V {
        try log()
        threadBarrier?.markAsRead(signature: signature)
        
        return value
    }
    
    public func set(_ val: V) throws {
//        print("set \(self) on \(String(describing: threadBarrier?.hashValue))")
        
        try log()
        threadBarrier?.markAsWritten(signature: signature)
        
        newValue = val
    }
    
    func commit() {
        guard let val = newValue else {
            return
        }
        
//        print("commit \(self) on \(String(describing: threadBarrier?.hashValue))")
        
        value = val
        newValue = nil
        firstBarrierHash.store(0)
    }
    
    func rollback() {
//        print("rollback \(self) on \(String(describing: threadBarrier?.hashValue))")
        
        newValue = nil
        firstBarrierHash.store(0)
    }
    
}

extension Reference: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Reference(value: \(value), info:\(debugInfo ?? ""))"
    }
}
