//
//  Bank.swift
//  STMTests
//
//  Created by Laurin Brandner on 06.01.19.
//

import Foundation

protocol Account {
    
    var ID: Int { get }
    
}

protocol Bank {
    
    @discardableResult func transfer(from: Account, to: Account, amount: Int) -> Bool
    
}
