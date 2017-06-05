//
//  Signature.swift
//  SwiftSTM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

struct Signature {
    
    weak var reference: Referenceable?
    var identifier: String
    
    init() {
        self.identifier = UUID().uuidString
    }
    
}

extension Signature: Hashable {
    
    var hashValue: Int {
        return identifier.hashValue
    }
    
}

func ==(lhs: Signature, rhs: Signature) -> Bool {
    return lhs.identifier == rhs.identifier
}
