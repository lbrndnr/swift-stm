//
//  Barrier.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

private let transactionNotificationName = Notification.Name("didCommitTransaction")

class Barrier {
    
    weak var thread: Thread?
    
    let identifier: Identifier
    var transaction: Transaction? {
        didSet {
            backoff = BackoffIterator()
        }
    }
    
    fileprivate var readReferences = Set<Signature>()
    fileprivate var writtenReferences = Set<Signature>()
    
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
        return readReferences.contains(signature)
    }
    
    func isWriting(_ signature: Signature) -> Bool {
        return writtenReferences.contains(signature)
    }
    
    func markAsRead(using signature: Signature) {
        readReferences.update(with: signature)
    }
    
    func markAsWritten(using signature: Signature) {
        writtenReferences.update(with: signature)
    }
    
    func execute() {
        guard let transaction = transaction else {
            return
        }
        
        transaction()
        
        writtenReferences.forEach { $0.reference?.commit() }
        readReferences.forEach { $0.reference?.reset() }
        
        writtenReferences.removeAll()
        readReferences.removeAll()
        
        NotificationCenter.default.post(name: transactionNotificationName, object: self)
    }
    
    func wait(for barrier: Barrier, conflict signature: Signature) {
        writtenReferences.forEach { $0.reference?.rollback() }
        readReferences.forEach { $0.reference?.reset() }
        
        writtenReferences.removeAll()
        readReferences.removeAll()
        
        blocked = barrier.isAccessing(signature)
        print("block", identifier)
        if blocked {
            NotificationCenter.default.addObserver(forName: transactionNotificationName, object: barrier, queue: .main) { _ in
                print("unblock", barrier.identifier)
                self.blocked = false
            }
            
            while (blocked ) {}
        }
        
        execute()
    }
    
    func retry() {
        
    }
    
}
