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
    func reset()
    
    var debugInfo: Any? { get }
    
}

public typealias Ref<V> = Reference<V>

public final class Reference<V> : Referenceable {
    
    var signature = Signature()
    
    fileprivate var value: V
    fileprivate var newValue: V?
    
    private var access = AtomicInt64(0)
    
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
    
    var writingBarrier: Int64 {
        return access.load() & 0xFFFFFF00
    }
    
    var numberOfReads: Int64 {
        return access.load() & 0xFF
    }
    
    public func get() throws -> V {
        guard let barrier = currentBarrier else {
            throw TransactionError.noBarrier
        }
        
        let cr = numberOfReads
        let nr: Int64 = barrier.isReading(signature: signature) ? cr : cr + 1
        let previouslyRead = access.CAS(current: Int64(barrier.hashValue << 16) + cr, future: Int64(barrier.hashValue << 16) + nr)
        let noPreviousRead = access.CAS(current: cr, future: Int64(barrier.hashValue << 16) + nr)
        
        guard noPreviousRead || previouslyRead else {
            throw TransactionError.collision
        }
        
        barrier.markAsRead(using: signature)
        return newValue ?? value
    }
    
    public func set(_ val: V) throws {
        guard let barrier = currentBarrier else {
            throw TransactionError.noBarrier
        }
        
        let cr = numberOfReads
        let previouslyWritten = access.CAS(current: Int64(barrier.hashValue << 16) + cr, future: Int64(barrier.hashValue << 16) + cr)
        let noPreviousWrite = access.CAS(current: cr, future: Int64(barrier.hashValue << 16) + cr)
        
        guard noPreviousWrite || previouslyWritten else {
            throw TransactionError.collision
        }
        
        barrier.markAsWritten(using: signature)
        newValue = val
    }

    func commit() {
        value = newValue ?? value
        newValue = nil
        
        while !access.CAS(current: access.load(), future: numberOfReads) {
        
        }
    }
    
    func rollback() {
        newValue = nil
        while !access.CAS(current: access.load(), future: numberOfReads) {
        
        }
    }
    
    func reset() {
        var a = access.load()
        var cr = numberOfReads

        while !access.CAS(current: (a & 0xFFFFFF00) + cr , future: (a & 0xFFFFFF00) + cr - 1) {
            a = access.load()
            cr = numberOfReads
        }
    }
    
}

extension Reference: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Reference(value: \(value), info:\(debugInfo ?? ""))"
    }
}
