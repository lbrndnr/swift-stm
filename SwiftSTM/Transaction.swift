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
