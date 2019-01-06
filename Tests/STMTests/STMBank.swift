//
//  STMBank.swift
//  STM
//
//  Created by Laurin Brandner on 29.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation
import STM

final class STMAccount: Account {
    
    var ID: Int
    var balance: Reference<Int>
    
    init(ID: Int, balance: Int) {
        self.ID = ID
        self.balance = Ref(balance)
    }
    
}

final class STMBank: Bank {
    
    let accounts: [STMAccount]
    
    var totalValue: Int {
        var res = 0
        atomic {
            res = self.accounts.reduce(0) { i, acc in
                return i + acc.balance
            }
        }
        
        return res
    }
    
    // MARK: - Initialization
    
    init(accounts: [STMAccount]) {
        self.accounts = accounts
    }
    
    // MARK: -
    
    @discardableResult func transfer(from: Account, to: Account, amount: Int) -> Bool {
        guard let from = from as? STMAccount,
            let to = to as? STMAccount else {
                preconditionFailure()
        }
        
        guard from.ID != to.ID else {
            return false
        }
        
        var res = false
        
        atomic {
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
