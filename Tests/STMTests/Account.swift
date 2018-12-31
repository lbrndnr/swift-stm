//
//  Account.swift
//  STM
//
//  Created by Laurin Brandner on 29.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation
import STM

class Account {
    
    var ID: Int
    var balance: Reference<Int>
    
    init(ID: Int, balance: Int) {
        self.ID = ID
        self.balance = Ref(balance)
    }
    
}
