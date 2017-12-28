//
//  Barrier.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

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
    
    // MARK: - Initialization
    
    init() {
        self.identifier = Manager.shared.generateNewIdentifier()
    }
    
    deinit {
        Manager.shared.recycle(identifier)
    }
    
    // MARK: -
    
    func isReading(signature: Signature) -> Bool {
        return readReferences.contains(signature)
    }
    
    func isWriting(signature: Signature) -> Bool {
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
        
        do {
            try transaction()
            
            writtenReferences.forEach { $0.reference?.commit() }
            readReferences.forEach { $0.reference?.reset() }
            
            writtenReferences.removeAll()
            readReferences.removeAll()
        }
        catch TransactionError.collision {
            print("collision")
            writtenReferences.forEach { $0.reference?.rollback() }
            readReferences.forEach { $0.reference?.reset() }
            
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
//            print("go to sleep \(identifier) for \(time) at \(Date())")
            Thread.sleep(forTimeInterval: time)
//            print("good morning \(identifier) at \(Date())")
        }
        
        execute()
    }
    
}
