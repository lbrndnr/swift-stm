//
//  Bank.swift
//  SwiftSTM
//
//  Created by Laurin Brandner on 29.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation
import SwiftSTM

class Bank {
    
    let accounts: [Account]
    
    var totalValue: Int {
        var res = 0
        atomic {
            res = self.accounts.reduce(0) { $0 + $1.balance.get() }
        }
        
        return res
    }
    
    // MARK: - Initialization
    
    init(accounts: [Account]) {
        self.accounts = accounts
    }
    
    // MARK: - Money
    
    func transfer(from: Account, to: Account, amount: Int) -> Bool {
        var res = false
        
        atomic {
            let l = from.balance
            
            guard l >= amount else {
                return
            }
            
            from.balance =| l - amount
            to.balance =| to.balance + amount
            
            res = true
        }
        
        return res
    }
    
}
