//
//  Manager.swift
//  STM
//
//  Created by Laurin Brandner on 02.07.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

typealias Identifier = UInt32

class Manager {
    
    static let shared = Manager()
    
    private var usedIDs = Set<Identifier>()
    private var nextID: Identifier = 1
    
    private var queue = DispatchQueue(label: "ch.laurinbrandner.stm.manager", qos: .background)
    
    func generateNewIdentifier() -> Identifier {
        var ID: Identifier!
        queue.sync {
            ID = nextID
            usedIDs.update(with: ID)
            
            repeat {
                nextID += 1
            } while usedIDs.contains(nextID)
        }
        
        return ID
    }
    
    func recycle(_ ID: Identifier) {
        queue.sync {
            guard usedIDs.contains(ID) else {
                return
            }
            
            usedIDs.remove(ID)
            if ID < nextID {
                nextID = ID
            }
        }
    }
    
}
