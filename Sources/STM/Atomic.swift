//
//  Atomic.swift
//  STM
//
//  Created by Laurin Brandner on 31.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

public typealias AtomicBlock = () -> ()

public func atomic(transaction: @escaping AtomicBlock) {
    Thread.current.barrier.apply(transaction, main: true)
}

public func orAtomic(transaction: @escaping AtomicBlock) {
    Thread.current.barrier.apply(transaction, main: false)
}

public func retry() {
    Thread.current.barrier.retry()
}
