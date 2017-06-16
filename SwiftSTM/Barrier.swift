//
//  Barrier.swift
//  SwiftSTM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

class Barrier {
    
    weak var thread: Thread?
    private(set) var priority = 0
    
    fileprivate let identifier: String
    var transaction: Transaction? {
        didSet {
            backoff = BackoffIterator()
            priority = 0
        }
    }
    
    fileprivate var readReferences = Set<Signature>()
    fileprivate var writtenReferences = Set<Signature>()
    
    private var backoff = BackoffIterator()
    
    // MARK: - Initialization
    
    init() {
        self.identifier = UUID().uuidString
    }
    
    // MARK: -
    
    func isReading(signature: Signature) -> Bool {
        return readReferences.contains(signature) || writtenReferences.contains(signature)
    }
    
    /// Marks the signature as read if it hasn't been written to before
    func markAsRead(using signature: Signature) {
        if !writtenReferences.contains(signature) {
            readReferences.update(with: signature)
        }
    }
    
    /// Marks the signature as written and overrides its previous state
    /// Returns true if it has been read before
    func markAsWritten(using signature: Signature) -> Bool {
        writtenReferences.update(with: signature)
        return readReferences.remove(signature) != nil
    }
    
    func execute() {
        guard let transaction = transaction else {
            return
        }
        
        do {
            try transaction()
            
            let readCollision = readReferences.contains { !($0.reference?.verifyReadAccess(from: self) ?? true) }
            let writeCollision = writtenReferences.contains { !($0.reference?.verifyWriteAccess(from: self) ?? true) }
            
            if readCollision || writeCollision {
                throw TransactionError.collision
            }
            
            let commitCollision = writtenReferences.contains { !($0.reference?.commit(from: self) ?? true) }
            let rollbackCollision = readReferences.contains { !($0.reference?.rollback(from: self) ?? true) }
            
            if commitCollision || rollbackCollision {
                throw TransactionError.collision
            }
            
            writtenReferences.removeAll()
            readReferences.removeAll()
        }
        catch TransactionError.collision {
            //print("collision on \(hashValue)")
            writtenReferences.forEach { $0.reference?.rollback(from: self) }
            
            //print("try rolling back \(readReferences.count) refs")
            readReferences.forEach { $0.reference?.rollback(from: self) }
            
            writtenReferences.removeAll()
            readReferences.removeAll()
            
            retry(in: backoff.next()!)
        }
        catch (let error) {
            print(error)
        }
    }
    
    func retry(in time: TimeInterval? = nil) {
        if let time = time {
            print("go to sleep \(hashValue) for \(time) at \(Date())")
            Thread.sleep(forTimeInterval: time)
            print("good morning \(hashValue) at \(Date())")
        }
        
        execute()
    }
    
}

extension Barrier: Equatable {
    
    var hashValue: Int {
        return identifier.hashValue
    }
    
}

func ==(lhs: Barrier, rhs: Barrier) -> Bool {
    return lhs.identifier == rhs.identifier
}
