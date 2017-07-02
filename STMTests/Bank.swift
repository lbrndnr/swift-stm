//
//  Bank.swift
//  STM
//
//  Created by Laurin Brandner on 29.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation
import STM

class Bank {
    
    let accounts: [Account]
    
    var totalValue: Int {
        var res = 0
        atomic {
            res = self.accounts.reduce(0) { i, acc in
                let v = try? acc.balance.get()
                return i + (v ?? 0)
            }
        }
        
        return res
    }
    
    // MARK: - Initialization
    
    init(accounts: [Account]) {
        self.accounts = accounts
    }
    
    // MARK: - Money
    
    @discardableResult func transfer(from: Account, to: Account, amount: Int) -> Bool {
        var res = false
        
        atomic {            
            let i = try from.balance.get()
            
            guard i >= amount else {
                return
            }
            
            try from.balance.set(i - amount)
            try to.balance.set(to.balance.get() + amount)
            
            res = true
        }
        
        return res
    }
    
}
