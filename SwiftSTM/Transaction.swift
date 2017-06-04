//
//  Transaction.swift
//  SwiftSTM
//
//  Created by Laurin Brandner on 31.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

private let currentBarrierKey = "ch.laurinbrandner.stm.current-barrier"

public typealias Transaction = () -> ()

public func atomic(transaction: @escaping Transaction) {
    if Thread.current.barrier == nil {
        Thread.current.barrier = Barrier()
    }
    
    let barrier = Thread.current.barrier!
    barrier.transaction = transaction
    barrier.execute()
}

public func retry() {
    guard let barrier = Thread.current.barrier else {
        return
    }
    
    barrier.retry()
}

class Barrier {
    
    fileprivate let identifier: String
    fileprivate var transaction: Transaction?
    
    var readReferences = Set<AnyHashable>()
    var writtenReferences = Set<AnyHashable>()
    
    var overlappingThreads = Set<Thread>()
    
    // MARK: - Initialization
    
    init() {
        self.identifier = UUID().uuidString
    }
    
    // MARK: -
    
    fileprivate func execute() {
        guard let transaction = transaction else {
            return
        }
        
        transaction()
        
        let conflicting = writtenReferences.contains { p in
            guard let ref = p.base as? Ref<Int> else {
                return false
            }
            
            return ref.conflicting
        }
        
        if conflicting {
            writtenReferences.forEach { p in
                guard let ref = p.base as? Ref<Int> else {
                    return
                }
                
                ref.rollback()
            }
        }
        else {
            writtenReferences.forEach { p in
                guard let ref = p.base as? Ref<Int> else {
                    return
                }
                
                ref.commit()
            }
        }
        
        writtenReferences.removeAll()
        readReferences.removeAll()
        overlappingThreads.removeAll()
    }
    
    fileprivate func retry(in time: TimeInterval? = nil) {
//        if let time = time {
//            let delay = DispatchTime.now() + time
//            DispatchQueue.
//        }
//        else {
//            execute()
//        }
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

extension Thread {
    
    var barrier: Barrier? {
        get {
            return threadDictionary[currentBarrierKey] as? Barrier
        }
        set {
            threadDictionary[currentBarrierKey] = newValue
        }
    }
    
}
