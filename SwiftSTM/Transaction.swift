//
//  Transaction.swift
//  SwiftSTM
//
//  Created by Laurin Brandner on 31.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

public typealias Transaction = () throws -> ()

public func atomic(transaction: @escaping Transaction) {
    let thread = Thread.current
    
    if Thread.current.barrier == nil {
        let barrier = Barrier()
        barrier.thread = thread
        
        thread.barrier = barrier
    }
    
    let barrier = thread.barrier!
    barrier.transaction = transaction
    barrier.execute()
}

public func retry() {
    guard let barrier = Thread.current.barrier else {
        return
    }
    
    barrier.retry()
}
