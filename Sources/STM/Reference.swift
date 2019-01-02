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
    func reset(reads: Bool, writes: Bool)
    
    func lock()
    func unlock()
    
}

public typealias Ref<V> = Reference<V>

public final class Reference<Value>: Referenceable {
    
    var signature = Signature()
    
    private var value: Value
    
    private var barrier: Barrier {
        return Thread.current.barrier
    }
    
    private var readers = AtomicLinkedList<Barrier>()
    private var writers = AtomicLinkedList<Barrier>()
    private var commitLock = OS_SPINLOCK_INIT
    
    // MARK: - Initialization
    
    public init(_ v: Value) {
        value = v
        signature.reference = self
    }
    
    // MARK: -
    
    public func get() -> Value {
        if !barrier.isReading(signature) {
            readers.prepend(barrier)
        }
        
        return barrier.read(signature) as? Value ?? value
    }
    
    public func set(_ newValue: Value) {
        if !barrier.isWriting(signature) {
            writers.prepend(barrier)
        }
        
        barrier.write(newValue, to: signature)
    }
    
    func lock() {
        OSSpinLockLock(&commitLock)
    }
    
    func unlock() {
        OSSpinLockUnlock(&commitLock)
    }
    
    func commit() {
        if let newValue = barrier.read(signature) as? Value {
            value = newValue
        }
        
        if barrier.isWriting(signature) {
            readers.filter { $0 != barrier }
                   .forEach { $0.abort() }
        }
        
        writers.filter { $0 != barrier }
               .forEach { $0.abort() }
        
        reset(reads: true, writes: true)
    }
    
    func reset(reads: Bool, writes: Bool) {
        if reads && barrier.isReading(signature) {
            readers.remove(barrier)
        }
        if writes && barrier.isWriting(signature) {
            writers.remove(barrier)
        }
    }
        
}

extension Reference: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Ref(\(value))"
    }
    
}
