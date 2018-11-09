//
//  Barrier.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

private let transactionNotificationName = Notification.Name("didCommitTransaction")

private let semaphore = DispatchSemaphore(value: 1)

final class Barrier {
    
    weak var thread: Thread?
    
    let identifier: Identifier
    var transaction: Transaction? {
        didSet {
            backoff = BackoffIterator()
        }
    }
    
    fileprivate var reads = Set<Signature>()
    fileprivate var writes = [Signature: Any]()
    
    private var backoff = BackoffIterator()
    private var blocked = false
    
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
    
    func execute() {
        guard let transaction = transaction else {
            return
        }
        
        transaction()
        
        semaphore.wait()
        
        writes.forEach { (signature, _) in
            signature.reference?.commit()
        }
        reads.forEach { $0.reference?.reset(reads: true, writes: false) }
        
        semaphore.signal()
        
        writes.removeAll()
        reads.removeAll()
        
        NotificationCenter.default.post(name: transactionNotificationName, object: self)
    }
    
    func wait(for barrier: Barrier, conflict signature: Signature) {
//        writtenReferences.forEach { $0.reference?.rollback() }
//        readReferences.forEach { $0.reference?.reset() }
//        
//        writtenReferences.removeAll()
//        readReferences.removeAll()
//        
//        blocked = barrier.isAccessing(signature)
//        print("block", identifier)
//        if blocked {
//            NotificationCenter.default.addObserver(forName: transactionNotificationName, object: barrier, queue: .main) { _ in
//                print("unblock", barrier.identifier)
//                self.blocked = false
//            }
//            
//            while (blocked ) {}
//        }
//        
//        execute()
    }
    
    func retry() {
        
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
