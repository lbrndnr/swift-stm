//
//  Barrier.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

private let transactionNotificationName = Notification.Name("didCommitTransaction")

final class Barrier {
    
    weak var thread: Thread?
    
    let identifier: Identifier
    
    fileprivate var reads = Set<Signature>()
    fileprivate var writes = [Signature: Any]()
    
    private var transaction: Transaction?
    private var backoff = BackoffIterator()
    private var blocked = false
    private var collided = false
    
    // MARK: - Initialization
    
    init() {
        identifier = Manager.shared.generateNewIdentifier()
    }
    
    deinit {
        Manager.shared.recycle(identifier)
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
    
    func retry() {
        retry(in: nil)
    }
    
    private func retry(in delay: TimeInterval?) {
        if let delay = delay {
            Thread.sleep(forTimeInterval: delay)
        }

        if let transaction = transaction {
            perform(transaction)
        }
    }
    
}

extension Barrier: Hashable {
    
    var hashValue: Int {
        return identifier.hashValue
    }
    
}

extension Barrier: Equatable {
    
    static func == (lhs: Barrier, rhs: Barrier) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
}
