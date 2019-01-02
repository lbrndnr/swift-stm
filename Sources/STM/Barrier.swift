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

enum Status {
    case normal
    case failed
}

fileprivate enum Transaction {
    case pending(AtomicBlock)
    case failed(AtomicBlock)
    case retried(AtomicBlock)
}

extension Transaction {
    
    func fail() -> Transaction {
        switch self {
        case .pending(let b):
            return .failed(b)
        case .retried(let b):
            return .failed(b)
        default:
            return self
        }
    }
    
    func retry() -> Transaction {
        switch self {
        case .pending(let b):
            return .retried(b)
        case .failed(let b):
            return .retried(b)
        default:
            return self
        }
    }
    
}

final class Barrier: Identifiable {
    
    let ID: UInt64
    
    var status: Status {
        guard let last = transactions.last else {
            return .normal
        }
        
        switch last {
        case .pending(_):
            return .normal
        default:
            return .failed
        }
    }
    
    fileprivate var transactions = [Transaction]()
    private var reads = Set<Signature>()
    private var writes = [Signature: Any]()
    
    private var backoff = BackoffIterator()
    
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
    
    func apply(_ block: @escaping AtomicBlock, main: Bool) {
        if main {
            transactions = [.pending(block)]
        }
        else if status == .failed {
            transactions.append(.pending(block))
        }
        else {
            return
        }
        
        backoff = BackoffIterator()
        block()
        
        let accesses = Set(Array(writes.keys) + Array(reads)).sorted { $0.ID < $1.ID }
        func rollback() {
            accesses.forEach { $0.reference?.reset(reads: true, writes: true) }
            
            writes.removeAll()
            reads.removeAll()
            
            retry(in: backoff.next())
        }
        
        guard status == .normal else {
            rollback()
            
            return
        }
        
        accesses.forEach { $0.reference?.lock() }
        
        guard status == .normal else {
            accesses.forEach { $0.reference?.unlock() }
            rollback()
            
            return
        }
        
        accesses.forEach { $0.reference?.commit() }
        accesses.forEach { $0.reference?.unlock() }
        
        writes.removeAll()
        reads.removeAll()
        transactions.removeAll()
        
        NotificationCenter.default.post(name: transactionNotificationName, object: self)
    }
    
    func abort() {
        guard let last = transactions.last else {
            return
        }
        
        transactions.removeLast()
        transactions.append(last.fail())
    }
    
    func retry(in delay: TimeInterval? = nil) {
        guard let last = transactions.last else {
            return
        }
        
        transactions.removeLast()
        transactions.append(last.retry())
    }
    
}

extension Barrier: Equatable {
    
    static func ==(lhs: Barrier, rhs: Barrier) -> Bool {
        return lhs.ID == rhs.ID
    }
    
}
