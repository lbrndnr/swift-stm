//
//  PerformanceTests.swift
//  STMTests
//
//  Created by Laurin Brandner on 06.01.19.
//

import XCTest

private let initialBalance = 1_000_000
private let accounts = 100_000
private let transactions = 10_000

class PerformanceTests: XCTestCase {

    private func measure(bank: Bank, getRandomAccount: @escaping (() -> Account), transactions: Int, threads: Int) {
        measureMetrics(PerformanceTests.defaultPerformanceMetrics, automaticallyStartMeasuring: false) {
            let semaphore = DispatchSemaphore(value: threads)
            let group = DispatchGroup()
            let queue = DispatchQueue(label: "operations", attributes: .concurrent)
            
            startMeasuring()
            for i in 0..<transactions {
                semaphore.wait()
                group.enter()
                queue.async {
                    let from = getRandomAccount()
                    let to = getRandomAccount()
                    bank.transfer(from: from, to: to, amount: i)
                    
                    semaphore.signal()
                    group.leave()
                }
            }
            
            group.wait()
            stopMeasuring()
        }
    }
    
    func testSTMPerformance() {
        let accs = (0 ..< accounts).map { STMAccount(ID: $0, balance: initialBalance) }
        let bank = STMBank(accounts: accs)
        let getRandomAccount = {
            return accs.randomElement()!
        }
        
        measure(bank: bank, getRandomAccount: getRandomAccount, transactions: transactions, threads: 32)
    }
    
    func testDispatchPerformance() {
        let accs = (0 ..< accounts).map { DispatchAccount(ID: $0, balance: initialBalance) }
        let bank = DispatchBank(accounts: accs)
        let getRandomAccount = {
            return accs.randomElement()!
        }
        
        measure(bank: bank, getRandomAccount: getRandomAccount, transactions: transactions, threads: 32)
    }

}
