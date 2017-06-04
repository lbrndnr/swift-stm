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
    var transaction: Transaction?
    
    var readReferences = Set<AnyHashable>()
    var writtenReferences = Set<AnyHashable>()
    
    var overlappingThreads = Set<Thread>()
    
    // MARK: - Initialization
    
    init() {
        self.identifier = UUID().uuidString
    }
    
    // MARK: -
    
    func execute() {
        guard let transaction = transaction else {
            return
        }
        
        do {
            try transaction()
            
            writtenReferences.forEach { p in
                guard let ref = p.base as? Ref<Int> else {
                    return
                }
                
                ref.commit()
            }
        }
        catch TransactionError.conflict {
            writtenReferences.forEach { p in
                guard let ref = p.base as? Ref<Int> else {
                    return
                }
                
                ref.rollback()
            }
        }
        catch (let error) {
            
        }
        defer {
            writtenReferences.removeAll()
            readReferences.removeAll()
            overlappingThreads.removeAll()
        }
    }
    
    func retry(in time: TimeInterval? = nil) {
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
