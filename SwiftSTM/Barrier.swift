//
//  Barrier.swift
//  SwiftSTM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

class Barrier {
    
    fileprivate let identifier: String
    var transaction: Transaction? {
        didSet {
            backoff = BackoffIterator()
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
    
    func markAsRead(signature: Signature) {
        if !writtenReferences.contains(signature) {
            readReferences.update(with: signature)
        }
    }
    
    func markAsWritten(signature: Signature) {
        writtenReferences.update(with: signature)
        readReferences.remove(signature)
    }
    
    func execute() {
        guard let transaction = transaction else {
            return
        }
        
        do {
            try transaction()
            
            writtenReferences.forEach { $0.reference?.commit() }
            readReferences.forEach { $0.reference?.rollback() }
        }
        catch TransactionError.conflict {
            writtenReferences.forEach { $0.reference?.rollback() }
            readReferences.forEach { $0.reference?.rollback() }
            
            if let time = backoff.next() {
                retry(in: time)
            }
        }
        catch (let error) {
            print(error)
        }
        defer {
            writtenReferences.removeAll()
            readReferences.removeAll()
        }
    }
    
    func retry(in time: TimeInterval? = nil) {
        if let time = time {
            print("go to sleep \(identifier) for \(time) at \(Date())")
            Thread.sleep(forTimeInterval: time)
            print("good morning \(identifier) at \(Date())")
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
