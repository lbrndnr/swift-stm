//
//  SwiftSTMTests.swift
//  SwiftSTMTests
//
//  Created by Laurin Brandner on 29.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import XCTest
@testable import SwiftSTM

private let amount = 1
private let initialBalance = 100_000
private let accounts = 10_000
private let transactions = 20_000

class SwiftSTMTests: XCTestCase {
    
    var bank = Bank(accounts: [])
    var sum = 0
    
    override func setUp() {
        super.setUp()
        
        let accs = (0 ..< accounts).map { Account(ID: $0, balance: initialBalance) }
        
        bank = Bank(accounts: accs)
        sum = bank.totalValue
    }
    
    private func doTransactions() {
        (0 ..< transactions).forEach { _ in
            let fromID = Int(arc4random_uniform(UInt32(accounts)))
            let toID = Int(arc4random_uniform(UInt32(accounts)))
            
            let from = bank.accounts[fromID]
            let to = bank.accounts[toID]
            
            bank.transfer(from: from, to: to, amount: amount)
        }
    }
    
    func testBank() {
        doTransactions()
        XCTAssertEqual(sum, bank.totalValue)
    }
    
    func testBankParallel() {
        let cores = ProcessInfo.processInfo.activeProcessorCount
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = cores
        
        (0 ..< cores).forEach { _ in
             queue.addOperation(doTransactions)
        }
        
        queue.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(sum, bank.totalValue)
    }
    
}
