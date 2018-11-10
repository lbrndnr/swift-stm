//
//  Identifiable.swift
//  STM
//
//  Created by Laurin Brandner on 10.11.18.
//

import Foundation

// TODO: This should be equatable as well. This can be done once https://bugs.swift.org/browse/SR-6265 is fixed
protocol Identifiable: Hashable {
    
    var ID: UInt64 { get }
    
}

extension Identifiable {
    
    var hashValue: Int {
        return ID.hashValue
    }
    
}

//func ==(lhs: Identifiable, rhs: Identifiable) -> Bool {
//    return lhs.ID == rhs.ID
//}
