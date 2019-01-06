//
//  DispatchBank.swift
//  STMTests
//
//  Created by Laurin Brandner on 06.01.19.
//

import Foundation

final class DispatchAccount: Account {
    
    var ID: Int
    var balance: Int
    var lock = OS_SPINLOCK_INIT
    
    init(ID: Int, balance: Int) {
        self.ID = ID
        self.balance = balance
    }
    
}

final class DispatchBank: Bank {
    
    let accounts: [DispatchAccount]
    
    var totalValue: Int {
        let res = self.accounts.reduce(0) { i, acc in
            return i + acc.balance
        }
        
        return res
    }
    
    // MARK: - Initialization
    
    init(accounts: [DispatchAccount]) {
        self.accounts = accounts
    }
    
    // MARK: -
    
    private func order(lhs: DispatchAccount, rhs: DispatchAccount) -> (lhs: DispatchAccount, rhs: DispatchAccount) {
        if lhs.ID < rhs.ID {
            return (lhs, rhs)
        }
        
        return (rhs, lhs)
    }
    
    private func lock(lhs: DispatchAccount, rhs: DispatchAccount, for block: (() -> ())) {
        let (a, b) = order(lhs: lhs, rhs: rhs)
        OSSpinLockLock(&a.lock)
        OSSpinLockLock(&b.lock)
        block()
        OSSpinLockUnlock(&a.lock)
        OSSpinLockUnlock(&b.lock)
    }
    
    @discardableResult func transfer(from: Account, to: Account, amount: Int) -> Bool {
        guard let from = from as? DispatchAccount,
                let to = to as? DispatchAccount else {
            preconditionFailure()
        }
        
        guard from.ID != to.ID else {
            return false
        }
        
        var res = false
        
        lock(lhs: from, rhs: to) {
            guard from.balance >= amount else {
                return
            }
            
            from.balance -= amount
            to.balance += amount
            
            res = true
        }
        
        return res
    }
    
}
