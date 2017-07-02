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

private let writeMask: UInt64 = 0xFFFFFFFF00000000
private let readMask: UInt64 = 0xFFFFFFFF

public final class Reference<V> : Referenceable {
    
    var signature = Signature()
    
    fileprivate var value: V
    fileprivate var newValue: V?
    
    private var access = AtomicUInt64(0)
    
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
    
    private func writingBarrier(from: UInt64) -> UInt64 {
        return (from & writeMask) >> 32
    }
    
    private func numberOfReads(from: UInt64) -> UInt64 {
        return from & readMask
    }
    
    public func get() throws -> V {
        guard let barrier = currentBarrier else {
            throw TransactionError.noBarrier
        }
        
        let sID = UInt64(barrier.identifier) << 32
        let cr = numberOfReads(from: access.load())
        let nr: UInt64 = barrier.isReading(signature: signature) ? cr : cr + 1
        let previouslyRead = access.CAS(current: sID + cr, future: sID + nr)
        let noPreviousRead = access.CAS(current: cr, future: nr)
        
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
        
        let sID = UInt64(barrier.identifier) << 32
        let cr = numberOfReads(from: access.load())
        let previouslyWritten = access.CAS(current: sID + cr, future: sID + cr)
        let noPreviousRead = barrier.isReading(signature: signature) && access.CAS(current: 1, future: sID + 1)
        let noPreviousAccess = access.CAS(current: 0, future: sID)
        
        guard noPreviousRead || noPreviousAccess || previouslyWritten else {
            throw TransactionError.collision
        }
        
        barrier.markAsWritten(using: signature)
        newValue = val
    }

    func commit() {
        value = newValue ?? value
        rollback()
    }
    
    func rollback() {
        newValue = nil
        access.bitwiseAnd(readMask)
    }
    
    func reset() {
        access.decrement()
    }
    
}

extension Reference: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Reference(value: \(value), info:\(debugInfo ?? ""))"
    }
}

extension String {
    /// optionally change to use "Character" type instead
    public func pad(with padding: String, toLength length: Int) -> String {
        let paddingWidth = length - self.characters.count
        guard paddingWidth > 0 else { return self }
        
        return String(repeating: padding, count: paddingWidth) + self
    }
}

extension UInt64 {
    
    var bits: String {
        let str = String(self, radix: 2).pad(with: "0", toLength: 64)
        let head = str.substring(to: str.index(str.startIndex, offsetBy: 32))
        let tail = str.substring(from: str.index(str.startIndex, offsetBy: 32))
        
        guard head.lengthOfBytes(using: .utf8) == tail.lengthOfBytes(using: .utf8) else {
            abort()
        }
        
        return head + "|" + tail
    }
    
}
