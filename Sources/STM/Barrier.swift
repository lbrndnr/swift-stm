//
//  Barrier.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation
import Atomics

private let transactionNotificationName = Notification.Name("didCommitTransaction")

private var IDCounter = AtomicUInt64()

final class Barrier: Identifiable {
    
    weak var thread: Thread?
    
    let ID: UInt64
    
    private var reads = Set<Signature>()
    private var writes = [Signature: Any]()
    
    private var transaction: Transaction?
    private var backoff = BackoffIterator()
    var collided = false
    
    // MARK: - Initialization
    
    init() {
        ID = IDCounter.increment()
    }
    
    // MARK: -
    
    func isAccessing(_ signature: Signature) -> Bool {
        return isReading(signature) || isWriting(signature)
    }
    
    func isReading(_ signature: Signature) -> Bool {
        return reads.contains(signature)
    }
    
    func isWriting(_ signature: Signature) -> Bool {
        return writes.keys.contains(signature)
    }
    
    func read(_ signature: Signature) -> Any? {
        guard let element = writes[signature] else {
            reads.update(with: signature)
            return nil
        }
        
        return element
    }
    
    func write(_ element: Any, to signature: Signature) {
        writes[signature] = element
    }
    
    func perform(_ t: @escaping Transaction) {
        backoff = BackoffIterator()
        collided = false
        transaction = t
        
        t()
        
        let accesses = Set(Array(writes.keys) + Array(reads)).sorted { $0.ID < $1.ID }
        func rollback() {
            accesses.forEach { $0.reference?.reset(reads: true, writes: true) }
            
            writes.removeAll()
            reads.removeAll()
            
            retry(in: backoff.next())
        }
        
        guard !collided else {
            rollback()
            
            return
        }
        
        accesses.forEach { $0.reference?.lock() }
        
        guard !collided else {
            accesses.forEach { $0.reference?.unlock() }
            rollback()
            
            return
        }
        
        accesses.forEach { $0.reference?.commit() }
        accesses.forEach { $0.reference?.unlock() }
        
        writes.removeAll()
        reads.removeAll()
        transaction = nil
        
        NotificationCenter.default.post(name: transactionNotificationName, object: self)
    }
    
    func abort() {
        collided = true
    }
    
    func retry(in delay: TimeInterval? = nil) {
        if let delay = delay {
            Thread.sleep(forTimeInterval: delay)
        }

        if let transaction = transaction {
            perform(transaction)
        }
    }
    
}

extension Barrier: Equatable {
    
    static func ==(lhs: Barrier, rhs: Barrier) -> Bool {
        return lhs.ID == rhs.ID
    }
    
}
