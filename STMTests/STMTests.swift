//
//  STMTests.swift
//  STMTests
//
//  Created by Laurin Brandner on 29.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import XCTest
@testable import STM

private let initialBalance = 1_000_000
private let accounts = 100000
private let transactions = 100_000

class STMTests: XCTestCase {
    
    var bank = Bank(accounts: [])
    var sum = 0
    
    override func setUp() {
        super.setUp()
        
        let accs = (0 ..< accounts).map { Account(ID: $0, balance: initialBalance) }
        
        bank = Bank(accounts: accs)
        sum = accounts * initialBalance
    }
    
    private func doTransactions(from fID: Int? = nil, to tID: Int? = nil) {
        (0 ..< transactions).forEach { i in
            let fromID = fID ?? Int(arc4random_uniform(UInt32(accounts)))
            let toID = tID ?? Int(arc4random_uniform(UInt32(accounts)))
            
            let from = bank.accounts[fromID]
            let to = bank.accounts[toID]
            
            bank.transfer(from: from, to: to, amount: i)
        }
    }
    
    func testBank() {
        doTransactions()
        XCTAssertEqual(sum, bank.totalValue)
    }
    
    private func doTransactionsParallel(from fID: Int? = nil, to tID: Int? = nil, queues: Int = ProcessInfo.processInfo.activeProcessorCount) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = queues
        
        (0 ..< queues).forEach { _ in
            queue.addOperation {
                self.doTransactions(from: fID, to: tID)
            }
        }
        
        queue.waitUntilAllOperationsAreFinished()
    }
    
    func testBankParallel() {
        doTransactionsParallel(queues: 16)
        XCTAssertEqual(sum, bank.totalValue)
    }
    
    func testDeadlock() {
        doTransactionsParallel(to: 0)
        XCTAssertEqual(sum, bank.totalValue)
    }
    
    func testMultipleWrites() {
        doTransactionsParallel(from: 0, to: 0)
        XCTAssertEqual(sum, bank.totalValue)
    }
    
}
