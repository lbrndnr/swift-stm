//
//  SwiftSTMTests.swift
//  SwiftSTMTests
//
//  Created by Laurin Brandner on 29.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import XCTest
@testable import SwiftSTM

private let initialBalance = 1_000_000
private let accounts = 20
private let transactions = 30_000

class SwiftSTMTests: XCTestCase {
    
    var bank = Bank(accounts: [])
    var sum = 0
    
    override func setUp() {
        super.setUp()
        
        let accs = (0 ..< accounts).map { Account(ID: $0, balance: initialBalance) }
        
        bank = Bank(accounts: accs)
        sum = accounts * initialBalance
    }
    
    private func doTransactions(with ID: Int? = nil) {
        (0 ..< transactions).forEach { i in
            let fromID = Int(arc4random_uniform(UInt32(accounts)))
            let toID = ID ?? Int(arc4random_uniform(UInt32(accounts)))
            
            let from = bank.accounts[fromID]
            let to = bank.accounts[toID]
            
            bank.transfer(from: from, to: to, amount: i)
        }
    }
    
    func testMultipleWrites() {
        let acc = bank.accounts[0]
        bank.transfer(from: acc, to: acc, amount: 1)
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
            queue.addOperation {
                self.doTransactions()
            }
        }
        
        queue.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(sum, bank.totalValue)
    }
    
    func testProgression() {
        let cores = ProcessInfo.processInfo.activeProcessorCount
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = cores
        
        (0 ..< cores).forEach { _ in
            queue.addOperation {
                self.doTransactions(with: 1)
            }
        }
        
        queue.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(sum, bank.totalValue)
    }
    
}
